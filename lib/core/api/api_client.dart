// ============================================================================
// ApiClient · Velvet 全局 Dio 配置
// ============================================================================
// - JWT token 自动注入
// - 401 自动跳登录
// - 错误统一处理
// - JSON 序列化
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  /// Velvet backend API base URL
  ///
  /// 构建时可用 --dart-define=API_BASE_URL=https://your-api.com 覆盖
  /// 默认走主人正式域名 · 不再使用一次性 trycloudflare URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://agent.ylctkx9s.work',
  );

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'velvet_jwt_token';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
      headers: {'Accept': 'application/json'},
      // 200-299 全 OK，其他抛 DioException 在 errorHandler 处理
      validateStatus: (s) => s != null && s >= 200 && s < 300,
    ),
  );

  ApiClient() {
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
  }

  Dio get dio => _dio;

  // ── Token 管理 ──────────────────────────────────────────
  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await ApiClient.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final code = err.response?.statusCode;

    // 401 → 清 token，让上层路由跳登录
    if (code == 401) {
      ApiClient.clearToken();
    }

    // 把 dio 错误转换成 AppException
    final appError = _toAppException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appError,
        response: err.response,
        type: err.type,
      ),
    );
  }

  AppException _toAppException(DioException err) {
    final code = err.response?.statusCode;
    final data = err.response?.data;

    if (code == null) {
      return const AppException(
        type: AppErrorType.network,
        message: '网络连接失败，请检查网络',
      );
    }

    final serverMsg = data is Map ? (data['msg'] as String?) : null;

    return switch (code) {
      400 => AppException(
          type: AppErrorType.validation,
          message: serverMsg ?? '请求参数有误',
        ),
      401 => const AppException(
          type: AppErrorType.unauthorized,
          message: '请先登录',
        ),
      403 => const AppException(
          type: AppErrorType.forbidden,
          message: '没有权限',
        ),
      404 => AppException(
          type: AppErrorType.notFound,
          message: serverMsg ?? '资源不存在',
        ),
      429 => const AppException(
          type: AppErrorType.rateLimit,
          message: '操作太频繁，稍后再试',
        ),
      _ when code >= 500 => const AppException(
          type: AppErrorType.server,
          message: '服务器开小差，稍后再试',
        ),
      _ => AppException(
          type: AppErrorType.unknown,
          message: serverMsg ?? '未知错误',
        ),
    };
  }
}

// ──────────────────────────────────────────────────────────
// 应用级错误模型
// ──────────────────────────────────────────────────────────
enum AppErrorType {
  network,
  validation,
  unauthorized,
  forbidden,
  notFound,
  rateLimit,
  server,
  unknown,
}

class AppException implements Exception {
  final AppErrorType type;
  final String message;
  const AppException({required this.type, required this.message});

  @override
  String toString() => message;
}
