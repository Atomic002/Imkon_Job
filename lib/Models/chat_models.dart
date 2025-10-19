// lib/Models/chat_model.dart
class ChatModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user1_id': user1Id,
    'user2_id': user2Id,
    'last_message': lastMessage,
    'last_message_time': lastMessageTime?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };
}

// lib/Models/message_model.dart
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? messageText;
  final String? attachmentUrl;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.messageText,
    this.attachmentUrl,
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      messageText: json['message_text'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'chat_id': chatId,
    'sender_id': senderId,
    'message_text': messageText,
    'attachment_url': attachmentUrl,
    'is_read': isRead,
  };
}
