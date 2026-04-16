// ============================================================================
// Payment Models · 支付数据模型
// ============================================================================

enum PaymentProvider {
  wechat('WECHAT', '微信支付'),
  alipay('ALIPAY', '支付宝'),
  mock('MOCK', '沙盒模拟');

  final String code;
  final String label;
  const PaymentProvider(this.code, this.label);

  static PaymentProvider fromCode(String? code) =>
      PaymentProvider.values.firstWhere(
        (p) => p.code == code,
        orElse: () => PaymentProvider.mock,
      );
}

class PaymentConfig {
  final double commissionRate;
  final List<PaymentProvider> providers;

  const PaymentConfig({
    required this.commissionRate,
    required this.providers,
  });

  factory PaymentConfig.fromJson(Map<String, dynamic> json) {
    final list = (json['providers'] as List?) ?? const [];
    return PaymentConfig(
      commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 0.06,
      providers: list
          .map((e) => PaymentProvider.fromCode(e as String?))
          .toList(),
    );
  }
}

class PaymentCreateResult {
  final String outTradeNo;
  final String? providerOrderId;
  final String? payload;
  final String? mode;

  const PaymentCreateResult({
    required this.outTradeNo,
    this.providerOrderId,
    this.payload,
    this.mode,
  });

  factory PaymentCreateResult.fromJson(Map<String, dynamic> json) =>
      PaymentCreateResult(
        outTradeNo: json['outTradeNo'] as String? ?? '',
        providerOrderId: json['providerOrderId'] as String?,
        payload: json['payload'] as String?,
        mode: json['mode'] as String?,
      );
}
