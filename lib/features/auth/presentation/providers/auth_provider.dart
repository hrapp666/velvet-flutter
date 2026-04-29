// ============================================================================
// AuthProvider · 全局认证状态
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../chat/data/services/chat_socket.dart';
import '../../data/repositories/auth_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthRepositoryImpl(api);
});

// ── 当前用户状态 ──────────────────────────────────────────
final currentUserProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  // keepAlive 防止切 tab 时"我的"页面闪 loading;login/logout 时通过
  // ref.invalidate(currentUserProvider) 主动刷新
  ref.keepAlive();
  final repo = ref.watch(authRepositoryProvider);
  return repo.currentUser();
});

// ── 登录状态 ──────────────────────────────────────────────
class AuthNotifier extends AsyncNotifier<UserProfile?> {
  /// 最近一次因 session 过期登出的时间 · 5 分钟内重复触发会被节流
  /// 防止极端情况下短时多个 401 同时打到 onSessionExpired 引发抖动
  DateTime? _lastExpiredAt;

  @override
  Future<UserProfile?> build() async {
    // 注册全局 session 失效回调 · ApiClient refresh-fail 时触发 ·
    // 单次置 state 为 null → GoRouter redirect 跳 /login，
    // 避免 N 个并发请求各自弹"请先登录"toast 洪水。
    ApiClient.onSessionExpired = _handleSessionExpired;
    ref.onDispose(() {
      // 仅当回调未被替换时清理 · 防止覆盖后续 AuthNotifier 实例
      if (identical(ApiClient.onSessionExpired, _handleSessionExpired)) {
        ApiClient.onSessionExpired = null;
      }
    });

    final repo = ref.read(authRepositoryProvider);
    return repo.currentUser();
  }

  void _handleSessionExpired() {
    // 已经是未登录态 · 不重复触发
    if (state.value == null) return;
    // 节流 · 5 分钟内最多触发一次 · 防止短时多 401 抖动登出
    final now = DateTime.now();
    final last = _lastExpiredAt;
    if (last != null && now.difference(last).inMinutes < 5) return;
    _lastExpiredAt = now;
    ChatSocket.instance.disconnect();
    state = const AsyncValue.data(null);
    ref.invalidate(currentUserProvider);
  }

  Future<void> login(String account, String password) async {
    // 切账号前先断旧 WS · 防止 A 账号 WS 把消息推到 B 账号
    ChatSocket.instance.disconnect();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.login(account: account, password: password);
      return result.user ?? await repo.currentUser();
    });
    // 同步 currentUserProvider · 必须 await refresh 而非 invalidate
    // invalidate 不阻塞 → router redirect 抢跑读到旧 null → 弹"请登录"
    // invalidate + await read · refresh 触发 unused_result lint
    ref.invalidate(currentUserProvider);
    await ref.read(currentUserProvider.future);
    // 用新 token 建立 WS
    if (state.value != null) {
      await ChatSocket.instance.connect();
    }
  }

  Future<void> register(
    String username,
    String password,
    String nickname, {
    required DateTime birthday,
    required bool agreedTerms,
  }) async {
    ChatSocket.instance.disconnect();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.register(
        username: username,
        password: password,
        nickname: nickname,
        birthday: birthday,
        agreedTerms: agreedTerms,
      );
      // 确保注册后一定拿到 user · 否则 feed 页会显示"未登录"
      final user = result.user ?? await repo.currentUser();
      if (user == null) {
        throw const AppException(
          type: AppErrorType.server,
          message: '注册成功但获取用户信息失败 · 请重新登录',
        );
      }
      return user;
    });
    // 注册成功后必须 await refresh · 否则 feed 抢跑读旧 null 弹"请登录"
    // invalidate + await read · refresh 触发 unused_result lint
    ref.invalidate(currentUserProvider);
    await ref.read(currentUserProvider.future);
    if (state.value != null) {
      await ChatSocket.instance.connect();
    }
  }

  Future<void> loginWithApple({
    required String identityToken,
    String? nickname,
  }) async {
    ChatSocket.instance.disconnect();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.loginWithApple(
        identityToken: identityToken,
        nickname: nickname,
      );
      return result.user ?? await repo.currentUser();
    });
    // invalidate + await read · refresh 触发 unused_result lint
    ref.invalidate(currentUserProvider);
    await ref.read(currentUserProvider.future);
    if (state.value != null) {
      await ChatSocket.instance.connect();
    }
  }

  Future<void> logout() async {
    // 先断 WS · 清掉对旧 token 的引用，避免 stream 回调把旧账号消息推给新账号
    ChatSocket.instance.disconnect();
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(null);
    // 同步 currentUserProvider · profile_screen 切回未登录态
    ref.invalidate(currentUserProvider);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserProfile?>(AuthNotifier.new);
