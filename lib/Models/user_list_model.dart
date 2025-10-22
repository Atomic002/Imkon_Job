import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';

class UsersListModal extends StatefulWidget {
  const UsersListModal({Key? key}) : super(key: key);

  @override
  State<UsersListModal> createState() => _UsersListModalState();
}

class _UsersListModalState extends State<UsersListModal> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => isLoading = true);

      final currentUserId = supabase.auth.currentUser?.id;

      final response = await supabase
          .from('users')
          .select()
          .neq('id', currentUserId!)
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        allUsers = List<Map<String, dynamic>>.from(response);
        filteredUsers = allUsers;
      });
    } catch (e) {
      print('Error loading users: $e');
      Get.snackbar('Xato', 'Foydalanuvchilarni yuklab bo\'lmadi');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredUsers = allUsers;
      } else {
        filteredUsers = allUsers.where((user) {
          final firstName = (user['first_name'] ?? '').toString().toLowerCase();
          final lastName = (user['last_name'] ?? '').toString().toLowerCase();
          final username = (user['username'] ?? '').toString().toLowerCase();
          final bio = (user['bio'] ?? '').toString().toLowerCase();

          return firstName.contains(query) ||
              lastName.contains(query) ||
              username.contains(query) ||
              bio.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _createChat(String otherUserId) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        Get.snackbar('Xato', 'Avval login qiling');
        return;
      }

      if (currentUserId == otherUserId) {
        Get.snackbar('Xato', 'O\'z o\'zingiz bilan chat yasab olmaysiz');
        return;
      }

      // Oldindan chat bor-yo'qligini tekshirish
      final existing = await supabase
          .from('chats')
          .select('id')
          .or(
            'and(user1_id.eq.$currentUserId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$currentUserId)',
          )
          .maybeSingle();

      late String chatId;

      if (existing != null) {
        chatId = existing['id'];
      } else {
        final newChat = await supabase
            .from('chats')
            .insert({'user1_id': currentUserId, 'user2_id': otherUserId})
            .select()
            .single();
        chatId = newChat['id'];
      }

      Get.back();
      Get.toNamed('/chat_detail', arguments: chatId);
    } catch (e) {
      print('Error creating chat: $e');
      Get.snackbar('Xato', 'Chat yaratishda xatolik yuz berdi: $e');
    }
  }

  void _openUserProfile(String userId) {
    Get.toNamed('/profile', arguments: userId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Foydalanuvchilar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Foydalanuvchi qidiring...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppConstants.primaryColor,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _filterUsers();
                        },
                        child: const Icon(Icons.close, color: Colors.grey),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppConstants.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Users list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Foydalanuvchi topilmadi'
                              : 'Qidiruv bo\'yicha foydalanuvchi topilmadi',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final userName = user['first_name'] != null
                          ? '${user['first_name']} ${user['last_name'] ?? ''}'
                          : user['username'] ?? 'Foydalanuvchi';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openUserProfile(user['id']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                GestureDetector(
                                  onTap: () => _openUserProfile(user['id']),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppConstants.primaryColor
                                        .withOpacity(0.15),
                                    backgroundImage:
                                        user['profile_photo_url'] != null
                                        ? NetworkImage(
                                            user['profile_photo_url'],
                                          )
                                        : null,
                                    child: user['profile_photo_url'] == null
                                        ? const Icon(
                                            Icons.person,
                                            color: AppConstants.primaryColor,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // User info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user['user_type'] == 'job_seeker'
                                            ? 'Ish qidiruvchi'
                                            : 'Ish beruvchi',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppConstants.textSecondary,
                                        ),
                                      ),
                                      if (user['bio'] != null &&
                                          user['bio']!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            user['bio'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF8E8E93),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Message icon button
                                GestureDetector(
                                  onTap: () => _createChat(user['id']),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppConstants.primaryColor
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.message_outlined,
                                      color: AppConstants.primaryColor,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
