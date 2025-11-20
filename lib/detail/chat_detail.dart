// lib/Screens/home/chat_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version1/Screens/home/map_picker_screen.dart';
import 'package:version1/controller/chat_controller.dart';
import 'package:version1/config/constants.dart';

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
  final String? initialMessage = Get.arguments?['initialMessage'];

  final TextEditingController messageController = TextEditingController();
  final TextEditingController editController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode messageFocusNode = FocusNode();
  late final ChatController controller;

  int _currentLineCount = 1;
  static const int _maxLines = 6;
  static const int _maxMessageLength = 300;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments as Map<String, dynamic>;
    chatId = args['chatId'];
    otherUserId = args['otherUserId'];
    userName = args['userName'];

    controller = Get.find<ChatController>();
    messageController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMessages(chatId);

      if (initialMessage != null && initialMessage!.isNotEmpty) {
        messageController.text = initialMessage!;
        _showApplicationDialog();
      }
    });

    ever(controller.currentMessages, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });
  }

  @override
  void dispose() {
    messageController.removeListener(_onTextChanged);
    messageController.dispose();
    editController.dispose();
    scrollController.dispose();
    messageFocusNode.dispose();
    controller.clearCurrentChat();
    super.dispose();
  }

  void _onTextChanged() {
    final text = messageController.text;
    final lineCount = '\n'.allMatches(text).length + 1;

    if (lineCount != _currentLineCount) {
      setState(() {
        _currentLineCount = lineCount;
      });
    }
  }

  void _showApplicationDialog() {
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.work, color: AppConstants.primaryColor),
              const SizedBox(width: 8),
              Text('application_title'.tr),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'application_message'.tr,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      messageController.text,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                messageController.clear();
                Get.back();
              },
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                Future.delayed(const Duration(milliseconds: 100), () {
                  messageFocusNode.requestFocus();
                });
              },
              child: Text('edit_application'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _sendMessage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
              ),
              child: Text('send_application'.tr),
            ),
          ],
        ),
      );
    });
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

    if (text.length > _maxMessageLength) {
      Get.snackbar(
        'error'.tr,
        'message_too_long'.tr.replaceAll('%s', '$_maxMessageLength'),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    messageController.clear();
    setState(() {
      _currentLineCount = 1;
    });

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
            Text(
              'send_location'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              title: Text(
                'current_location'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('current_location_desc'.tr),
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
              title: Text(
                'choose_from_map'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('choose_from_map_desc'.tr),
              onTap: () {
                Get.back();
                _openMapPicker();
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'cancel'.tr,
                style: const TextStyle(color: Colors.grey),
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
        Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('detecting_location'.tr),
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
          'success'.tr,
          'location_sent'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'location_not_detected'.tr,
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
        'error'.tr,
        'location_send_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _openMapPicker() async {
    try {
      final location = await controller.getCurrentLocation();
      final double initialLat = location?['latitude'] ?? 41.2995;
      final double initialLng = location?['longitude'] ?? 69.2401;

      await Navigator.push<Map<String, double>>(
        context,
        MaterialPageRoute(
          builder: (context) => MapPickerScreen(
            initialLatitude: initialLat,
            initialLongitude: initialLng,
            onLocationPicked: (lat, lng) async {
              await controller.sendMessage(
                chatId: chatId,
                latitude: lat,
                longitude: lng,
              );
              Navigator.pop(context);
              Get.snackbar(
                'success'.tr,
                'location_sent'.tr,
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
        'error'.tr,
        'map_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ✅ 3 nuqta menyu uchun chat options
  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
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
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: Text('view_profile'.tr),
              onTap: () {
                Get.back();
                Get.toNamed(
                  '/other_profile',
                  arguments: {'userId': otherUserId},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.orange),
              title: Text('search_in_chat'.tr),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'info'.tr,
                  'coming_soon'.tr,
                  backgroundColor: Colors.blue,
                  colorText: Colors.white,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off, color: Colors.grey),
              title: Text('mute_notifications'.tr),
              onTap: () {
                Get.back();
                Get.snackbar(
                  'info'.tr,
                  'coming_soon'.tr,
                  backgroundColor: Colors.blue,
                  colorText: Colors.white,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('delete_chat'.tr),
              onTap: () {
                Get.back();
                _confirmDeleteChat();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteChat() {
    Get.dialog(
      AlertDialog(
        title: Text('delete_chat'.tr),
        content: Text('delete_chat_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.deleteChat(chatId);
              Get.back(); // Chat detail ekranidan chiqish
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(message, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
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
            const SizedBox(height: 16),
            if (!(message.attachmentUrl?.startsWith('location:') ?? false)) ...[
              ListTile(
                leading: const Icon(
                  Icons.copy,
                  color: AppConstants.primaryColor,
                ),
                title: Text('copy'.tr),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: message.messageText ?? ''),
                  );
                  Get.back();
                  controller.copyMessage(message.messageText ?? '');
                },
              ),
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.blue),
                title: Text('reply'.tr),
                onTap: () {
                  Get.back();
                  controller.setReplyTo(message);
                  messageFocusNode.requestFocus();
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.orange),
                  title: Text('edit'.tr),
                  onTap: () {
                    Get.back();
                    _showEditDialog(message);
                  },
                ),
            ],
            ListTile(
              leading: const Icon(Icons.forward, color: Colors.green),
              title: Text('forward'.tr),
              onTap: () {
                Get.back();
                _showForwardDialog(message);
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('delete'.tr),
                onTap: () {
                  Get.back();
                  _confirmDelete(message.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(message) {
    editController.text = message.messageText ?? '';
    Get.dialog(
      AlertDialog(
        title: Text('edit_message'.tr),
        content: TextField(
          controller: editController,
          maxLines: null,
          maxLength: _maxMessageLength,
          decoration: InputDecoration(
            hintText: 'write_message'.tr,
            border: const OutlineInputBorder(),
            counterText: '${editController.text.length}/$_maxMessageLength',
          ),
          onChanged: (value) => setState(() {}),
        ),
        actions: [
          TextButton(
            onPressed: () {
              editController.clear();
              Get.back();
            },
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty) {
                await controller.editMessage(message.id, newText);
                editController.clear();
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }

  void _showForwardDialog(message) {
    Get.dialog(
      AlertDialog(
        title: Text('forward_to'.tr),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Obx(() {
            if (controller.chats.isEmpty) {
              return Center(child: Text('no_other_chats'.tr));
            }

            return ListView.builder(
              itemCount: controller.chats.length,
              itemBuilder: (context, index) {
                final chat = controller.chats[index];

                // ✅ Hozirgi chatni ko'rsatmaslik
                if (chat.id == chatId) return const SizedBox.shrink();

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: chat.otherUserAvatar != null
                        ? NetworkImage(chat.otherUserAvatar!)
                        : null,
                    child: chat.otherUserAvatar == null
                        ? Text(chat.otherUserName?[0] ?? '?')
                        : null,
                  ),
                  title: Text(chat.otherUserName ?? 'User'),
                  onTap: () async {
                    Get.back();
                    await controller.forwardMessage(message.id, chat.id);
                  },
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
        ],
      ),
    );
  }

  void _confirmDelete(String messageId) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_message'.tr),
        content: Text('delete_message_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.deleteMessage(messageId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  void _showReactionPicker(String messageId) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏', '👏', '🔥'];

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
            Text(
              'choose_reaction'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: emojis.map((emoji) {
                return InkWell(
                  onTap: () async {
                    await controller.toggleReaction(messageId, emoji);
                    Get.back();
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ],
        ),
      ),
    );
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
          onTap: () =>
              Get.toNamed('/other_profile', arguments: {'userId': otherUserId}),
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
          IconButton(
            onPressed: _showChatOptions, // ✅ 3 nuqta menyu
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Reply bar
          Obx(() {
            if (controller.replyingTo.value == null) {
              return const SizedBox.shrink();
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  const Icon(
                    Icons.reply,
                    size: 20,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'replying_to'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        Text(
                          controller.replyingTo.value!.messageText ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => controller.cancelReply(),
                  ),
                ],
              ),
            );
          }),

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
                        'no_messages_yet'.tr,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'send_first_message'.tr,
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _showLocationOptions,
                    icon: const Icon(
                      Icons.location_on_outlined,
                      color: AppConstants.primaryColor,
                    ),
                    tooltip: 'send_location'.tr,
                  ),
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(maxHeight: _maxLines * 24.0),
                      child: TextField(
                        controller: messageController,
                        focusNode: messageFocusNode,
                        decoration: InputDecoration(
                          hintText: 'write_message'.tr,
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
                          suffixText:
                              '${messageController.text.length}/$_maxMessageLength',
                          suffixStyle: TextStyle(
                            fontSize: 10,
                            color:
                                messageController.text.length >
                                    _maxMessageLength
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                        maxLines: null,
                        minLines: 1,
                        maxLength: _maxMessageLength,
                        buildCounter:
                            (
                              context, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        scrollPhysics: const ClampingScrollPhysics(),
                        onSubmitted: null,
                      ),
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
    final reactions = controller.messageReactions[message.id] ?? [];

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

        GestureDetector(
          onLongPress: () => _showMessageOptions(message, isMe),
          onDoubleTap: () => _showReactionPicker(message.id),
          child: Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.replyToId != null)
                  _buildReplyPreview(message, isMe),
                isLocation
                    ? _buildLocationMessage(message.attachmentUrl!, isMe)
                    : Text(
                        message.messageText ?? '',
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                if (message.isEdited)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'edited'.tr,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.grey[500],
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),
                    if (isMe)
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message.isRead
                            ? Colors.blue[300]
                            : Colors.white70,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (reactions.isNotEmpty) _buildReactions(reactions, message.id),
      ],
    );
  }

  Widget _buildReplyPreview(message, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white : AppConstants.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Text(
        'Reply message...',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: isMe ? Colors.white70 : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildReactions(List reactions, String messageId) {
    final grouped = <String, int>{};
    for (var r in reactions) {
      grouped[r.emoji] = (grouped[r.emoji] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: grouped.entries.map((entry) {
          return InkWell(
            onTap: () => controller.toggleReaction(messageId, entry.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
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
        if (await canLaunchUrl(url))
          await launchUrl(url, mode: LaunchMode.externalApplication);
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
                'location_message'.tr,
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
            'open_in_map'.tr,
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
