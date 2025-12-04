// lib/Screens/home/chat_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_2/config/constants.dart';
import 'package:flutter_application_2/controller/chat_controller.dart';
import 'package:flutter_application_2/Screens/home/map_picker_screen.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final ScrollController scrollController = ScrollController();
  final FocusNode messageFocusNode = FocusNode();
  late final ChatController controller;
  late final String currentUserId;

  static const int _maxMessageLength = 300;

  final List<String> emojis = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '🙏',
    '👏',
    '🔥',
    '🎉',
    '😍',
    '🤔',
    '💯',
  ];

  @override
  void initState() {
    super.initState();

    final args = Get.arguments as Map<String, dynamic>;
    chatId = args['chatId'];
    otherUserId = args['otherUserId'];
    userName = args['userName'];

    controller = Get.find<ChatController>();
    currentUserId = controller.supabase.auth.currentUser!.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMessages(chatId);

      if (initialMessage != null && initialMessage!.isNotEmpty) {
        messageController.text = initialMessage!;
        _showApplicationDialog();
      }
    });

    ever(controller.currentMessages, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    messageFocusNode.dispose();
    controller.clearCurrentChat();
    super.dispose();
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
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

  Future<void> _sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    if (text.length > _maxMessageLength) {
      Get.snackbar(
        'error'.tr,
        'message_too_long'.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    messageController.clear();
    await controller.sendMessage(chatId: chatId, messageText: text);
    _scrollToBottom();
  }

  Future<void> _showLocationOptions() async {
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

            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.map, color: Colors.green),
              ),
              title: Text('choose_from_map'.tr),
              subtitle: Text('choose_from_map_desc'.tr),
              onTap: () {
                Get.back();
                _openMapPicker();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _openMapPicker() async {
    try {
      final result = await Get.to(() => const MapPickerScreen());

      if (result != null && result is Map<String, double>) {
        final latitude = result['latitude'];
        final longitude = result['longitude'];

        if (latitude != null && longitude != null) {
          await controller.sendMessage(
            chatId: chatId,
            messageText: '📍 Location',
            latitude: latitude,
            longitude: longitude,
          );
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Map picker error: $e');
      Get.snackbar(
        'error'.tr,
        'location_send_error'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showReactionPicker(String messageId) {
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () async {
                    Get.back();
                    await controller.toggleReaction(messageId, emojis[index]);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ],
        ),
      ),
    );
  }

  void _showReactionDetails(String messageId, String emoji, List reactions) {
    final usersWithThisEmoji = reactions
        .where((r) => r.emoji == emoji)
        .toList();

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
            const SizedBox(height: 16),
            Text(
              '$emoji • ${usersWithThisEmoji.length}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Divider(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: usersWithThisEmoji.length,
                itemBuilder: (context, index) {
                  final reaction = usersWithThisEmoji[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppConstants.primaryColor.withOpacity(
                        0.1,
                      ),
                      child: Text(
                        (reaction.userName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(reaction.userName ?? 'User'),
                    subtitle: Text(
                      DateFormat('HH:mm • dd/MM').format(reaction.createdAt),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Get.back(), child: Text('close'.tr)),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(dynamic message, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (!(message.attachmentUrl?.startsWith('location:') ?? false)) ...[
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.green),
                title: Text('copy'.tr),
                onTap: () {
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
              leading: const Icon(Icons.favorite, color: Colors.pink),
              title: Text('add_reaction'.tr),
              onTap: () {
                Get.back();
                _showReactionPicker(message.id);
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(dynamic message) {
    final editController = TextEditingController(
      text: message.messageText ?? '',
    );
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
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              editController.dispose();
              Get.back();
            },
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty) {
                await controller.editMessage(message.id, newText);
                editController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildReplyBar(),
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppConstants.textPrimary,
      elevation: 0,
      titleSpacing: 0,
      title: InkWell(
        onTap: () =>
            Get.toNamed('/other_profile', arguments: {'userId': otherUserId}),
        child: Row(
          children: [
            Stack(
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
                Obx(() {
                  if (!controller.isUserOnline(otherUserId))
                    return const SizedBox.shrink();
                  return Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  );
                }),
              ],
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
                  Obx(() {
                    if (!controller.isUserOnline(otherUserId))
                      return const SizedBox.shrink();
                    return Text(
                      'online'.tr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBar() {
    return Obx(() {
      if (controller.replyingTo.value == null) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.grey[200],
        child: Row(
          children: [
            const Icon(Icons.reply, size: 20, color: AppConstants.primaryColor),
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
    });
  }

  Widget _buildMessageList() {
    return Obx(() {
      if (controller.isLoading.value && controller.currentMessages.isEmpty) {
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
          final isMe = message.senderId == currentUserId;

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
    });
  }

  Widget _buildMessageBubble(dynamic message, bool isMe, bool showTime) {
    final reactions = controller.messageReactions[message.id] ?? [];
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
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            ),
          ),
        ),
        if (reactions.isNotEmpty) _buildReactions(reactions, message.id),
      ],
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
            onTap: () => _showReactionDetails(messageId, entry.key, reactions),
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
                  Text(entry.key, style: const TextStyle(fontSize: 14)),
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

  Widget _buildInputBar() {
    return Container(
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
            ),
            Expanded(
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
    );
  }
}
