// ============================================================================
// AuthProvider · 全局认证状态
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.login(account: account, password: password);
      return result.user ?? await repo.currentUser();
    });
  }

  Future<void> register(String username, String password, String nickname) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.register(
        username: username,
        password: password,
        nickname: nickname,
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
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserProfile?>(AuthNotifier.new);
