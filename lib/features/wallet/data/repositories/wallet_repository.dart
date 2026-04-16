// ============================================================================
// WalletRepository · 钱包/提现接口层
// ============================================================================

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../moment/data/models/moment_model.dart' show Page;
import '../models/wallet_model.dart';

abstract interface class WalletRepository {
  Future<WalletDto> myWallet();
  Future<WithdrawalDto> requestWithdraw(WithdrawRequestBody body);
  Future<Page<WithdrawalDto>> myWithdrawals({int page = 0, int size = 20});
}

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<WalletDto> myWallet() async {
    try {
      final res = await _api.dio.get('/api/v1/wallet');
      return WalletDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toError(e, '加载钱包失败');
    }
  }

  @override
  Future<WithdrawalDto> requestWithdraw(WithdrawRequestBody body) async {
    try {
      final res = await _api.dio.post(
        '/api/v1/wallet/withdraw',
        data: body.toJson(),
      );
      return WithdrawalDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toError(e, '申请提现失败');
    }
  }

  @override
  Future<Page<WithdrawalDto>> myWithdrawals({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final res = await _api.dio.get(
        '/api/v1/wallet/withdrawals',
        queryParameters: {'page': page, 'size': size},
      );
      return Page.fromJson(
        res.data as Map<String, dynamic>,
        WithdrawalDto.fromJson,
      );
    } on DioException catch (e) {
      throw _toError(e, '加载提现记录失败');
    }
  }

  AppException _toError(DioException e, String fallback) {
    if (e.error is AppException) return e.error as AppException;
    return AppException(type: AppErrorType.unknown, message: fallback);
  }
}
