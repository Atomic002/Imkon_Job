// lib/Models/chat_model.dart
class ChatModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;

  // Qo'shimcha ma'lumotlar
  String? otherUserName;
  String? otherUserAvatar;
  String? otherUserId;
  int unreadCount;

  ChatModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserId,
    this.unreadCount = 0,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
