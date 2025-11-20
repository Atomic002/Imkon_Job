// lib/controller/chat_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version1/Models/chat_models.dart';
import 'package:version1/Models/message_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart'; // ✅ Clipboard uchun

class ChatController extends GetxController {
  final supabase = Supabase.instance.client;

  // Observable lists
  final RxList<ChatModel> chats = <ChatModel>[].obs;
  final RxList<MessageModel> currentMessages = <MessageModel>[].obs;
  final RxMap<String, List<MessageReaction>> messageReactions =
      <String, List<MessageReaction>>{}.obs;

  // Loading states
  final isLoading = false.obs;
  final isSending = false.obs;
  final isDeleting = false.obs;

  // Editing state
  final RxString editingMessageId = ''.obs;
  final RxString editingText = ''.obs;

  // Reply state
  final Rx<MessageModel?> replyingTo = Rx<MessageModel?>(null);

  // Current chat ID
  String? currentChatId;

  // Realtime subscription
  RealtimeChannel? _messagesSubscription;
  RealtimeChannel? _chatsSubscription;

  @override
  void onInit() {
    super.onInit();
    loadChats();
    _subscribeToChatsUpdates();
  }

  @override
  void onClose() {
    _messagesSubscription?.unsubscribe();
    _chatsSubscription?.unsubscribe();
    super.onClose();
  }

  // ==================== CHAT OPERATIONS ====================

