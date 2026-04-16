// ============================================================================
// Chat models · Conversation + Message + WsConnectionState
// ============================================================================

/// WebSocket 连接状态枚举
enum WsConnectionState {
  /// 初始状态，或 disconnect() 调用后
  disconnected,

  /// _open() 执行中（正在建立连接）
  connecting,

  /// 连接成功，channel 已就绪
  connected,

  /// 连接断开，正在等待下次重连
  reconnecting,

  /// 超过最大重连次数，彻底放弃（UI 应暴露"点击重试"）
  failed,
}

class ConversationModel {
  final int id;
  final int otherUserId;
  final String otherUserNickname;
  final String? otherUserAvatarUrl;
  final int? momentId;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final int unread;

  const ConversationModel({
    required this.id,
    required this.otherUserId,
    required this.otherUserNickname,
    this.otherUserAvatarUrl,
    this.momentId,
    this.lastMessageContent,
    this.lastMessageAt,
    required this.unread,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: (json['id'] as num).toInt(),
      otherUserId: (json['otherUserId'] as num).toInt(),
      otherUserNickname: json['otherUserNickname'] as String? ?? '匿名',
      otherUserAvatarUrl: json['otherUserAvatarUrl'] as String?,
      momentId: (json['momentId'] as num?)?.toInt(),
      lastMessageContent: json['lastMessageContent'] as String?,
      lastMessageAt: _parseDate(json['lastMessageAt']),
      unread: (json['unread'] as num?)?.toInt() ?? 0,
    );
  }
}

class MessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderNickname;
  final String type;
  final String content;
  final String? mediaUrl;
  final int? refMomentId;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderNickname,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.refMomentId,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: (json['id'] as num).toInt(),
      conversationId: (json['conversationId'] as num).toInt(),
      senderId: (json['senderId'] as num).toInt(),
      senderNickname: json['senderNickname'] as String? ?? '匿名',
      type: json['type'] as String? ?? 'TEXT',
      content: json['content'] as String? ?? '',
      mediaUrl: json['mediaUrl'] as String?,
      refMomentId: (json['refMomentId'] as num?)?.toInt(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
