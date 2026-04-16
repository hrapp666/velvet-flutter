// ============================================================================
// Merchant Models · 商家认证数据模型
// ============================================================================

enum SellerType {
  personal('PERSONAL', '个人'),
  business('BUSINESS', '企业');

  final String code;
  final String label;
  const SellerType(this.code, this.label);

  static SellerType fromCode(String? code) =>
      SellerType.values.firstWhere(
        (s) => s.code == code,
        orElse: () => SellerType.personal,
      );
}

enum MerchantStatus {
  none('NONE', '未申请'),
  pending('PENDING', '审核中'),
  approved('APPROVED', '已认证'),
  rejected('REJECTED', '被拒绝');

  final String code;
  final String label;
  const MerchantStatus(this.code, this.label);

  static MerchantStatus fromCode(String? code) =>
      MerchantStatus.values.firstWhere(
        (s) => s.code == code,
        orElse: () => MerchantStatus.none,
      );
}

class MerchantDto {
  final int? id;
  final int userId;
  final String shopName;
  final String? shopAvatar;
  final String? shopCover;
  final String? shopIntro;
  final String? contactName;
  final String? contactPhone;
  final String? contactWechat;
  final SellerType sellerType;
  final String? personalRealName;
  final String? personalIdNo;
  final String? receiveAlipay;
  final String? receiveWechat;
  final String? receiveBankCard;
  final String? receiveBankName;
  final MerchantStatus status;
  final String? reviewNote;
  final double rating;
  final int salesCount;
  final DateTime? createdAt;

  const MerchantDto({
    this.id,
    required this.userId,
    required this.shopName,
    this.shopAvatar,
    this.shopCover,
    this.shopIntro,
    this.contactName,
    this.contactPhone,
    this.contactWechat,
    this.sellerType = SellerType.personal,
    this.personalRealName,
    this.personalIdNo,
    this.receiveAlipay,
    this.receiveWechat,
    this.receiveBankCard,
    this.receiveBankName,
    this.status = MerchantStatus.pending,
    this.reviewNote,
    this.rating = 0,
    this.salesCount = 0,
    this.createdAt,
  });

  factory MerchantDto.fromJson(Map<String, dynamic> json) => MerchantDto(
        id: (json['id'] as num?)?.toInt(),
        userId: (json['userId'] as num).toInt(),
        shopName: json['shopName'] as String? ?? '',
        shopAvatar: json['shopAvatar'] as String?,
        shopCover: json['shopCover'] as String?,
        shopIntro: json['shopIntro'] as String?,
        contactName: json['contactName'] as String?,
        contactPhone: json['contactPhone'] as String?,
        contactWechat: json['contactWechat'] as String?,
        sellerType: SellerType.fromCode(json['sellerType'] as String?),
        personalRealName: json['personalRealName'] as String?,
        personalIdNo: json['personalIdNo'] as String?,
        receiveAlipay: json['receiveAlipay'] as String?,
        receiveWechat: json['receiveWechat'] as String?,
        receiveBankCard: json['receiveBankCard'] as String?,
        receiveBankName: json['receiveBankName'] as String?,
        status: MerchantStatus.fromCode(json['status'] as String?),
        reviewNote: json['reviewNote'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        salesCount: (json['salesCount'] as num?)?.toInt() ?? 0,
        createdAt: _parseDt(json['createdAt']),
      );
}

class MerchantApplyBody {
  final String shopName;
  final String? shopIntro;
  final SellerType sellerType;
  final String? contactName;
  final String? contactPhone;
  final String? contactWechat;
  final String? personalRealName;
  final String? personalIdNo;
  final String? receiveWechat;
  final String? receiveAlipay;
  final String? receiveBankCard;
  final String? receiveBankName;

  const MerchantApplyBody({
    required this.shopName,
    this.shopIntro,
    this.sellerType = SellerType.personal,
    this.contactName,
    this.contactPhone,
    this.contactWechat,
    this.personalRealName,
    this.personalIdNo,
    this.receiveWechat,
    this.receiveAlipay,
    this.receiveBankCard,
    this.receiveBankName,
  });

  Map<String, dynamic> toJson() => {
        'shopName': shopName,
        if (shopIntro != null) 'shopIntro': shopIntro,
        'sellerType': sellerType.code,
        if (contactName != null) 'contactName': contactName,
        if (contactPhone != null) 'contactPhone': contactPhone,
        if (contactWechat != null) 'contactWechat': contactWechat,
        if (personalRealName != null) 'personalRealName': personalRealName,
        if (personalIdNo != null) 'personalIdNo': personalIdNo,
        if (receiveWechat != null) 'receiveWechat': receiveWechat,
        if (receiveAlipay != null) 'receiveAlipay': receiveAlipay,
        if (receiveBankCard != null) 'receiveBankCard': receiveBankCard,
        if (receiveBankName != null) 'receiveBankName': receiveBankName,
      };
}

DateTime? _parseDt(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
