// ============================================================================
// AdminRepository · 管理员数据接口
// ============================================================================

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class AdminStats {
  final int totalUsers;
  final int totalMerchants;
  final int todayOrderCount;
  final int todaySalesCents;
  final int todayCommissionCents;
  final int totalSalesCents;
  final int totalCommissionCents;
  final int pendingMerchants;
  final int pendingWithdrawals;
  final int pendingReports;
  final int pendingPayoutCents;

  const AdminStats({
    required this.totalUsers,
    required this.totalMerchants,
    required this.todayOrderCount,
    required this.todaySalesCents,
    required this.todayCommissionCents,
    required this.totalSalesCents,
    required this.totalCommissionCents,
    required this.pendingMerchants,
    required this.pendingWithdrawals,
    required this.pendingReports,
    required this.pendingPayoutCents,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
        totalMerchants: (json['totalMerchants'] as num?)?.toInt() ?? 0,
        todayOrderCount: (json['todayOrderCount'] as num?)?.toInt() ?? 0,
        todaySalesCents: (json['todaySalesCents'] as num?)?.toInt() ?? 0,
        todayCommissionCents:
            (json['todayCommissionCents'] as num?)?.toInt() ?? 0,
        totalSalesCents: (json['totalSalesCents'] as num?)?.toInt() ?? 0,
        totalCommissionCents:
            (json['totalCommissionCents'] as num?)?.toInt() ?? 0,
        pendingMerchants: (json['pendingMerchants'] as num?)?.toInt() ?? 0,
        pendingWithdrawals:
            (json['pendingWithdrawals'] as num?)?.toInt() ?? 0,
        pendingReports: (json['pendingReports'] as num?)?.toInt() ?? 0,
        pendingPayoutCents:
            (json['pendingPayoutCents'] as num?)?.toInt() ?? 0,
      );
}

class AdminRepository {
  AdminRepository(this._api);
  final ApiClient _api;

  Future<AdminStats> stats() async {
    try {
      final res = await _api.dio.get('/api/v1/admin/stats');
      return AdminStats.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw (e.error is AppException)
          ? e.error as AppException
          : const AppException(
              type: AppErrorType.server, message: '加载管理数据失败');
    }
  }
}
