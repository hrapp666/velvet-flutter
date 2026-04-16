// ============================================================================
// MerchantRepository · 商家认证接口层
// ============================================================================

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/merchant_model.dart';

abstract interface class MerchantRepository {
  Future<MerchantDto> apply(MerchantApplyBody body);
  Future<MerchantDto?> myMerchant();
  Future<MerchantDto?> getPublic(int userId);
}

class MerchantRepositoryImpl implements MerchantRepository {
  MerchantRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<MerchantDto> apply(MerchantApplyBody body) async {
    try {
      final res = await _api.dio.post(
        '/api/v1/merchants/apply',
        data: body.toJson(),
      );
      return MerchantDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toError(e, '申请失败');
    }
  }

  @override
  Future<MerchantDto?> myMerchant() async {
    try {
      final res = await _api.dio.get('/api/v1/merchants/me');
      final data = res.data;
      if (data == null) return null;
      return MerchantDto.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _toError(e, '加载商家资料失败');
    }
  }

  @override
  Future<MerchantDto?> getPublic(int userId) async {
    try {
      final res = await _api.dio.get('/api/v1/merchants/public/user/$userId');
      final data = res.data;
      if (data == null) return null;
      return MerchantDto.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _toError(e, '加载店铺失败');
    }
  }

  AppException _toError(DioException e, String fallback) {
    if (e.error is AppException) return e.error as AppException;
    return AppException(type: AppErrorType.unknown, message: fallback);
  }
}
