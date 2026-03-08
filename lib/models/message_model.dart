class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'content': content,
    'sent_at': sentAt.toIso8601String(),
    'is_read': isRead,
  };

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'] ?? '',
    conversationId: json['conversation_id'] ?? '',
    senderId: json['sender_id'] ?? '',
    content: json['content'] ?? '',
    sentAt: DateTime.parse(json['sent_at'] ?? DateTime.now().toIso8601String()),
    isRead: json['is_read'] ?? false,
  );

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    DateTime? sentAt,
    bool? isRead,
  }) => MessageModel(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    senderId: senderId ?? this.senderId,
    content: content ?? this.content,
    sentAt: sentAt ?? this.sentAt,
    isRead: isRead ?? this.isRead,
  );
}
