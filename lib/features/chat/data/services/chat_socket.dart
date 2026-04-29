// ============================================================================
// ChatSocket · WebSocket 实时连接（单例）
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/api/api_client.dart';
import '../models/chat_models.dart';

// ============================================================================
// ReconnectBackoff · 纯逻辑类，无 WebSocket 依赖，可独立测试
// ============================================================================

/// 指数退避重连策略
///
/// 退避序列（秒）：1 → 2 → 4 → 8 → 16 → 32 → 32（cap）
/// 超过 maxAttempts 后 [nextDelay] 返回 null，调用方应进入 failed 状态。
class ReconnectBackoff {
  ReconnectBackoff({this.maxAttempts = 10, this.capSeconds = 32});

  final int maxAttempts;
  final int capSeconds;

  int _attempt = 0;

  int get attempt => _attempt;

  bool get isFailed => _attempt >= maxAttempts;

  /// 返回下次重连等待时长；已超限则返回 null。
  /// 每次调用自动递增内部计数器。
  Duration? nextDelay() {
    if (_attempt >= maxAttempts) return null;
    final raw = 1 << _attempt; // 1, 2, 4, 8, 16, 32, 64…
    _attempt++;
    return Duration(seconds: min(raw, capSeconds));
  }

  /// 重置计数器（稳定连接 30 秒后调用）
  void reset() => _attempt = 0;
}

// ============================================================================
// ChatSocket · 单例，带状态机 + 指数退避
// ============================================================================

/// WebSocket 连接管理 — 应用全局单例
///
/// 协议：
///   - connect: ws://host/ws/chat?token=JWT
///   - PING / PONG keepalive（每 25s）
///   - 接收 MSG → 转发到 [messages] stream
///   - 指数退避重连：1s → 2s → 4s → 8s → 16s → 32s（cap）
///   - max 10 次失败后进入 [WsConnectionState.failed]，停止自动重连
///   - 稳定连接 30s 后重置退避计数器
class ChatSocket {
  ChatSocket._();
  static final ChatSocket instance = ChatSocket._();

  WebSocketChannel? _channel;
  Timer? _ping;
  Timer? _reconnect;
  Timer? _stabilityTimer;
  bool _disposed = false;
  String? _token;

  final _backoff = ReconnectBackoff();

  final _messageController = StreamController<MessageModel>.broadcast();
  final _stateController =
      StreamController<WsConnectionState>.broadcast();

  WsConnectionState _currentState = WsConnectionState.disconnected;

  /// 收消息流（任何 conversation 的消息都会进来）
  Stream<MessageModel> get messages => _messageController.stream;

  /// WebSocket 连接状态流
  Stream<WsConnectionState> get connectionState => _stateController.stream;

  /// 当前连接状态快照
  WsConnectionState get currentState => _currentState;

  bool get isConnected => _channel != null;

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  /// 启动连接
  Future<void> connect() async {
    if (_disposed) return;
    if (_channel != null && _currentState == WsConnectionState.connected) {
      return; // 已连
    }
    // 先把状态切到 connecting · 消除"未 连 接"的闪烁(getToken async gap)
    if (_currentState != WsConnectionState.connected) {
      _setState(WsConnectionState.connecting);
    }
    final token = await ApiClient.getToken();
    if (token == null || token.isEmpty) {
      // 没 token 不连 · 维持 disconnected · 不显 connecting
      _setState(WsConnectionState.disconnected);
      return;
    }
    if (_token == token && _channel != null) return; // 已连
    _token = token;
    await _open();
  }

  /// 断开连接并清理（用户主动登出等场景）
  void disconnect() {
    _ping?.cancel();
    _reconnect?.cancel();
    _stabilityTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _token = null;
    _setState(WsConnectionState.disconnected);
  }

  /// 从 failed 状态手动触发重试（UI "重试"按钮回调）
  void manualRetry() {
    if (_currentState != WsConnectionState.failed) return;
    _backoff.reset();
    _setState(WsConnectionState.connecting);
    _open();
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _messageController.close();
    _stateController.close();
  }

  // --------------------------------------------------------------------------
  // Internal
  // --------------------------------------------------------------------------

