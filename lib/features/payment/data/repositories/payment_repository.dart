// ============================================================================
// PaymentRepository · 支付接口层
// ============================================================================

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../models/payment_model.dart';

abstract interface class PaymentRepository {
  Future<PaymentConfig> getConfig();
  Future<PaymentCreateResult> createPayment({
    required int orderId,
    required PaymentProvider provider,
  });
  Future<void> mockMarkPaid(int orderId);
}

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<PaymentConfig> getConfig() async {
    try {
      final res = await _api.dio.get('/api/v1/payments/config');
      return PaymentConfig.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toError(e, '加载支付配置失败');
    }
  }

  @override
  Future<PaymentCreateResult> createPayment({
    required int orderId,
    required PaymentProvider provider,
  }) async {
    try {
      final res = await _api.dio.post('/api/v1/payments/create', data: {
        'orderId': orderId,
        'provider': provider.code,
      });
      return PaymentCreateResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toError(e, '调起支付失败');
    }
  }

  @override
  Future<void> mockMarkPaid(int orderId) async {
    try {
      await _api.dio.post('/api/v1/payments/mock-paid/$orderId');
    } on DioException catch (e) {
      throw _toError(e, '标记付款失败');
    }
  }

  AppException _toError(DioException e, String fallback) {
    if (e.error is AppException) return e.error as AppException;
    return AppException(type: AppErrorType.unknown, message: fallback);
  }
}
