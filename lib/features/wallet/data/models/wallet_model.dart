// ============================================================================
// Wallet Models · 钱包 / 提现数据模型
// ============================================================================

class WalletDto {
  final int pendingCents;
  final int balanceCents;
  final int withdrawnCents;
  final int totalSalesCents;
  final int totalCommissionCents;

  const WalletDto({
    required this.pendingCents,
    required this.balanceCents,
    required this.withdrawnCents,
    required this.totalSalesCents,
    required this.totalCommissionCents,
  });

  factory WalletDto.fromJson(Map<String, dynamic> json) => WalletDto(
        pendingCents: (json['pendingCents'] as num?)?.toInt() ?? 0,
        balanceCents: (json['balanceCents'] as num?)?.toInt() ?? 0,
        withdrawnCents: (json['withdrawnCents'] as num?)?.toInt() ?? 0,
        totalSalesCents: (json['totalSalesCents'] as num?)?.toInt() ?? 0,
        totalCommissionCents:
            (json['totalCommissionCents'] as num?)?.toInt() ?? 0,
      );

  double get pendingYuan => pendingCents / 100.0;
  double get balanceYuan => balanceCents / 100.0;
  double get withdrawnYuan => withdrawnCents / 100.0;
  double get totalSalesYuan => totalSalesCents / 100.0;
  double get totalCommissionYuan => totalCommissionCents / 100.0;
}

/// 提现方式
enum WithdrawMethod {
  wechat('WECHAT', '微信'),
  alipay('ALIPAY', '支付宝'),
  bank('BANK', '银行卡');

  final String code;
  final String label;
  const WithdrawMethod(this.code, this.label);

  static WithdrawMethod fromCode(String? code) {
    return WithdrawMethod.values.firstWhere(
      (m) => m.code == code,
      orElse: () => WithdrawMethod.wechat,
    );
  }
}

/// 提现状态
enum WithdrawStatus {
  pending('PENDING', '审核中'),
  approved('APPROVED', '已批准'),
  paid('PAID', '已到账'),
  rejected('REJECTED', '已拒绝');

  final String code;
  final String label;
  const WithdrawStatus(this.code, this.label);

  static WithdrawStatus fromCode(String? code) {
    return WithdrawStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => WithdrawStatus.pending,
    );
  }
}

class WithdrawalDto {
  final int id;
  final int amountCents;
  final WithdrawMethod method;
  final String account;
  final String accountName;
  final WithdrawStatus status;
  final String? reviewNote;
  final DateTime? createdAt;
  final DateTime? paidAt;

  const WithdrawalDto({
    required this.id,
    required this.amountCents,
    required this.method,
    required this.account,
    required this.accountName,
    required this.status,
    this.reviewNote,
    this.createdAt,
    this.paidAt,
  });

  double get amountYuan => amountCents / 100.0;

  factory WithdrawalDto.fromJson(Map<String, dynamic> json) => WithdrawalDto(
        id: (json['id'] as num).toInt(),
        amountCents: (json['amountCents'] as num).toInt(),
        method: WithdrawMethod.fromCode(json['method'] as String?),
        account: json['account'] as String? ?? '',
        accountName: json['accountName'] as String? ?? '',
        status: WithdrawStatus.fromCode(json['status'] as String?),
        reviewNote: json['reviewNote'] as String?,
        createdAt: _parseDt(json['createdAt']),
        paidAt: _parseDt(json['paidAt']),
      );
}

class WithdrawRequestBody {
  final int amountCents;
  final WithdrawMethod method;
  final String account;
  final String accountName;

  const WithdrawRequestBody({
    required this.amountCents,
    required this.method,
    required this.account,
    required this.accountName,
  });

  Map<String, dynamic> toJson() => {
        'amountCents': amountCents,
        'method': method.code,
        'account': account,
        'accountName': accountName,
      };
}

DateTime? _parseDt(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
