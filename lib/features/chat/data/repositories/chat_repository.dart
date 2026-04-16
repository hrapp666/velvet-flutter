// ============================================================================
// ChatRepository · 私信数据层
// ============================================================================

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/chat_models.dart';

abstract class ChatRepository {
  Future<List<ConversationModel>> listConversations({int page = 0, int size = 20});
  Future<List<MessageModel>> listMessages(int conversationId,
      {int page = 0, int size = 30});
  Future<MessageModel> send({
    required int otherUserId,
    required String content,
    int? momentId,
    String type = 'TEXT',
    String? mediaUrl,
    int? refMomentId,
  });
  Future<void> markRead(int conversationId);
}

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient _api;
  ChatRepositoryImpl(this._api);

  @override
  Future<List<ConversationModel>> listConversations(
      {int page = 0, int size = 20}) async {
    try {
      final res = await _api.dio.get('/api/v1/chat/conversations',
          queryParameters: {'page': page, 'size': size});
      final data = res.data as Map<String, dynamic>;
      final content = (data['content'] as List?) ?? [];
      return content
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toAppError(e, '加载会话失败');
    }
  }

  @override
  Future<List<MessageModel>> listMessages(int conversationId,
      {int page = 0, int size = 30}) async {
    try {
      final res = await _api.dio.get(
        '/api/v1/chat/conversations/$conversationId/messages',
        queryParameters: {'page': page, 'size': size},
      );
      final data = res.data as Map<String, dynamic>;
      final content = (data['content'] as List?) ?? [];
      return content
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toAppError(e, '加载消息失败');
    }
  }

  @override
  Future<MessageModel> send({
    required int otherUserId,
    required String content,
    int? momentId,
    String type = 'TEXT',
    String? mediaUrl,
    int? refMomentId,
  }) async {
    try {
      final res = await _api.dio.post('/api/v1/chat/messages', data: {
        'otherUserId': otherUserId,
        'content': content,
        if (momentId != null) 'momentId': momentId,
        'type': type,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (refMomentId != null) 'refMomentId': refMomentId,
      });
      return MessageModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toAppError(e, '发送失败');
    }
  }

  @override
  Future<void> markRead(int conversationId) async {
    try {
      await _api.dio.post('/api/v1/chat/conversations/$conversationId/read');
    } on DioException catch (e) {
      throw _toAppError(e, '标记已读失败');
    }
  }

  AppException _toAppError(DioException e, String fallback) {
    if (e.error is AppException) return e.error as AppException;
    return AppException(type: AppErrorType.unknown, message: fallback);
  }
}
