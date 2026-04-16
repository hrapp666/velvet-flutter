// ============================================================================
// Moment 数据模型 — 跟后端 MomentDto 对齐
// ============================================================================

class MomentModel {
  final int id;
  final int userId;
  final String userNickname;
  final String? userAvatarUrl;
  final String? title;
  final String content;
  final String? coverUrl;
  final List<String> mediaUrls;
  final bool hasItem;
  final int? itemPriceCents;
  final Map<String, dynamic> itemAttributes;
  final List<String> tags;
  final String? location;
  final double? latitude;
  final double? longitude;
  /// 仅在 nearby 查询返回时填充（米），其他场景为 null
  final double? distanceMeters;
  final String visibility;
  final String status;
  final int viewCount;
  final int likeCount;
  final int favoriteCount;
  final int commentCount;
  final int chatCount;
  final bool liked;
  final bool favorited;
  final DateTime? createdAt;

  const MomentModel({
    required this.id,
    required this.userId,
    required this.userNickname,
    this.userAvatarUrl,
    this.title,
    required this.content,
    this.coverUrl,
    this.mediaUrls = const [],
    this.hasItem = false,
    this.itemPriceCents,
    this.itemAttributes = const {},
    this.tags = const [],
    this.location,
    this.latitude,
    this.longitude,
    this.distanceMeters,
    this.visibility = 'PUBLIC',
    this.status = 'PUBLISHED',
    this.viewCount = 0,
    this.likeCount = 0,
    this.favoriteCount = 0,
    this.commentCount = 0,
    this.chatCount = 0,
    this.liked = false,
    this.favorited = false,
    this.createdAt,
  });

  factory MomentModel.fromJson(Map<String, dynamic> json) {
    return MomentModel(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      userNickname: json['userNickname'] as String? ?? '未知',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      mediaUrls: (json['mediaUrls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      hasItem: json['hasItem'] as bool? ?? false,
      itemPriceCents: (json['itemPriceCents'] as num?)?.toInt(),
      itemAttributes: (json['itemAttributes'] as Map?)?.cast<String, dynamic>() ?? const {},
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      visibility: json['visibility'] as String? ?? 'PUBLIC',
      status: json['status'] as String? ?? 'PUBLISHED',
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      chatCount: (json['chatCount'] as num?)?.toInt() ?? 0,
      liked: json['liked'] as bool? ?? false,
      favorited: json['favorited'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  /// 价格元（用于显示）
  double get priceYuan => (itemPriceCents ?? 0) / 100.0;

  /// 距离的人话（用于 UI 标签）— 1.2 km / 380 m
  String? get distanceLabel {
    final d = distanceMeters;
    if (d == null) return null;
    if (d < 1000) return '${d.round()}m';
    return '${(d / 1000).toStringAsFixed(d < 10000 ? 1 : 0)}km';
  }
}

class CreateMomentBody {
  final String? title;
  final String content;
  final String? coverUrl;
  final List<String> mediaUrls;
  final bool hasItem;
  final int? itemPriceCents;
  final Map<String, dynamic> itemAttributes;
  final List<String> tags;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String visibility;

  const CreateMomentBody({
    this.title,
    required this.content,
    this.coverUrl,
    this.mediaUrls = const [],
    this.hasItem = false,
    this.itemPriceCents,
    this.itemAttributes = const {},
    this.tags = const [],
    this.location,
    this.latitude,
    this.longitude,
    this.visibility = 'PUBLIC',
  });

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        'content': content,
        if (coverUrl != null) 'coverUrl': coverUrl,
        'mediaUrls': mediaUrls,
        'hasItem': hasItem,
        if (itemPriceCents != null) 'itemPriceCents': itemPriceCents,
        'itemAttributes': itemAttributes,
        'tags': tags,
        if (location != null) 'location': location,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'visibility': visibility,
      };
}

/// 分页响应
class Page<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;
  final bool last;

  const Page({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.last,
  });

  factory Page.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parser,
  ) {
    return Page(
      content: (json['content'] as List)
          .map((e) => parser(e as Map<String, dynamic>))
          .toList(),
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      number: (json['number'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      last: json['last'] as bool? ?? true,
    );
  }
}
