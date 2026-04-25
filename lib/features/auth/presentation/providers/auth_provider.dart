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
  final repo = ref.watch(authRepositoryProvider);
  return repo.currentUser();
});

// ── 登录状态 ──────────────────────────────────────────────
class AuthNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final repo = ref.read(authRepositoryProvider);
    return repo.currentUser();
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
    // 同步 currentUserProvider · profile_screen 立即看到登录态
    ref.invalidate(currentUserProvider);
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
    ref.invalidate(currentUserProvider);
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
    ref.invalidate(currentUserProvider);
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
