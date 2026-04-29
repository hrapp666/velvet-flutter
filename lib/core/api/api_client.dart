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

  /// 全局会话失效回调 · 由 AuthNotifier 在 build() 中注册。
  /// refresh token 失败 → ApiClient 清 token → 触发此回调 →
  /// AuthNotifier 把 state 置 null → GoRouter redirect 一次性跳 /login。
  /// 避免 N 个并发 401 各自弹"请先登录"toast 洪水。
  static void Function()? onSessionExpired;

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'velvet_jwt_token';
  static const _refreshTokenKey = 'velvet_refresh_token';

  // 单例 Dio · _ErrorInterceptor 需要它来发 refresh 请求和重放原请求
  static final Dio _dio = _buildDio();

  static Dio _buildDio() {
    final dio = Dio(
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
    dio.interceptors.add(_AuthInterceptor());
    dio.interceptors.add(_RetryInterceptor(dio));
    dio.interceptors.add(_ErrorInterceptor(dio));
    return dio;
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
    await _storage.delete(key: _refreshTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
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

/// 瞬时网络错误自动重试 · 透明恢复手机→VPS 链路抖动
///
/// 只重试幂等请求(GET / HEAD) + 明确 extra['__retryable']=true 的写请求。
/// 触发条件:connectTimeout / sendTimeout / receiveTimeout / connectionError。
/// 重试 1 次,200ms 延迟。仍失败 → 走 _ErrorInterceptor 弹"网络较慢"。
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);
  final Dio _dio;

  static const _retryFlag = '__retriedOnce';

  bool _isTransient(DioExceptionType t) =>
      t == DioExceptionType.connectionTimeout ||
      t == DioExceptionType.sendTimeout ||
      t == DioExceptionType.receiveTimeout ||
      t == DioExceptionType.connectionError;

  bool _isIdempotent(RequestOptions o) {
    final m = o.method.toUpperCase();
    if (m == 'GET' || m == 'HEAD') return true;
    return o.extra['__retryable'] == true;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final opts = err.requestOptions;
    if (opts.extra[_retryFlag] == true ||
        !_isTransient(err.type) ||
        !_isIdempotent(opts)) {
      return handler.next(err);
    }
    opts.extra[_retryFlag] = true;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    try {
      final res = await _dio.fetch<dynamic>(opts);
      handler.resolve(res);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

class _ErrorInterceptor extends Interceptor {
  _ErrorInterceptor(this._dio);

  final Dio _dio;

  // 同一时刻只允许一个 refresh 请求 · 多个并发 401 共享同一次 refresh 结果
  static Future<_RefreshOutcome>? _refreshFuture;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final code = err.response?.statusCode;
    final data = err.response?.data;
    final serverCode = data is Map ? (data['code'] as String?) : null;
    final isAuthError = code == 401 || serverCode == 'UNAUTHORIZED';

    // 跳过 refresh 端点本身的 401 · 防止递归
    final path = err.requestOptions.path;
    final isRefreshCall = path.endsWith('/api/v1/auth/refresh');
    final alreadyRetried = err.requestOptions.extra['__retriedAfterRefresh'] == true;

    if (isAuthError && !isRefreshCall && !alreadyRetried) {
      _RefreshOutcome outcome;
      try {
        outcome = await (_refreshFuture ??= _attemptRefresh());
      } on Object catch (_) {
        outcome = const _RefreshOutcome.transientError();
      } finally {
        _refreshFuture = null;
      }
      if (outcome.newAccess != null && outcome.newAccess!.isNotEmpty) {
        // 重放原请求 · 带新 token + 标记防止二次重试
        final retryOpts = err.requestOptions
          ..headers['Authorization'] = 'Bearer ${outcome.newAccess}'
          ..extra['__retriedAfterRefresh'] = true;
        try {
          final retryRes = await _dio.fetch<dynamic>(retryOpts);
          handler.resolve(retryRes);
          return;
        } on DioException catch (retryErr) {
          // 重放也挂了 · 走原始失败流程（不踢登出 · 让下次请求再试）
          return _rejectWithAppError(retryErr, handler);
        }
      }
      // refresh 没拿到新 token · 区分两种情况：
      // - hardFailure: refresh token 缺失 / 后端返 401 → 真的过期了，登出
      // - 否则（网络错 / 5xx / 超时）→ 保留 token，本次请求当作网络失败处理
      if (outcome.hardFailure) {
        await ApiClient.clearToken();
        ApiClient.onSessionExpired?.call();
      } else {
        // transientError: refresh 因为网络/5xx 没成功 · 不能让原始 401 冒上去
        // 否则 currentUser() 会吃到 unauthorized → ProfileScreen 渲染"请先登录"
        // 改成 network 错误 · UI 显示"网络较慢" · 用户保持登录态 · 下次自动重试
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const AppException(
              type: AppErrorType.network,
              message: '网络较慢，请稍后再试',
            ),
            response: err.response,
            type: err.type,
          ),
        );
        return;
      }
    } else if (isAuthError && (isRefreshCall || alreadyRetried)) {
      // refresh 端点本身 401，或重试后仍 401 = 真过期，登出
      await ApiClient.clearToken();
      ApiClient.onSessionExpired?.call();
    }

    return _rejectWithAppError(err, handler);
  }

  Future<_RefreshOutcome> _attemptRefresh() async {
    final refreshToken = await ApiClient.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      // 真没 refresh token = 登出
      return const _RefreshOutcome.hardFailure();
    }
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: const {'__retriedAfterRefresh': true}),
      );
      final data = res.data;
      if (data == null) return const _RefreshOutcome.hardFailure();
      final newAccess = (data['token'] ?? data['accessToken']) as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (newAccess == null || newAccess.isEmpty) {
        return const _RefreshOutcome.hardFailure();
      }
      await ApiClient.saveToken(newAccess);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await ApiClient.saveRefreshToken(newRefresh);
      }
      return _RefreshOutcome.success(newAccess);
    } on DioException catch (e) {
      // 后端明确说 refresh token 失效 → hardFailure 登出
      // 网络/5xx/超时 → transient，保留 token 不登出
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        return const _RefreshOutcome.hardFailure();
      }
      return const _RefreshOutcome.transientError();
    } on Object {
      return const _RefreshOutcome.transientError();
    }
  }

  void _rejectWithAppError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
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
      // 按 DioExceptionType 区分 · 旧实现一律"网络连接失败"导致用户误判
      return switch (err.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => const AppException(
            type: AppErrorType.network,
            message: '网络较慢，请稍后再试',
          ),
        DioExceptionType.connectionError => const AppException(
            type: AppErrorType.network,
            message: '无法连接服务器，请检查网络',
          ),
        DioExceptionType.cancel => const AppException(
            type: AppErrorType.unknown,
            message: '请求已取消',
          ),
        DioExceptionType.badCertificate => const AppException(
            type: AppErrorType.network,
            message: '证书校验失败',
          ),
        DioExceptionType.badResponse ||
        DioExceptionType.unknown => AppException(
            type: AppErrorType.unknown,
            message: err.message ?? '请求失败，请重试',
          ),
      };
    }

    final serverMsg = data is Map ? (data['msg'] as String?) : null;
    final serverCode = data is Map ? (data['code'] as String?) : null;

    // 任意状态码 + body code=UNAUTHORIZED → 当 401 处理(后端实际返 400)
    if (serverCode == 'UNAUTHORIZED') {
      return const AppException(
        type: AppErrorType.unauthorized,
        message: '请先登录',
      );
    }

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

/// refresh 三态：success / hardFailure(真过期·登出) / transientError(网络问题·保留 token)
class _RefreshOutcome {
  final String? newAccess;
  final bool hardFailure;
  const _RefreshOutcome._(this.newAccess, this.hardFailure);
  const _RefreshOutcome.success(String token) : this._(token, false);
  const _RefreshOutcome.hardFailure() : this._(null, true);
  const _RefreshOutcome.transientError() : this._(null, false);
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

/// 把任意错误对象转成给用户看的中文文案。
/// AppException 直接返回 message; 其他类型给中性 fallback。
///
/// 特例：unauthorized 返回空串 · 调用方应当 `if (msg.isNotEmpty) showToast(msg)` 跳过。
/// 理由：refresh 失败已由 ApiClient.onSessionExpired 触发全局 router redirect，
/// 各按钮再 toast 一次"请先登录"是噪声。空串 = silent。
String userMessageOf(Object? error, {String fallback = '操作失败，请稍后再试'}) {
  if (error is AppException) {
    if (error.type == AppErrorType.unauthorized) return '';
    return error.message;
  }
  if (error == null) return fallback;
  return fallback;
}
