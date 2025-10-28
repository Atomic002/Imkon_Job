// lib/Models/message_model.dart
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? messageText;
  final String? attachmentUrl;
  final bool isRead;
  final DateTime createdAt;

  // Lokatsiya uchun
  final double? latitude;
  final double? longitude;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.messageText,
    this.attachmentUrl,
    required this.isRead,
    required this.createdAt,
    this.latitude,
    this.longitude,
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
      latitude: json['latitude'],
      longitude: json['longitude'],
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
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  bool get isLocation => latitude != null && longitude != null;
}