  Future<void> _open() async {
    // 重连前从 secure storage 重新读 token · 修复死循环 banner
    // 同事反馈"网络不稳一直显示" = 后端 1008 拒绝 token 后 stale _token 被反复重试
    // 这里覆盖 _token 让 manualRetry / scheduleReconnect 路径都用最新值
    final fresh = await ApiClient.getToken();
    if (fresh == null || fresh.isEmpty) {
      // token 已被 401 拦截器或登出清掉 → 不重连,等上层路由跳登录
      _setState(WsConnectionState.failed);
      return;
    }
    _token = fresh;

    try {
      // 强制 wss · 禁止明文 ws（生产 baseUrl 必须 https,本地调试 http→ws 仅在 dart-define VELVET_INSECURE_WS=true 时通过）
      // 用 Uri.replace 而不是字符串替换 —— 兼容 baseUrl 带 path 前缀（如 /api）的场景。
      final apiUri = Uri.parse(ApiClient.baseUrl);
      final String wsScheme;
      if (apiUri.scheme == 'https') {
        wsScheme = 'wss';
      } else if (apiUri.scheme == 'http' &&
          const bool.fromEnvironment('VELVET_INSECURE_WS')) {
        wsScheme = 'ws';
      } else {
        // 静默原因:不允许走明文 ws,直接进 failed,UI 重试不生效
        _setState(WsConnectionState.failed);
        return;
      }
      final uri = apiUri.replace(scheme: wsScheme, path: '/ws/chat', query: '');
      // P1-3:token 走 Sec-WebSocket-Protocol header(子协议),不再放 querystring
      // 子协议名格式 velvet.token.<JWT> · 后端 ChatWebSocketHandler 取该 header 解析
      final channel = WebSocketChannel.connect(
        uri,
        protocols: ['velvet.token.$_token'],
      );
      _channel = channel;
      channel.stream.listen(
        _onData,
        onError: _onError,
        // closure 传 channel 进 _onDone · 用于读 closeCode 区分 auth 拒绝 vs 网络断
        onDone: () => _onDone(channel),
        cancelOnError: false,
      );

      // web_socket_channel v3: connect() は同步返回，握手结果在 channel.ready 里。
      // 必须 await ready 才知道握手成功 · 失败会 throw · 被下方 on Object catch 接住走重连
      await channel.ready;
      if (_disposed) return; // dispose() 在握手期间被调用 · 不再切状态或启动 timer
      // 到这里握手已成功，才切换到 connected 状态
      _setState(WsConnectionState.connected);

      // 每 25s ping
      _ping?.cancel();
      _ping = Timer.periodic(
        const Duration(seconds: 25),
        (_) => _sendPing(),
      );

      // 稳定 30s 后重置退避计数器（防 flap）
      _stabilityTimer?.cancel();
      _stabilityTimer = Timer(const Duration(seconds: 30), _backoff.reset);
    } on Object catch (_) {
      // 静默原因：WS 建连任何失败（含 ready 抛出的握手错误）都走 reconnect schedule
      _channel = null;
      _setState(WsConnectionState.reconnecting);
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = json['type'] as String?;
      if (type == 'MSG') {
        // 服务端字段：id / conversationId / senderId / senderNickname /
        //             content / msgType / timestamp
        final ts = json['timestamp'];
        final msg = MessageModel(
          id: (json['id'] as num?)?.toInt() ?? 0,
          conversationId: (json['conversationId'] as num).toInt(),
          senderId: (json['senderId'] as num).toInt(),
          senderNickname: json['senderNickname'] as String? ?? '',
          type: json['msgType'] as String? ?? 'TEXT',
          content: json['content'] as String? ?? '',
          mediaUrl: null,
          refMomentId: null,
          createdAt: ts is num
              ? DateTime.fromMillisecondsSinceEpoch(ts.toInt())
              : DateTime.now(),
        );
        _messageController.add(msg);
      }
      // PONG / CONNECTED / ERROR 暂不处理
    } on Object catch (_) {
      // 静默原因：单条畸形消息不该让整个 WS stream 关掉，丢弃继续
    }
  }

  void _onError(Object err) {
    _channel = null;
    _ping?.cancel();
    _stabilityTimer?.cancel();
    if (!_disposed) {
      _setState(WsConnectionState.reconnecting);
      _scheduleReconnect();
    }
  }

  void _onDone(WebSocketChannel channel) {
    _channel = null;
    _ping?.cancel();
    _stabilityTimer?.cancel();
    if (_disposed) return;

    // close code 1008 (POLICY_VIOLATION) = 后端 ChatWebSocketHandler 主动拒绝 token
    // 同 token 重连必然死循环 → 进 failed 等用户手动重试或下次 HTTP 401 触发 refresh
    // 注意:不再调 ApiClient.clearToken() · WS 单点拒绝不该全局踢用户登录
    //   如果 token 真的失效,下次任何 HTTP 请求会拿到 401 → ApiClient 走 refresh 流程,
    //   refresh 失败才登出。这避免了 WS 误标 1008 把整个 session 干掉。
    // 其他 close code (1001 going-away / 1006 abnormal / 1011 server error 等) 走重连
    if (channel.closeCode == 1008) {
      _token = null;
      _setState(WsConnectionState.failed);
      return;
    }

    _setState(WsConnectionState.reconnecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnect?.cancel();
    if (_disposed) return;

    final delay = _backoff.nextDelay();
    if (delay == null) {
      // 超过最大重连次数，进入 failed 状态，停止自动重连
      _setState(WsConnectionState.failed);
      return;
    }

    _reconnect = Timer(delay, () {
      if (!_disposed) _open();
    });
  }

  void _sendPing() {
    try {
      _channel?.sink.add(jsonEncode({'type': 'PING'}));
    } on Object catch (_) {
      // 静默原因：ping 失败会由 onDone/onError 走 reconnect 路径
    }
  }

  /// 状态机 helper — 相同状态不 emit，不同才变更并广播
  void _setState(WsConnectionState next) {
    if (_currentState == next) return;
    _currentState = next;
    if (!_stateController.isClosed) {
      _stateController.add(next);
    }
  }
}
