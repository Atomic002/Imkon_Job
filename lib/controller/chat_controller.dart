// lib/Controllers/chat_controller.dart
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version1/Models/chat_models.dart';
import 'package:version1/Models/message_model.dart';

class ChatController extends GetxController {
  final supabase = Supabase.instance.client;

  final RxList<ChatModel> chats = <ChatModel>[].obs;
  final RxList<MessageModel> currentMessages = <MessageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;

  String? currentChatId; // ✅ Hozirgi ochiq chat ID

  RealtimeChannel? _chatChannel;
  RealtimeChannel? _messageChannel;

  @override
  void onInit() {
    super.onInit();
    loadChats();
    setupRealtimeListeners();
  }

  @override
  void onClose() {
    _chatChannel?.unsubscribe();
    _messageChannel?.unsubscribe();
    super.onClose();
  }

  // Chatlarni yuklash
  Future<void> loadChats() async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      if (chats.isEmpty) {
        isLoading.value = true;
      }

      final response = await supabase
          .from('chats')
          .select('''
            id,
            user1_id,
            user2_id,
            last_message,
            last_message_time,
            created_at
          ''')
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
          .order('last_message_time', ascending: false);

      final List<ChatModel> loadedChats = [];

      for (var chatData in response) {
        final chat = ChatModel.fromJson(chatData);

        final otherUserId = chat.user1Id == currentUserId
            ? chat.user2Id
            : chat.user1Id;

        final userResponse = await supabase
            .from('users')
            .select('id, first_name, last_name, username, profile_photo_url')
            .eq('id', otherUserId)
            .single();

        chat.otherUserId = otherUserId;
        chat.otherUserName =
            '${userResponse['first_name'] ?? ''} ${userResponse['last_name'] ?? ''}'
                .trim();
        if (chat.otherUserName!.isEmpty) {
          chat.otherUserName = userResponse['username'] ?? 'User';
        }
        chat.otherUserAvatar = userResponse['profile_photo_url'];

        final unreadResponse = await supabase
            .from('messages')
            .select('id')
            .eq('chat_id', chat.id)
            .eq('is_read', false)
            .neq('sender_id', currentUserId);

        chat.unreadCount = unreadResponse.length;

        loadedChats.add(chat);
      }

