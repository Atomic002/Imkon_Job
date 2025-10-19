import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version1/Models/chat_models.dart';

class ChatController extends GetxController {
  // ✅ Observable variables
  final chats = <ChatModel>[].obs;
  final messages = <MessageModel>[].obs;
  final isLoading = false.obs;
  final currentChatId = Rxn<String>();

  // ✅ Supabase client
  final supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    loadChats();
  }

  // ==================== CHATS LOAD ====================
  // Barcha chatlarni Supabase dan olish
  Future<void> loadChats() async {
    try {
      isLoading.value = true;

      // ✅ Logged in user ni olish
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        print('User not logged in');
        return;
      }

      // ✅ Supabase query - user1_id yoki user2_id ga teng bo'lgan chatlar
      final response = await supabase
          .from('chats')
          .select()
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('last_message_time', ascending: false);

      // ✅ JSON ni ChatModel ga convert qilish
      chats.value = (response as List)
          .map((c) => ChatModel.fromJson(c as Map<String, dynamic>))
          .toList();

      print('${chats.length} ta chat yuklandi');
    } catch (e) {
      print('Chats load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== MESSAGES LOAD ====================
  // Bitta chatning barcha messagelarini olish
  Future<void> loadMessages(String chatId) async {
    try {
      isLoading.value = true;
      currentChatId.value = chatId;

      // ✅ Supabase query - chat_id ga teng bo'lgan barcha messages
      final response = await supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false);

      // ✅ JSON ni MessageModel ga convert qilish
      messages.value = (response as List)
          .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
          .toList();

      print('${messages.length} ta xabar yuklandi');
    } catch (e) {
      print('Messages load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== SEND MESSAGE ====================
  // Yangi xabar yuborish
  Future<void> sendMessage(String text) async {
    try {
      // ✅ Logged in user ni olish
      final userId = supabase.auth.currentUser?.id;
      final chatId = currentChatId.value;

      if (userId == null || chatId == null || text.isEmpty) {
        print('Invalid parameters');
        return;
      }

      // ✅ Message ni Supabase ga insert qilish
      await supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': userId,
        'message_text': text,
        'is_read': false,
      });

      // ✅ Chat ni last_message bilan update qilish
      await supabase
          .from('chats')
          .update({
            'last_message': text,
            'last_message_time': DateTime.now().toIso8601String(),
          })
          .eq('id', chatId);

      // ✅ Xabarlarni qayta yuklash
      await loadMessages(chatId);

      print('Xabar yuborildi');
    } catch (e) {
      print('Send message error: $e');
    }
  }

  // ==================== CREATE CHAT ====================
  // Ikkita user o'rtasida chat yaratish
  Future<String?> createOrGetChat(String otherUserId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // ✅ Oldindan chat bor-yo'qligini tekshirish
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

      // ✅ Yangi chat yaratish
      final response = await supabase
          .from('chats')
          .insert({'user1_id': userId, 'user2_id': otherUserId})
          .select()
          .single();

      return response['id'];
    } catch (e) {
      print('Create chat error: $e');
      return null;
    }
  }

  // ==================== DELETE CHAT ====================
  // Chatni o'chirish
  Future<void> deleteChat(String chatId) async {
    try {
      await supabase.from('chats').delete().eq('id', chatId);
      chats.removeWhere((c) => c.id == chatId);
      print('Chat o\'chirildi');
    } catch (e) {
      print('Delete chat error: $e');
    }
  }

  // ==================== MARK AS READ ====================
  // Xabarni o'qilgan deb belgilash
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId);

      print('Xabarlar o\'qilgan deb belgilandi');
    } catch (e) {
      print('Mark as read error: $e');
    }
  }

  @override
  void onClose() {
    currentChatId.close();
    super.onClose();
  }
}
