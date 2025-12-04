// lib/controller/chat_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/Models/chat_models.dart';
import 'package:flutter_application_2/Models/message_model.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ChatController extends GetxController {
  final supabase = Supabase.instance.client;

  // Observable lists
  final RxList<ChatModel> chats = <ChatModel>[].obs;
  final RxList<MessageModel> currentMessages = <MessageModel>[].obs;
  final RxMap<String, List<MessageReaction>> messageReactions =
      <String, List<MessageReaction>>{}.obs;

  // Total unread count
  final RxInt totalUnreadCount = 0.obs;

  // Online users tracking
  final RxMap<String, bool> onlineUsers = <String, bool>{}.obs;

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

  // Realtime subscriptions
  RealtimeChannel? _messagesSubscription;
  RealtimeChannel? _chatsSubscription;
  RealtimeChannel? _presenceSubscription;
  RealtimeChannel? _reactionsSubscription;

  @override
  void onInit() {
    super.onInit();
    loadChats();
    _subscribeToChatsUpdates();
    _subscribeToPresence();
    _startUnreadCountRefresh();
  }

  Timer? _unreadCountTimer;

  void _startUnreadCountRefresh() {
    _unreadCountTimer?.cancel();
    _unreadCountTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateTotalUnreadCount();
    });
  }

  Future<void> _updateTotalUnreadCount() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      int totalUnread = 0;
      for (var chat in chats) {
        try {
          final unreadData = await supabase
              .from('messages')
              .select('id')
              .eq('chat_id', chat.id)
              .eq('is_read', false)
              .neq('sender_id', userId);

          totalUnread += unreadData.length;
        } catch (e) {
          print('⚠️ Update unread count error: $e');
        }
      }

      totalUnreadCount.value = totalUnread;
    } catch (e) {
      print('❌ Update total unread error: $e');
    }
  }

  @override
  void onClose() {
    _unreadCountTimer?.cancel();
    _messagesSubscription?.unsubscribe();
    _chatsSubscription?.unsubscribe();
    _presenceSubscription?.unsubscribe();
    _reactionsSubscription?.unsubscribe();
    super.onClose();
  }

  // ==================== PRESENCE (ONLINE STATUS) ====================

  void _subscribeToPresence() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      _presenceSubscription = supabase
          .channel('online_users')
          .onPresenceSync((payload) {
            try {
              final state = _presenceSubscription?.presenceState();
              if (state != null && state.isNotEmpty) {
                final Map<String, bool> newOnlineUsers = {};

                state.forEach(
                  (userId, presences) {
                        if (presences is List && presences.isNotEmpty) {
                          final presence = presences.first;
                          if (presence is Map<String, dynamic>) {
                            final uid = presence['user_id'] as String?;
                            if (uid != null) {
                              newOnlineUsers[uid] = true;
                            }
                          }
                        }
                      }
                      as void Function(SinglePresenceState element),
                );

                onlineUsers.value = newOnlineUsers;
              }
            } catch (e) {
              print('⚠️ Presence sync error: $e');
            }
          })
          .subscribe((status, error) async {
            if (status == RealtimeSubscribeStatus.subscribed) {
              await _presenceSubscription?.track({'user_id': userId});
              print('✅ Presence tracking started');
            }
          });
    } catch (e) {
      print('❌ Presence setup error: $e');
    }
  }

  bool isUserOnline(String userId) => onlineUsers[userId] ?? false;

  // ==================== CHAT OPERATIONS ====================

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
      int totalUnread = 0;

      for (var chatData in response) {
        final chat = ChatModel.fromJson(chatData);
        final otherUserId = chat.user1Id == userId
            ? chat.user2Id
            : chat.user1Id;
        chat.otherUserId = otherUserId;

        try {
          final userData = await supabase
              .from('users')
              .select('username, first_name, profile_photo_url')
              .eq('id', otherUserId)
              .maybeSingle();

          if (userData != null) {
            chat.otherUserName = userData['first_name'] ?? userData['username'];
            chat.otherUserAvatar = userData['profile_photo_url'];
          } else {
            chat.otherUserName = 'Unknown User';
          }
        } catch (e) {
          chat.otherUserName = 'Deleted User';
        }

        try {
          final unreadData = await supabase
              .from('messages')
              .select('id')
              .eq('chat_id', chat.id)
              .eq('is_read', false)
              .neq('sender_id', userId);

          chat.unreadCount = unreadData.length;
          totalUnread += unreadData.length;
        } catch (e) {
          chat.unreadCount = 0;
        }

        loadedChats.add(chat);
      }

      chats.value = loadedChats;
      totalUnreadCount.value = totalUnread;
    } catch (e) {
      print('❌ Load chats error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> createOrGetChat(String otherUserId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

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

  Future<void> deleteChat(String chatId) async {
    try {
      await supabase.from('chats').delete().eq('id', chatId);
      chats.removeWhere((chat) => chat.id == chatId);
      await loadChats();

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

      await _markMessagesAsRead(chatId);
      await _loadReactionsForMessages();
      _subscribeToMessages(chatId);
      _subscribeToReactions(chatId);
    } catch (e) {
      print('❌ Load messages error: $e');
    } finally {
      isLoading.value = false;
    }
  }

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

      await supabase
          .from('chats')
          .update({
            'last_message': messageText ?? 'Location',
            'last_message_time': DateTime.now().toIso8601String(),
          })
          .eq('id', chatId);

      replyingTo.value = null;
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

  Future<void> editMessage(String messageId, String newText) async {
    try {
      if (newText.isEmpty || newText.length > 300) {
        Get.snackbar(
          'error'.tr,
          newText.isEmpty ? 'message_empty'.tr : 'message_too_long'.tr,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      await supabase
          .from('messages')
          .update({'message_text': newText, 'is_edited': true})
          .eq('id', messageId);

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
      );
    } catch (e) {
      print('❌ Edit message error: $e');
    }
  }

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
      );
    } catch (e) {
      print('❌ Delete message error: $e');
    } finally {
      isDeleting.value = false;
    }
  }

  void copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'success'.tr,
      'message_copied'.tr,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
    );
  }

  void setReplyTo(MessageModel message) => replyingTo.value = message;
  void cancelReply() => replyingTo.value = null;

  void startEditing(MessageModel message) {
    editingMessageId.value = message.id;
    editingText.value = message.messageText ?? '';
  }

  void cancelEditing() {
    editingMessageId.value = '';
    editingText.value = '';
  }

  // ==================== REACTIONS ====================

  Future<void> toggleReaction(String messageId, String emoji) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final existing = await supabase
          .from('message_reactions')
          .select('id')
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('emoji', emoji)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('message_reactions')
            .delete()
            .eq('id', existing['id']);
      } else {
        await supabase.from('message_reactions').insert({
          'message_id': messageId,
          'user_id': userId,
          'emoji': emoji,
        });
      }

      await _loadReactionsForMessage(messageId);
    } catch (e) {
      print('❌ Toggle reaction error: $e');
    }
  }

  Future<void> _loadReactionsForMessages() async {
    try {
      final messageIds = currentMessages.map((m) => m.id).toList();
      if (messageIds.isEmpty) return;

      final response = await supabase
          .from('message_reactions')
          .select('*')
          .inFilter('message_id', messageIds);

      final userIds = response.map((r) => r['user_id'] as String).toSet();
      Map<String, Map<String, dynamic>> usersMap = {};

      if (userIds.isNotEmpty) {
        final usersData = await supabase
            .from('users')
            .select('id, username, first_name')
            .inFilter('id', userIds.toList());

        for (var user in usersData) {
          usersMap[user['id']] = user;
        }
      }

      final Map<String, List<MessageReaction>> reactions = {};

      for (var data in response) {
        final userId = data['user_id'] as String;
        final userData = usersMap[userId];

        if (userData != null) {
          data['users'] = userData;
        }

        final reaction = MessageReaction.fromJson(data);
        reactions.putIfAbsent(reaction.messageId, () => []).add(reaction);
      }

      messageReactions.value = reactions;
    } catch (e) {
      print('❌ Load reactions error: $e');
    }
  }

  Future<void> _loadReactionsForMessage(String messageId) async {
    try {
      final response = await supabase
          .from('message_reactions')
          .select('*')
          .eq('message_id', messageId);

      final userIds = response.map((r) => r['user_id'] as String).toSet();
      Map<String, Map<String, dynamic>> usersMap = {};

      if (userIds.isNotEmpty) {
        final usersData = await supabase
            .from('users')
            .select('id, username, first_name')
            .inFilter('id', userIds.toList());

        for (var user in usersData) {
          usersMap[user['id']] = user;
        }
      }

      final reactions = response.map((data) {
        final userId = data['user_id'] as String;
        final userData = usersMap[userId];

        if (userData != null) {
          data['users'] = userData;
        }

        return MessageReaction.fromJson(data);
      }).toList();

      messageReactions[messageId] = reactions;
      messageReactions.refresh();
    } catch (e) {
      print('❌ Load reaction error: $e');
    }
  }

  // ==================== READ STATUS ====================

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

      for (var message in currentMessages) {
        if (message.senderId != userId) {
          message.isRead = true;
        }
      }
      currentMessages.refresh();
      await loadChats();
    } catch (e) {
      print('❌ Mark read error: $e');
    }
  }

  // ==================== LOCATION ====================

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

  void _subscribeToReactions(String chatId) {
    _reactionsSubscription?.unsubscribe();

    _reactionsSubscription = supabase
        .channel('reactions:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'message_reactions',
          callback: (payload) async {
            await _loadReactionsForMessages();
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
          callback: (payload) {
            loadChats();
          },
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
    _reactionsSubscription?.unsubscribe();
  }
}

// ==================== MESSAGE REACTION MODEL ====================

class MessageReaction {
  final String id;
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime createdAt;
  String? userName;

  MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
    this.userName,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    String? name;
    if (json['users'] != null) {
      final user = json['users'] as Map<String, dynamic>;
      name = user['first_name'] ?? user['username'];
    }

    return MessageReaction(
      id: json['id'],
      messageId: json['message_id'],
      userId: json['user_id'],
      emoji: json['emoji'],
      createdAt: DateTime.parse(json['created_at']),
      userName: name,
    );
  }
}
