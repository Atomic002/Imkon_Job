import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controller/chat_controller.dart';
import '../../config/constants.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({Key? key}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late ChatController controller;
  final TextEditingController _messageController = TextEditingController();
  final supabase = Supabase.instance.client;
  late String chatId;
  late String otherUserId;
  Map<String, dynamic>? otherUserData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Get arguments properly
    final args = Get.arguments as Map<String, dynamic>;
    chatId = args['chatId'] as String;
    otherUserId = args['otherUserId'] as String;

    print(
      'ChatDetailScreen initialized with chatId: $chatId, otherUserId: $otherUserId',
    );

    controller = Get.find<ChatController>();
    controller.currentChatId.value = chatId;

    _loadChatDetails();
  }

  Future<void> _loadChatDetails() async {
    try {
      setState(() => isLoading = true);

      // Boshqa user ma'lumotini olish
      final userData = await supabase
          .from('users')
          .select()
          .eq('id', otherUserId)
          .single();

      setState(() {
        otherUserData = userData;
        isLoading = false;
      });

      // Xabarlarni yuklash
      await controller.loadMessages(chatId);
      await controller.markMessagesAsRead(chatId);
    } catch (e) {
      print('Error loading chat details: $e');
      setState(() => isLoading = false);
      Get.snackbar(
        'Xato',
        'Chat ma\'lumotlari yuklanmadi: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hozir';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} daqiqa oldin';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} soat oldin';
    } else if (difference.inDays == 1) {
      return 'Kecha';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} kun oldin';
    } else {
      return DateFormat('dd.MM.yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firstName = otherUserData?['first_name'] ?? '';
    final lastName = otherUserData?['last_name'] ?? '';
    final username = otherUserData?['username'] ?? 'User';
    final fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : username;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Get.toNamed('/other_user_profile', arguments: otherUserId);
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                backgroundImage: otherUserData?['profile_photo_url'] != null
                    ? NetworkImage(otherUserData!['profile_photo_url'])
                    : null,
                child: otherUserData?['profile_photo_url'] == null
                    ? Text(
                        fullName[0].toUpperCase(),
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (otherUserData?['user_type'] != null)
                      Text(
                        otherUserData!['user_type'] == 'job_seeker'
                            ? 'Ish qidiryapti'
                            : otherUserData!['user_type'] == 'employer'
                            ? 'Ish beruvchi'
                            : '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

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
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isCurrentUser =
                      message.senderId == supabase.auth.currentUser?.id;

                  return Align(
                    alignment: isCurrentUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentUser
                            ? AppConstants.primaryColor
                            : Colors.grey[200],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isCurrentUser
                              ? const Radius.circular(16)
                              : Radius.zero,
                          bottomRight: isCurrentUser
                              ? Radius.zero
                              : const Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            message.messageText ?? '',
                            style: TextStyle(
                              color: isCurrentUser
                                  ? Colors.white
                                  : AppConstants.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(message.createdAt),
                            style: TextStyle(
                              color: isCurrentUser
                                  ? Colors.white70
                                  : Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Xabar yozing...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () async {
                        final text = _messageController.text.trim();
                        if (text.isNotEmpty) {
                          _messageController.clear();
                          await controller.sendMessage(text);
                        }
                      },
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
