class ConversationModel {
  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final Map<String, int> unreadCount;

  ConversationModel({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
    this.unreadCount = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'participant_ids': participantIds,
    'last_message': lastMessage,
    'last_message_at': lastMessageAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'unread_count': unreadCount,
  };

  factory ConversationModel.fromJson(Map<String, dynamic> json) => ConversationModel(
    id: json['id'] ?? '',
    participantIds: List<String>.from(json['participant_ids'] ?? []),
    lastMessage: json['last_message'],
    lastMessageAt: DateTime.parse(json['last_message_at'] ?? DateTime.now().toIso8601String()),
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    unreadCount: Map<String, int>.from(json['unread_count'] ?? {}),
  );

  ConversationModel copyWith({
    String? id,
    List<String>? participantIds,
    String? lastMessage,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    Map<String, int>? unreadCount,
  }) => ConversationModel(
    id: id ?? this.id,
    participantIds: participantIds ?? this.participantIds,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    createdAt: createdAt ?? this.createdAt,
    unreadCount: unreadCount ?? this.unreadCount,
  );
}
