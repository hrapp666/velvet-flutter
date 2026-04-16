// ============================================================================
// Order Models · 订单数据模型
// ============================================================================

enum OrderStatus {
  pending('PENDING', '待付款'),
  paid('PAID', '已付款 · 等发货'),
  shipped('SHIPPED', '已发货'),
  received('RECEIVED', '已签收'),
  confirmed('CONFIRMED', '已完成'),
  canceled('CANCELED', '已取消'),
  refundReq('REFUND_REQ', '退款中'),
  refunded('REFUNDED', '已退款');

  final String code;
  final String label;
  const OrderStatus(this.code, this.label);

  static OrderStatus fromCode(String? code) =>
      OrderStatus.values.firstWhere(
        (s) => s.code == code,
        orElse: () => OrderStatus.pending,
      );

  bool get isDone =>
      this == OrderStatus.confirmed ||
      this == OrderStatus.canceled ||
      this == OrderStatus.refunded;
}

class OrderDto {
  final int id;
  final int momentId;
  final int buyerId;
  final String buyerNickname;
  final int sellerId;
  final String sellerNickname;
  final int priceCents;
  final int commissionCents;
  final String? titleSnapshot;
  final String? coverSnapshot;
  final OrderStatus status;
  final String? paymentMethod;
  final DateTime? paidAt;
  final DateTime? shippedAt;
  final String? trackingNo;
  final DateTime? receivedAt;
  final DateTime? confirmedAt;
  final String? buyerNote;
  final String? sellerNote;
  final DateTime? createdAt;

  const OrderDto({
    required this.id,
    required this.momentId,
    required this.buyerId,
    required this.buyerNickname,
    required this.sellerId,
    required this.sellerNickname,
    required this.priceCents,
    this.commissionCents = 0,
    this.titleSnapshot,
    this.coverSnapshot,
    this.status = OrderStatus.pending,
    this.paymentMethod,
    this.paidAt,
    this.shippedAt,
    this.trackingNo,
    this.receivedAt,
    this.confirmedAt,
    this.buyerNote,
    this.sellerNote,
    this.createdAt,
  });

  double get priceYuan => priceCents / 100.0;
  double get commissionYuan => commissionCents / 100.0;
  double get sellerNetYuan => (priceCents - commissionCents) / 100.0;

  factory OrderDto.fromJson(Map<String, dynamic> json) => OrderDto(
        id: (json['id'] as num).toInt(),
        momentId: (json['momentId'] as num).toInt(),
        buyerId: (json['buyerId'] as num).toInt(),
        buyerNickname: json['buyerNickname'] as String? ?? '',
        sellerId: (json['sellerId'] as num).toInt(),
        sellerNickname: json['sellerNickname'] as String? ?? '',
        priceCents: (json['priceCents'] as num).toInt(),
        commissionCents: (json['commissionCents'] as num?)?.toInt() ?? 0,
        titleSnapshot: json['titleSnapshot'] as String?,
        coverSnapshot: json['coverSnapshot'] as String?,
        status: OrderStatus.fromCode(json['status'] as String?),
        paymentMethod: json['paymentMethod'] as String?,
        paidAt: _parseDt(json['paidAt']),
        shippedAt: _parseDt(json['shippedAt']),
        trackingNo: json['trackingNo'] as String?,
        receivedAt: _parseDt(json['receivedAt']),
        confirmedAt: _parseDt(json['confirmedAt']),
        buyerNote: json['buyerNote'] as String?,
        sellerNote: json['sellerNote'] as String?,
        createdAt: _parseDt(json['createdAt']),
      );
}

enum OrderSide {
  buyer('buyer'),
  seller('seller');

  final String path;
  const OrderSide(this.path);
}

DateTime? _parseDt(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
