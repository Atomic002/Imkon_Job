import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controller/chat_controller.dart';
import '../../config/constants.dart';

// ==================== CHAT SCREEN ====================
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatController controller;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ChatController());
  }

  void _showUsersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UsersListModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'messages'.tr,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Hozircha suhbat yo\'q',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yangi suhbat boshlash uchun + tugmasini bosing',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.chats.length,
          padding: const EdgeInsets.only(top: 4),
          itemBuilder: (context, index) {
            final chat = controller.chats[index];
            return _buildChatItem(context, chat);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUsersModal,
        backgroundColor: AppConstants.primaryColor,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, dynamic chat) {
    final currentUserId = supabase.auth.currentUser?.id;
    final otherUserId = chat.user1Id == currentUserId
        ? chat.user2Id
        : chat.user1Id;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getOtherUserInfo(otherUserId),
      builder: (context, snapshot) {
        // first_name va last_name dan to'liq ism yasash
        final firstName = snapshot.data?['first_name'] ?? '';
        final lastName = snapshot.data?['last_name'] ?? '';
        final username = snapshot.data?['username'] ?? 'User';

        // To'liq ism yoki username
        final userName = (firstName.isNotEmpty || lastName.isNotEmpty)
            ? '$firstName $lastName'.trim()
            : username;

        final userAvatar = snapshot.data?['profile_photo_url'];

        return Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {
              try {
                print(
                  'Navigating to chat_detail with chatId: ${chat.id}, otherUserId: $otherUserId',
                );
                Get.toNamed(
                  '/chat_detail',
                  arguments: {
                    'chatId': chat.id,
                    'otherUserId': otherUserId,
                    'userName': userName,
                  },
                );
              } catch (e) {
                print('Navigation error: $e');
                Get.snackbar(
                  'Xato',
                  'Chatni ochishda xatolik: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                    backgroundImage: userAvatar != null && userAvatar.isNotEmpty
                        ? NetworkImage(userAvatar)
                        : null,
                    child: userAvatar == null || userAvatar.isEmpty
                        ? Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Chat info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getTimeFromNow(chat.lastMessageTime),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chat.lastMessage ?? 'Xabar yo\'q',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getOtherUserInfo(String userId) async {
    try {
      final response = await supabase
          .from('users')
          .select('first_name, last_name, username, profile_photo_url')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }

  String _getTimeFromNow(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hozir';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s';
    } else if (difference.inDays == 1) {
      return 'Kecha';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}.${dateTime.month}';
    }
  }
}

// ==================== USERS LIST MODAL ====================
class UsersListModal extends StatefulWidget {
  const UsersListModal({super.key});

  @override
  State<UsersListModal> createState() => _UsersListModalState();
}

class _UsersListModalState extends State<UsersListModal> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        print('Current user ID is null');
        setState(() => isLoading = false);
        return;
      }

      final response = await supabase
          .from('users')
          .select('id, first_name, last_name, profile_photo_url, username')
          .neq('id', currentUserId);

      print('Loaded ${response.length} users');

      setState(() {
        allUsers = List<Map<String, dynamic>>.from(response);
        filteredUsers = allUsers;
        isLoading = false;
      });
    } catch (e) {
      print('Load users error: $e');
      setState(() => isLoading = false);
      if (mounted) {
        Get.snackbar(
          'Xato',
          'Foydalanuvchilarni yuklashda xatolik: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = allUsers;
      } else {
        filteredUsers = allUsers.where((user) {
          final firstName = user['first_name']?.toString().toLowerCase() ?? '';
          final lastName = user['last_name']?.toString().toLowerCase() ?? '';
          final username = user['username']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return firstName.contains(searchLower) ||
              lastName.contains(searchLower) ||
              username.contains(searchLower);
        }).toList();
      }
    });
  }

  void _startChatWithUser(String userId, String userName) async {
    try {
      print('Starting chat with user: $userId, name: $userName');

      // Loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final controller = Get.find<ChatController>();
      final chatId = await controller.createOrGetChat(userId);

      // Close loading dialog
      Get.back();

      if (chatId != null) {
        print('Chat created/retrieved: $chatId');
        Get.back(); // Close users modal

        await Get.toNamed(
          '/chat_detail',
          arguments: {
            'chatId': chatId,
            'otherUserId': userId,
            'userName': userName,
          },
        );
      } else {
        print('Failed to create/get chat');
        Get.snackbar(
          'Xato',
          'Chatni ochishda xatolik yuz berdi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error starting chat: $e');
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar(
        'Xato',
        'Chatni ochishda xatolik: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _navigateToProfile(String userId) {
    try {
      print('Navigating to profile: $userId');
      Get.back(); // Close modal
      Get.toNamed('/other_user_profile', arguments: userId);
    } catch (e) {
      print('Navigation error: $e');
      Get.snackbar(
        'Xato',
        'Profilni ochishda xatolik: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Foydalanuvchilar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search bar
                TextField(
                  controller: searchController,
                  onChanged: _filterUsers,
                  decoration: InputDecoration(
                    hintText: 'Qidirish...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),
          ),

          // Users list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      'Foydalanuvchi topilmadi',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _buildUserItem(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final username = user['username'] ?? 'User';

    // To'liq ism yoki username
    final userName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : username;

    final userAvatar = user['profile_photo_url'];
    final userId = user['id'];

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _navigateToProfile(userId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                backgroundImage: userAvatar != null && userAvatar.isNotEmpty
                    ? NetworkImage(userAvatar)
                    : null,
                child: userAvatar == null || userAvatar.isEmpty
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // User info
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
                    ),
                    Text(
                      '@$username',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Message button
              InkWell(
                onTap: () => _startChatWithUser(userId, userName),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.message_outlined,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
