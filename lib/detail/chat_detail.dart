// lib/Screens/home/chat_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version1/Screens/home/map_picker_screen.dart';

// Controllers va configs
import 'package:version1/controller/chat_controller.dart';
import 'package:version1/config/constants.dart';

// Map picker - ALOHIDA import qilamiz

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({Key? key}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late final String chatId;
  late final String otherUserId;
  late final String userName;
  final String? userAvatar = Get.arguments?['userAvatar'];

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late final ChatController controller;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments as Map<String, dynamic>;
    chatId = args['chatId'];
    otherUserId = args['otherUserId'];
    userName = args['userName'];

    controller = Get.put(ChatController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMessages(chatId);
    });

    ever(controller.currentMessages, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    controller.clearCurrentChat();
    super.dispose();
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    await controller.sendMessage(chatId: chatId, messageText: text);
  }

  void _showLocationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lokatsiya yuborish',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
              title: const Text(
                'Hozirgi joylashuvim',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('GPS orqali aniq manzilni yuborish'),
              onTap: () async {
                Get.back();
                await _sendCurrentLocation();
              },
            ),
            const Divider(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.map_outlined, color: Colors.green),
              ),
              title: const Text(
                'Xaritadan tanlash',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Istalgan joyni xaritadan belgilash'),
              onTap: () {
                Get.back();
                _openMapPicker();
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Bekor qilish',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendCurrentLocation() async {
    try {
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Lokatsiya aniqlanmoqda...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final location = await controller.getCurrentLocation();
      Get.back();

      if (location != null) {
        await controller.sendMessage(
          chatId: chatId,
          latitude: location['latitude'],
          longitude: location['longitude'],
        );

        Get.snackbar(
          'Muvaffaqiyatli',
          'Lokatsiya yuborildi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Xato',
          'Lokatsiyani aniqlab bo\'lmadi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          icon: const Icon(Icons.warning, color: Colors.white),
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Send location error: $e');
      Get.snackbar(
        'Xato',
        'Lokatsiya yuborishda xato',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ✅ ASOSIY TUZATISH - Bu yerda xato bor edi!
  Future<void> _openMapPicker() async {
    try {
      // 1. Lokatsiyani olamiz
      final location = await controller.getCurrentLocation();

      final double initialLat = location?['latitude'] ?? 41.2995;
      final double initialLng = location?['longitude'] ?? 69.2401;

      // 2. Map picker screen ochamiz - TO'G'RI USUL
      final result = await Navigator.push<Map<String, double>>(
        context,
        MaterialPageRoute(
          builder: (context) => MapPickerScreen(
            initialLatitude: initialLat,
            initialLongitude: initialLng,
            onLocationPicked: (lat, lng) async {
              // Lokatsiyani yuboramiz
              await controller.sendMessage(
                chatId: chatId,
                latitude: lat,
                longitude: lng,
              );

              // Navigator bilan orqaga qaytamiz
              Navigator.pop(context);

              // Success message
              Get.snackbar(
                'Muvaffaqiyatli',
                'Lokatsiya yuborildi',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ),
      );
    } catch (e) {
      print('Map picker error: $e');
      Get.snackbar(
        'Xato',
        'Xaritani ochishda xato',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            Get.toNamed('/other_profile', arguments: {'userId': otherUserId});
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                backgroundImage: userAvatar != null && userAvatar!.isNotEmpty
                    ? NetworkImage(userAvatar!)
                    : null,
                child: userAvatar == null || userAvatar!.isEmpty
                    ? Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.currentMessages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.currentMessages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hozircha xabarlar yo\'q',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Birinchi xabarni yuboring!',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: controller.currentMessages.length,
                itemBuilder: (context, index) {
                  final message = controller.currentMessages[index];
                  final isMe =
                      message.senderId ==
                      controller.supabase.auth.currentUser?.id;
                  final showTime =
                      index == 0 ||
                      controller.currentMessages[index - 1].createdAt
                              .difference(message.createdAt)
                              .inMinutes
                              .abs() >
                          5;

                  return _buildMessageBubble(message, isMe, showTime);
                },
              );
            }),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: _showLocationOptions,
                    icon: const Icon(
                      Icons.location_on_outlined,
                      color: AppConstants.primaryColor,
                    ),
                    tooltip: 'Lokatsiya yuborish',
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Xabar yozing...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => controller.isSending.value
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            onPressed: _sendMessage,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppConstants.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
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

  Widget _buildMessageBubble(message, bool isMe, bool showTime) {
    final isLocation = message.attachmentUrl?.startsWith('location:') ?? false;

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (showTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? AppConstants.primaryColor : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: isLocation
              ? _buildLocationMessage(message.attachmentUrl!, isMe)
              : Text(
                  message.messageText ?? '',
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLocationMessage(String attachmentUrl, bool isMe) {
    final parts = attachmentUrl.replaceFirst('location:', '').split(',');
    final latitude = double.parse(parts[0]);
    final longitude = double.parse(parts[1]);

    return InkWell(
      onTap: () async {
        final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: isMe ? Colors.white : AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Lokatsiya',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Xaritada ko\'rish uchun bosing',
            style: TextStyle(
              color: isMe ? Colors.white70 : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
