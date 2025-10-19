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
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      messageText: json['message_text'],
      attachmentUrl: json['attachment_url'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'sender_id': senderId,
      'message_text': messageText,
      'attachment_url': attachmentUrl,
      'is_read': isRead,
    };
  }
}
