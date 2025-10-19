import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version1/controller/chat_controller.dart';
import '../../config/constants.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late ChatController controller;
  final messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.find<ChatController>();

    // ✅ Chat ID ni arguments dan olish
    final chatId = Get.arguments as String;
    print('Chat ID: $chatId');

    // ✅ Messages ni load qilish
    controller.loadMessages(chatId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kompaniya 1'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: Column(
        children: [
          // ==================== MESSAGES LIST ====================
          Expanded(
            child: Obx(() {
              // ✅ Loading state
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // ✅ Messages bo'sh bo'lsa
              if (controller.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hozircha xabar yo\'q',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              // ✅ Messages list
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final msg = controller.messages[index];

                  // ✅ Supabase dan current user ID olish
                  final currentUserId =
                      Supabase.instance.client.auth.currentUser?.id;

                  // ✅ Xabar meniki yoki boshqasinkimi?
                  final isMe = msg.senderId == currentUserId;

                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        // ✅ Meniki bo'lsa - blue, boshqasini bo'lsa - grey
                        color: isMe
                            ? AppConstants.primaryColor
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg.messageText ?? 'Xabar topilmadi',
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // ==================== MESSAGE INPUT ====================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                // ✅ Text input field
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Xabar yozing...',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppConstants.primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // ✅ Send button
                CircleAvatar(
                  backgroundColor: AppConstants.primaryColor,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () {
                      // ✅ Xabar bo'sh bo'lmasa yuborish
                      if (messageController.text.trim().isNotEmpty) {
                        controller.sendMessage(messageController.text.trim());
                        messageController.clear();
                      } else {
                        Get.snackbar(
                          'Xato',
                          'Xabar qatorini to\'ldiring',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
