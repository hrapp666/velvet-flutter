// ============================================================================
// NotificationRepository
// ============================================================================

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> list({int page = 0, int size = 20});
  Future<int> unreadCount();
  Future<void> markRead(int id);
  Future<void> markAllRead();
}

class NotificationRepositoryImpl implements NotificationRepository {
  final ApiClient _api;
  NotificationRepositoryImpl(this._api);

  @override
  Future<List<NotificationModel>> list({int page = 0, int size = 20}) async {
    try {
      final res = await _api.dio.get('/api/v1/notifications',
          queryParameters: {'page': page, 'size': size});
      final data = res.data as Map<String, dynamic>;
      final content = (data['content'] as List?) ?? [];
      return content
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toAppError(e, '加载通知失败');
    }
  }

  @override
  Future<int> unreadCount() async {
    try {
      final res = await _api.dio.get('/api/v1/notifications/unread-count');
      final data = res.data as Map<String, dynamic>;
      return (data['count'] as num?)?.toInt() ?? 0;
    } on DioException {
      // 静默原因：未读数是非关键 polling 路径 · 网络抖动降级为 0 优于 throw
      // 防止顶部小红点崩成红色错误图标 · 下次 poll 会自动恢复真实值
      return 0;
    }
  }

  @override
  Future<void> markRead(int id) async {
    try {
      await _api.dio.post('/api/v1/notifications/$id/read');
    } on DioException catch (e) {
      throw _toAppError(e, '标记已读失败');
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await _api.dio.post('/api/v1/notifications/read-all');
    } on DioException catch (e) {
      throw _toAppError(e, '全部已读失败');
    }
  }

  AppException _toAppError(DioException e, String fallback) {
    if (e.error is AppException) return e.error as AppException;
    return AppException(type: AppErrorType.unknown, message: fallback);
  }
}
