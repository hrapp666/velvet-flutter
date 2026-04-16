// ============================================================================
// MomentRepository · 动态数据层
// ============================================================================

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/moment_model.dart';

abstract class MomentRepository {
  Future<Page<MomentModel>> listPublic({int page = 0, int size = 20});
  Future<Page<MomentModel>> listByUser(int userId, {int page = 0, int size = 20});
  Future<MomentModel> getById(int id);
  Future<MomentModel> create(CreateMomentBody body);
  Future<void> delete(int id);

  /// 同城 / 附近动态（按距离升序，自带 distanceMeters）
  Future<List<MomentModel>> listNearby({
    required double lat,
    required double lng,
    double radiusKm = 20,
    int page = 0,
    int size = 20,
  });

  /// v0 推荐 · 基于用户历史 tag 的 jaccard 相似度
  /// 需登录。冷启动 fallback 返回最新 public。
  Future<List<MomentModel>> listRecommended({int limit = 20});

  // 互动
  Future<bool> toggleLike(int momentId);
  Future<bool> toggleFavorite(int momentId);

  // 我的收藏
  Future<List<MomentModel>> myFavorites({int page = 0, int size = 30});
}

class MomentRepositoryImpl implements MomentRepository {
  final ApiClient _api;
  MomentRepositoryImpl(this._api);

  @override
  Future<Page<MomentModel>> listPublic({int page = 0, int size = 20}) async {
    try {
      final res = await _api.dio.get('/api/v1/moments/public', queryParameters: {
        'page': page,
        'size': size,
      });
      return Page.fromJson(res.data as Map<String, dynamic>, MomentModel.fromJson);
    } on DioException catch (e) {
      throw _toAppError(e, '加载动态失败');
    }
  }

  @override
  Future<Page<MomentModel>> listByUser(int userId, {int page = 0, int size = 20}) async {
    try {
      final res = await _api.dio.get(
        '/api/v1/moments/public/user/$userId',
        queryParameters: {'page': page, 'size': size},
      );
      return Page.fromJson(res.data as Map<String, dynamic>, MomentModel.fromJson);
    } on DioException catch (e) {
      throw _toAppError(e, '加载用户动态失败');
    }
  }

  @override
  Future<MomentModel> getById(int id) async {
    try {
      final res = await _api.dio.get('/api/v1/moments/public/$id');
      return MomentModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toAppError(e, '加载动态详情失败');
    }
  }

  @override
  Future<List<MomentModel>> listNearby({
    required double lat,
    required double lng,
    double radiusKm = 20,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final res = await _api.dio.get(
        '/api/v1/moments/public/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radiusKm': radiusKm,
          'page': page,
          'size': size,
        },
      );
      final list = (res.data as List).cast<Map<String, dynamic>>();
      return list.map(MomentModel.fromJson).toList();
    } on DioException catch (e) {
      throw _toAppError(e, '加载附近动态失败');
    }
  }

  @override
  Future<List<MomentModel>> listRecommended({int limit = 20}) async {
    try {
      final res = await _api.dio.get(
        '/api/v1/moments/recommended',
        queryParameters: {'limit': limit},
      );
      final list = (res.data as List).cast<Map<String, dynamic>>();
      return list.map(MomentModel.fromJson).toList();
    } on DioException catch (e) {
      throw _toAppError(e, '加载推荐失败');
    }
  }

  @override
  Future<MomentModel> create(CreateMomentBody body) async {
    try {
      final res = await _api.dio.post('/api/v1/moments', data: body.toJson());
      return MomentModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toAppError(e, '发布失败');
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _api.dio.delete('/api/v1/moments/$id');
    } on DioException catch (e) {
      throw _toAppError(e, '删除失败');
    }
  }

  @override
  Future<bool> toggleLike(int momentId) async {
    try {
      final res = await _api.dio.post('/api/v1/moments/$momentId/like');
      return (res.data as Map<String, dynamic>)['liked'] as bool? ?? false;
    } on DioException catch (e) {
      throw _toAppError(e, '操作失败');
    }
  }

  @override
  Future<bool> toggleFavorite(int momentId) async {
    try {
      final res = await _api.dio.post('/api/v1/moments/$momentId/favorite');
      return (res.data as Map<String, dynamic>)['favorited'] as bool? ?? false;
    } on DioException catch (e) {
      throw _toAppError(e, '操作失败');
    }
  }

  @override
  Future<List<MomentModel>> myFavorites({int page = 0, int size = 30}) async {
    try {
      final res = await _api.dio.get('/api/v1/favorites/my',
          queryParameters: {'page': page, 'size': size});
      final data = res.data as Map<String, dynamic>;
      final list = (data['content'] as List? ?? []).cast<Map<String, dynamic>>();
      return list.map(MomentModel.fromJson).toList();
    } on DioException catch (e) {
      throw _toAppError(e, '加载收藏失败');
    }
  }

  AppException _toAppError(DioException e, String fallback) {
    if (e.error is AppException) return e.error as AppException;
    return AppException(type: AppErrorType.unknown, message: fallback);
  }
}
