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
    final token = await ApiClient.getToken();
    if (token == null || token.isEmpty) return;
    if (_token == token && _channel != null) return; // 已连
    _token = token;
    _setState(WsConnectionState.connecting);
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
    try {
      // 把 https/http 替换成 wss/ws
      final base = ApiClient.baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');
      final uri = Uri.parse('$base/ws/chat?token=$_token');
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      channel.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _setState(WsConnectionState.connected);

      // 每 25s ping
      _ping?.cancel();
      _ping = Timer.periodic(
        const Duration(seconds: 25),
        (_) => _sendPing(),
      );

      // 稳定 30s 后重置退避计数器（防 flap）
      _stabilityTimer?.cancel();
      _stabilityTimer = Timer(const Duration(seconds: 30), () {
        _backoff.reset();
      });
    } on Object catch (_) {
      // 静默原因：WS 建连任何失败都走 reconnect schedule，上层无需知道细节
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

  void _onDone() {
    _channel = null;
    _ping?.cancel();
    _stabilityTimer?.cancel();
    if (!_disposed) {
      _setState(WsConnectionState.reconnecting);
      _scheduleReconnect();
    }
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
