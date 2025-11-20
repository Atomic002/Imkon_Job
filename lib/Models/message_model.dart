// lib/Models/message_model.dart
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  String? messageText;
  final String? attachmentUrl;
  bool isRead;
  final DateTime createdAt;
  bool isEdited;
  final String? replyToId;

  // Additional data
  String? senderName;
  String? senderAvatar;
  MessageModel? replyToMessage;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.messageText,
    this.attachmentUrl,
    required this.isRead,
    required this.createdAt,
    this.isEdited = false,
    this.replyToId,
    this.senderName,
    this.senderAvatar,
    this.replyToMessage,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      messageText: json['message_text'],
      attachmentUrl: json['attachment_url'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      isEdited: json['is_edited'] ?? false,
      replyToId: json['reply_to_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'message_text': messageText,
      'attachment_url': attachmentUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'is_edited': isEdited,
      'reply_to_id': replyToId,
    };
  }
}
