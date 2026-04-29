// ============================================================================
// OrderRepository · 订单接口层
// ============================================================================

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../moment/data/models/moment_model.dart' show Page;
import '../models/order_model.dart';

abstract interface class OrderRepository {
  Future<OrderDto> create(
    int momentId, {
    String? buyerNote,
    String? shippingName,
    String? shippingPhone,
    String? shippingAddress,
  });
  Future<OrderDto> getById(int id);
  Future<Page<OrderDto>> listMine(
    OrderSide side, {
    int page = 0,
    int size = 20,
  });
  Future<OrderDto> cancel(int id);
  Future<OrderDto> ship(int id, {String? trackingNo, String? sellerNote});
  Future<OrderDto> confirm(int id);
  Future<OrderDto> refund(int id, String reason);
}

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<OrderDto> create(
    int momentId, {
    String? buyerNote,
    String? shippingName,
    String? shippingPhone,
    String? shippingAddress,
  }) async {
    try {
      final res = await _api.dio.post('/api/v1/orders', data: {
        'momentId': momentId,
        if (buyerNote != null) 'buyerNote': buyerNote,
        if (shippingName != null) 'shippingName': shippingName,
        if (shippingPhone != null) 'shippingPhone': shippingPhone,
        if (shippingAddress != null) 'shippingAddress': shippingAddress,
      });
      return OrderDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toError(e, '下单失败');
    }
  }

  @override
  Future<OrderDto> getById(int id) async {
    try {
      final res = await _api.dio.get('/api/v1/orders/$id');
      return OrderDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toError(e, '加载订单失败');
    }
  }

  @override
  Future<Page<OrderDto>> listMine(
    OrderSide side, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final res = await _api.dio.get(
        '/api/v1/orders/${side.path}',
        queryParameters: {'page': page, 'size': size},
      );
      return Page.fromJson(
        res.data as Map<String, dynamic>,
        OrderDto.fromJson,
      );
    } on DioException catch (e) {
      throw _toError(e, '加载订单列表失败');
    }
  }

  @override
  Future<OrderDto> cancel(int id) async {
    try {
      final res = await _api.dio.post('/api/v1/orders/$id/cancel');
      return OrderDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toError(e, '取消失败');
    }
  }

  @override
  Future<OrderDto> ship(
    int id, {
    String? trackingNo,
    String? sellerNote,
  }) async {
    try {
      final res = await _api.dio.post(
        '/api/v1/orders/$id/ship',
        data: {
          if (trackingNo != null) 'trackingNo': trackingNo,
          if (sellerNote != null) 'sellerNote': sellerNote,
        },
      );
      return OrderDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toError(e, '发货失败');
    }
  }

  @override
  Future<OrderDto> confirm(int id) async {
    try {
      final res = await _api.dio.post('/api/v1/orders/$id/confirm');
      return OrderDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toError(e, '确认失败');
    }
  }

  @override
  Future<OrderDto> refund(int id, String reason) async {
    try {
      final res = await _api.dio.post(
        '/api/v1/orders/$id/refund',
        data: {'reason': reason},
      );
      return OrderDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toError(e, '申请退款失败');
    }
  }

  AppException _toError(DioException e, String fallback) {
    if (e.error is AppException) return e.error as AppException;
    return AppException(type: AppErrorType.unknown, message: fallback);
  }
}
