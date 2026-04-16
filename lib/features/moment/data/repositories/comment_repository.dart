// ============================================================================
// CommentRepository · 评论数据层
// ============================================================================

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';

class CommentModel {
  final int id;
  final int momentId;
  final int userId;
  final String userNickname;
  final String? userAvatarUrl;
  final int? parentId;
  final String content;
  final int likeCount;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.momentId,
    required this.userId,
    required this.userNickname,
    this.userAvatarUrl,
    this.parentId,
    required this.content,
    required this.likeCount,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: (json['id'] as num).toInt(),
      momentId: (json['momentId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      userNickname: json['userNickname'] as String? ?? '匿名',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      parentId: (json['parentId'] as num?)?.toInt(),
      content: json['content'] as String? ?? '',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

abstract class CommentRepository {
  Future<List<CommentModel>> list(int momentId, {int page = 0, int size = 20});
  Future<CommentModel> create(int momentId, String content, {int? parentId});
  Future<void> delete(int id);
}

class CommentRepositoryImpl implements CommentRepository {
  final ApiClient _api;
  CommentRepositoryImpl(this._api);

  @override
  Future<List<CommentModel>> list(
    int momentId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final res = await _api.dio.get(
        '/api/v1/comments/public/moment/$momentId',
        queryParameters: {'page': page, 'size': size},
      );
      final data = res.data as Map<String, dynamic>;
      final content = (data['content'] as List?) ?? [];
      return content
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _toAppError(e, '加载评论失败');
    }
  }

  @override
  Future<CommentModel> create(
    int momentId,
    String content, {
    int? parentId,
  }) async {
    try {
      final res = await _api.dio.post('/api/v1/comments', data: {
        'momentId': momentId,
        'content': content,
        if (parentId != null) 'parentId': parentId,
      });
      return CommentModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toAppError(e, '发送失败');
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _api.dio.delete('/api/v1/comments/$id');
    } on DioException catch (e) {
      throw _toAppError(e, '删除失败');
    }
  }

  AppException _toAppError(DioException e, String fallback) {
    if (e.error is AppException) return e.error as AppException;
    return AppException(type: AppErrorType.unknown, message: fallback);
  }
}