      chats.value = loadedChats;
      print('✅ ${loadedChats.length} ta chat yuklandi');
    } catch (e) {
      print('❌ Load chats error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Xabarlarni yuklash
  Future<void> loadMessages(String chatId) async {
    try {
      isLoading.value = true;
      currentChatId = chatId; // ✅ Hozirgi chatni saqlaymiz

      final response = await supabase
          .from('messages')
          .select('*')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      currentMessages.value = response
          .map<MessageModel>((json) => MessageModel.fromJson(json))
          .toList();

      print('✅ ${currentMessages.length} ta xabar yuklandi');

      await markMessagesAsRead(chatId);
    } catch (e) {
      print('❌ Load messages error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ YANGILANGAN - Xabar yuborish (darhol ko'rinadi)
  Future<void> sendMessage({
    required String chatId,
    String? messageText,
    String? attachmentUrl,
    double? latitude,
    double? longitude,
  }) async {
    try {
      isSending.value = true;
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) return;

      final now = DateTime.now();
      final messageId =
          supabase.auth.currentUser!.id + now.millisecondsSinceEpoch.toString();

      final messageData = {
        'chat_id': chatId,
        'sender_id': currentUserId,
        'message_text': messageText,
        'attachment_url': attachmentUrl,
        'is_read': false,
        'created_at': now.toIso8601String(),
      };

      // Agar lokatsiya bo'lsa
      if (latitude != null && longitude != null) {
        messageData['attachment_url'] = 'location:$latitude,$longitude';
        messageData['message_text'] = null;
      }

      // ✅ AVVAL LOCAL GA QO'SHAMIZ (Darhol ko'rinadi)
      final tempMessage = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: currentUserId,
        messageText: messageText,
        attachmentUrl: latitude != null && longitude != null
            ? 'location:$latitude,$longitude'
            : attachmentUrl,
        isRead: false,
        createdAt: now,
      );

      currentMessages.add(tempMessage);

      // ✅ KEYIN DATABASE GA YUBORIRAMIZ
      final insertedMessage = await supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      // ✅ Temp message ni real message bilan almashtiramiz
      final index = currentMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        currentMessages[index] = MessageModel.fromJson(insertedMessage);
      }

      // Chatni yangilash
      await supabase
          .from('chats')
          .update({
            'last_message': messageText ?? '📍 Lokatsiya',
            'last_message_time': now.toIso8601String(),
          })
          .eq('id', chatId);

      print('✅ Xabar yuborildi');
    } catch (e) {
      print('❌ Send message error: $e');

      // Xato bo'lsa, temp message ni o'chiramiz
      currentMessages.removeWhere(
        (m) =>
            m.senderId == supabase.auth.currentUser?.id &&
            m.createdAt.isAfter(
              DateTime.now().subtract(const Duration(seconds: 5)),
            ),
      );

      Get.snackbar(
        'Xato',
        'Xabar yuborishda xato',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }

  // Xabarlarni o'qilgan deb belgilash
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);

      print('✅ Xabarlar o\'qilgan deb belgilandi');
    } catch (e) {
      print('❌ Mark messages as read error: $e');
    }
  }

  // ✅ YANGILANGAN - Realtime listeners
  void setupRealtimeListeners() {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    print('📡 Realtime listeners sozlanmoqda...');

    // ✅ Xabarlar uchun listener (BIRINCHI)
    _messageChannel = supabase
        .channel('messages-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) async {
            print('📨 Yangi xabar keldi: ${payload.newRecord}');

            try {
              final newMessage = MessageModel.fromJson(payload.newRecord);

              // ✅ Agar bu chat ochiq bo'lsa VA bu mening xabarim bo'lmasa
              if (currentChatId == newMessage.chatId &&
                  newMessage.senderId != currentUserId) {
                // Agar xabar mavjud bo'lmasa, qo'shamiz
                if (!currentMessages.any((m) => m.id == newMessage.id)) {
                  currentMessages.add(newMessage);
                  print('✅ Yangi xabar qo\'shildi');

                  // Xabarni darhol o'qilgan deb belgilaymiz
                  await markMessagesAsRead(newMessage.chatId);
                }
              }

              // Chatlar ro'yxatini yangilaymiz (background)
              loadChats();
            } catch (e) {
              print('❌ Xabarni parse qilishda xato: $e');
            }
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            print('✅ Messages channel subscribe bo\'ldi');
          } else if (error != null) {
            print('❌ Messages channel xato: $error');
          }
        });

    // ✅ Chatlar uchun listener
    _chatChannel = supabase
        .channel('chats-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chats',
          callback: (payload) {
            print('📨 Chat yangilandi');
            loadChats();
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            print('✅ Chats channel subscribe bo\'ldi');
          } else if (error != null) {
            print('❌ Chats channel xato: $error');
          }
        });
  }

  // Lokatsiyani olish
  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      print('📍 Lokatsiya olinmoqda...');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Lokatsiya ruxsati berilmadi');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Lokatsiya ruxsati butunlay bekor qilingan');
        Get.snackbar(
          'Ruxsat kerak',
          'Lokatsiyani yuborish uchun sozlamalardan ruxsat bering',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('✅ Lokatsiya olindi: ${position.latitude}, ${position.longitude}');

      return {'latitude': position.latitude, 'longitude': position.longitude};
    } catch (e) {
      print('❌ Get location error: $e');
      return null;
    }
  }

  // ✅ Chat screen dan chiqqanda
  void clearCurrentChat() {
    currentChatId = null;
    currentMessages.clear();
  }
}
