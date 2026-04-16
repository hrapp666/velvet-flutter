// ============================================================================
// Notification model
// ============================================================================

class NotificationModel {
  final int id;
  final int userId;
  final String type; // LIKE / COMMENT / FOLLOW / DM / FAVORITE / SYSTEM
  final String title;
  final String? content;
  final int? actorId;
  final String? targetType;
  final int? targetId;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.content,
    this.actorId,
    this.targetType,
    this.targetId,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      type: json['type'] as String? ?? 'SYSTEM',
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      actorId: (json['actorId'] as num?)?.toInt(),
      targetType: json['targetType'] as String?,
      targetId: (json['targetId'] as num?)?.toInt(),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