  /// Load all chats for current user
  Future<void> loadChats() async {
    try {
      isLoading.value = true;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('chats')
          .select('*')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('last_message_time', ascending: false);

      final List<ChatModel> loadedChats = [];

      for (var chatData in response) {
        final chat = ChatModel.fromJson(chatData);

        // Determine other user
        final otherUserId = chat.user1Id == userId
            ? chat.user2Id
            : chat.user1Id;
        chat.otherUserId = otherUserId;

        // Load other user info
        try {
          final userData = await supabase
              .from('users')
              .select('username, first_name, profile_photo_url')
              .eq('id', otherUserId)
              .maybeSingle(); // ✅ single() o'rniga maybeSingle()

          if (userData != null) {
            chat.otherUserName = userData['first_name'] ?? userData['username'];
            chat.otherUserAvatar = userData['profile_photo_url'];
          } else {
            chat.otherUserName = 'Unknown User';
          }
        } catch (e) {
          print('⚠️ User not found: $otherUserId');
          chat.otherUserName = 'Deleted User';
        }

        // Count unread messages
        try {
          final unreadCount = await supabase
              .from('messages')
              .select('id')
              .eq('chat_id', chat.id)
              .eq('is_read', false)
              .neq('sender_id', userId);

          chat.unreadCount = unreadCount.count ?? 0;
        } catch (e) {
          print('⚠️ Unread count error: $e');
          chat.unreadCount = 0;
        }

        loadedChats.add(chat);
      }

      chats.value = loadedChats;
    } catch (e) {
      print('❌ Load chats error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Create or get existing chat
  Future<String?> createOrGetChat(String otherUserId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Check if chat exists
      final existing = await supabase
          .from('chats')
          .select('id')
          .or(
            'and(user1_id.eq.$userId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$userId)',
          )
          .maybeSingle();

      if (existing != null) {
        return existing['id'];
      }

      // Create new chat
      final newChat = await supabase
          .from('chats')
          .insert({'user1_id': userId, 'user2_id': otherUserId})
          .select('id')
          .single();

      await loadChats();
      return newChat['id'];
    } catch (e) {
      print('❌ Create chat error: $e');
      return null;
    }
  }

  /// Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      await supabase.from('chats').delete().eq('id', chatId);
      chats.removeWhere((chat) => chat.id == chatId);

      Get.snackbar(
        'success'.tr,
        'chat_deleted'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      print('❌ Delete chat error: $e');
      Get.snackbar(
        'error'.tr,
        'delete_chat_error'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ==================== MESSAGE OPERATIONS ====================

  /// Load messages for specific chat
  Future<void> loadMessages(String chatId) async {
    try {
      isLoading.value = true;
      currentChatId = chatId;

      final response = await supabase
          .from('messages')
          .select('*')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      currentMessages.value = response
          .map((e) => MessageModel.fromJson(e))
          .toList();

      // Mark as read
      await _markMessagesAsRead(chatId);

      // Load reactions
      await _loadReactionsForMessages();

      // Subscribe to new messages
      _subscribeToMessages(chatId);
    } catch (e) {
      print('❌ Load messages error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Send message
  Future<void> sendMessage({
    required String chatId,
    String? messageText,
    String? attachmentUrl,
    double? latitude,
    double? longitude,
  }) async {
    try {
      isSending.value = true;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      String? finalAttachment = attachmentUrl;
      if (latitude != null && longitude != null) {
        finalAttachment = 'location:$latitude,$longitude';
      }

      // Check message length
      if (messageText != null && messageText.length > 300) {
        Get.snackbar(
          'error'.tr,
          'message_too_long'.tr,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final messageData = {
        'chat_id': chatId,
        'sender_id': userId,
        'message_text': messageText,
        'attachment_url': finalAttachment,
        'reply_to_id': replyingTo.value?.id,
      };

      await supabase.from('messages').insert(messageData);

      // Update chat's last message
      await supabase
          .from('chats')
          .update({
            'last_message': messageText ?? 'Location',
            'last_message_time': DateTime.now().toIso8601String(),
          })
          .eq('id', chatId);

      // Clear reply state
      replyingTo.value = null;

      // ✅ Reload messages avtomatik ishlaydi realtime orqali
    } catch (e) {
      print('❌ Send message error: $e');
      Get.snackbar(
        'error'.tr,
        'send_message_error'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSending.value = false;
    }
  }

  /// Edit message
  Future<void> editMessage(String messageId, String newText) async {
    try {
      if (newText.isEmpty) {
        Get.snackbar(
          'error'.tr,
          'message_empty'.tr,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      if (newText.length > 300) {
        Get.snackbar(
          'error'.tr,
          'message_too_long'.tr,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      await supabase
          .from('messages')
          .update({'message_text': newText, 'is_edited': true})
          .eq('id', messageId);

      // Update local
      final index = currentMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        currentMessages[index].messageText = newText;
        currentMessages[index].isEdited = true;
        currentMessages.refresh();
      }

      editingMessageId.value = '';
      editingText.value = '';

      Get.snackbar(
        'success'.tr,
        'message_edited'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      print('❌ Edit message error: $e');
      Get.snackbar(
        'error'.tr,
        'edit_message_error'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      isDeleting.value = true;

      await supabase.from('messages').delete().eq('id', messageId);

      currentMessages.removeWhere((m) => m.id == messageId);

      Get.snackbar(
        'success'.tr,
        'message_deleted'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      print('❌ Delete message error: $e');
      Get.snackbar(
        'error'.tr,
        'delete_message_error'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isDeleting.value = false;
    }
  }

  /// Copy message text
  void copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text)); // ✅ To'g'ri ishlaydi
    Get.snackbar(
      'success'.tr,
      'message_copied'.tr,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 1),
    );
  }

  /// Forward message
  Future<void> forwardMessage(String messageId, String targetChatId) async {
    try {
      final message = currentMessages.firstWhere((m) => m.id == messageId);

      await sendMessage(
        chatId: targetChatId,
        messageText: message.messageText,
        attachmentUrl: message.attachmentUrl,
      );

      Get.snackbar(
        'success'.tr,
        'message_forwarded'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      print('❌ Forward message error: $e');
    }
  }

  /// Set reply-to message
  void setReplyTo(MessageModel message) {
    replyingTo.value = message;
  }

  /// Cancel reply
  void cancelReply() {
    replyingTo.value = null;
  }

  /// Start editing
  void startEditing(MessageModel message) {
    editingMessageId.value = message.id;
    editingText.value = message.messageText ?? '';
  }

  /// Cancel editing
  void cancelEditing() {
    editingMessageId.value = '';
    editingText.value = '';
  }

  // ==================== REACTIONS ====================

  /// Add/remove reaction
  Future<void> toggleReaction(String messageId, String emoji) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Check if user already reacted with this emoji
      final existing = await supabase
          .from('message_reactions')
          .select('id')
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('emoji', emoji) // ✅ Aniq emoji tekshirish
          .maybeSingle();

      if (existing != null) {
        // Remove reaction
        await supabase
            .from('message_reactions')
            .delete()
            .eq('id', existing['id']);
      } else {
        // Add reaction
        await supabase.from('message_reactions').insert({
          'message_id': messageId,
          'user_id': userId,
          'emoji': emoji,
        });
      }

      // Reload reactions for this message
      await _loadReactionsForMessage(messageId);
    } catch (e) {
      print('❌ Toggle reaction error: $e');
    }
  }

  /// Load reactions for all messages
  Future<void> _loadReactionsForMessages() async {
    try {
      final messageIds = currentMessages.map((m) => m.id).toList();
      if (messageIds.isEmpty) return;

      final response = await supabase
          .from('message_reactions')
          .select('*')
          .inFilter('message_id', messageIds);

      final Map<String, List<MessageReaction>> reactions = {};

      for (var data in response) {
        final reaction = MessageReaction.fromJson(data);
        if (!reactions.containsKey(reaction.messageId)) {
          reactions[reaction.messageId] = [];
        }
        reactions[reaction.messageId]!.add(reaction);
      }

      messageReactions.value = reactions;
    } catch (e) {
      print('❌ Load reactions error: $e');
    }
  }

  /// Load reactions for single message
  Future<void> _loadReactionsForMessage(String messageId) async {
    try {
      final response = await supabase
          .from('message_reactions')
          .select('*')
          .eq('message_id', messageId);

      final reactions = response
          .map((e) => MessageReaction.fromJson(e))
          .toList();
      messageReactions[messageId] = reactions;
      messageReactions.refresh(); // ✅ UI yangilansin
    } catch (e) {
      print('❌ Load reaction error: $e');
    }
  }

  // ==================== READ STATUS ====================

  /// Mark messages as read
  Future<void> _markMessagesAsRead(String chatId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      // Update local
      for (var message in currentMessages) {
        if (message.senderId != userId) {
          message.isRead = true;
        }
      }
      currentMessages.refresh();

      // ✅ Chat ro'yxatidagi unread countni yangilash
      await loadChats();
    } catch (e) {
      print('❌ Mark read error: $e');
    }
  }

  // ==================== LOCATION ====================

  /// Get current location
  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'error'.tr,
          'location_service_disabled'.tr,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'error'.tr,
            'location_permission_denied'.tr,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'error'.tr,
          'location_permission_permanently_denied'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }

      final position = await Geolocator.getCurrentPosition();
      return {'latitude': position.latitude, 'longitude': position.longitude};
    } catch (e) {
      print('❌ Get location error: $e');
      return null;
    }
  }

  // ==================== REALTIME SUBSCRIPTIONS ====================

  void _subscribeToMessages(String chatId) {
    _messagesSubscription?.unsubscribe();

    _messagesSubscription = supabase
        .channel('messages:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) async {
            final newMessage = MessageModel.fromJson(payload.newRecord);

            // ✅ Duplicate message qo'shmaslik
            if (!currentMessages.any((m) => m.id == newMessage.id)) {
              currentMessages.add(newMessage);
              await _markMessagesAsRead(chatId);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            final updatedMessage = MessageModel.fromJson(payload.newRecord);
            final index = currentMessages.indexWhere(
              (m) => m.id == updatedMessage.id,
            );
            if (index != -1) {
              currentMessages[index] = updatedMessage;
              currentMessages.refresh();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final deletedId = payload.oldRecord['id'];
            currentMessages.removeWhere((m) => m.id == deletedId);
          },
        )
        .subscribe();
  }

  void _subscribeToChatsUpdates() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _chatsSubscription = supabase
        .channel('chats:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chats',
          callback: (payload) => loadChats(),
        )
        .subscribe();
  }

  void clearCurrentChat() {
    currentChatId = null;
    currentMessages.clear();
    messageReactions.clear();
    replyingTo.value = null;
    editingMessageId.value = '';
    _messagesSubscription?.unsubscribe();
  }
}

extension on PostgrestList {
  get count => null;
}

// ==================== MESSAGE REACTION MODEL ====================

class MessageReaction {
  final String id;
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime createdAt;

  MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      id: json['id'],
      messageId: json['message_id'],
      userId: json['user_id'],
      emoji: json['emoji'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
