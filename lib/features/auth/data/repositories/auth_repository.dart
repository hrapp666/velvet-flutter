// ============================================================================
// AuthRepository · 用户认证数据层
// ============================================================================
// - 注册 / 登录 / 登出 / 当前用户获取
// - 后端 API: /api/v1/auth/register, /login, /me
// - JWT token 持久化在 secure storage（API client 管理）
// ============================================================================

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';

abstract class AuthRepository {
  Future<AuthResult> register({
    required String username,
    required String password,
    required String nickname,
  });

  Future<AuthResult> login({
    required String account,
    required String password,
  });

  Future<void> logout();

  Future<UserProfile?> currentUser();
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;
  AuthRepositoryImpl(this._api);

  @override
  Future<AuthResult> register({
    required String username,
    required String password,
    required String nickname,
  }) async {
    try {
      final res = await _api.dio.post('/api/v1/auth/register', data: {
        'username': username,
        'password': password,
        'nickname': nickname,
      });
      return _parseAuthResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : const AppException(
        type: AppErrorType.unknown,
        message: '注册失败',
      );
    }
  }

  @override
  Future<AuthResult> login({
    required String account,
    required String password,
  }) async {
    try {
      final res = await _api.dio.post('/api/v1/auth/login', data: {
        'account': account,
        'password': password,
      });
      return _parseAuthResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is AppException ? e.error as AppException : const AppException(
        type: AppErrorType.unknown,
        message: '登录失败',
      );
    }
  }

  @override
  Future<void> logout() async {
    await ApiClient.clearToken();
  }

  @override
  Future<UserProfile?> currentUser() async {
    final token = await ApiClient.getToken();
    if (token == null || token.isEmpty) return null;
    try {
      // 优先 /auth/me（含 role + merchantStatus），回退到 /users/me
      try {
        final res = await _api.dio.get('/api/v1/auth/me');
        return UserProfile.fromJson(res.data as Map<String, dynamic>);
      } on DioException catch (_) {
        // 静默原因：新接口缺失时走旧接口兜底，两者均失败才真报错
        final res = await _api.dio.get('/api/v1/users/me');
        return UserProfile.fromJson(res.data as Map<String, dynamic>);
      }
    } on DioException catch (_) {
      // 静默原因：currentUser() 失败即视为未登录，返回 null 让 UI 走未登录态
      return null;
    }
  }

  Future<AuthResult> _parseAuthResponse(Map<String, dynamic> json) async {
    final token = json['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const AppException(type: AppErrorType.server, message: '后端返回 token 为空');
    }
    await ApiClient.saveToken(token);
    final userJson = json['user'] as Map<String, dynamic>?;
    return AuthResult(
      token: token,
      user: userJson != null ? UserProfile.fromJson(userJson) : null,
    );
  }
}

// ──────────────────────────────────────────────────────────
// 简易模型（生产应该用 freezed）
// ──────────────────────────────────────────────────────────
class AuthResult {
  final String token;
  final UserProfile? user;
  const AuthResult({required this.token, this.user});
}

class UserProfile {
  final int id;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final int momentsCount;
  final int followersCount;
  final int followingCount;
  final String role;            // USER / MERCHANT / ADMIN
  final String merchantStatus;  // NONE / PENDING / APPROVED / REJECTED

  const UserProfile({
    required this.id,
    required this.username,
    required this.nickname,
    this.avatarUrl,
    this.bio,
    this.momentsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.role = 'USER',
    this.merchantStatus = 'NONE',
  });

  bool get isAdmin => role == 'ADMIN';
  bool get isMerchant => role == 'MERCHANT' && merchantStatus == 'APPROVED';
  bool get canPublishItem => isMerchant;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: (json['id'] as num).toInt(),
        username: json['username'] as String,
        nickname: json['nickname'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        bio: json['bio'] as String?,
        momentsCount: (json['momentsCount'] as num?)?.toInt() ?? 0,
        followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
        followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
        role: json['role'] as String? ?? 'USER',
        merchantStatus: json['merchantStatus'] as String? ?? 'NONE',
      );
}
