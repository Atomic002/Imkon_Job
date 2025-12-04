// lib/Screens/home/all_users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_2/config/constants.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({Key? key}) : super(key: key);

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      setState(() => isLoading = true);

      final currentUserId = supabase.auth.currentUser?.id;

      final response = await supabase
          .from('users')
          .select(
            'id, username, first_name, last_name, profile_photo_url, user_type',
          )
          .neq('id', currentUserId!)
          .order('created_at', ascending: false);

      setState(() {
        allUsers = List<Map<String, dynamic>>.from(response);
        filteredUsers = allUsers;
        isLoading = false;
      });
    } catch (e) {
      print('Load users error: $e');
      setState(() => isLoading = false);
    }
  }

  void filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = allUsers;
      } else {
        filteredUsers = allUsers.where((user) {
          final username = user['username']?.toString().toLowerCase() ?? '';
          final firstName = user['first_name']?.toString().toLowerCase() ?? '';
          final lastName = user['last_name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return username.contains(searchLower) ||
              firstName.contains(searchLower) ||
              lastName.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> startChatWithUser(
    String userId,
    String userName,
    String? avatar,
  ) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final currentUserId = supabase.auth.currentUser?.id;

      final existing = await supabase
          .from('chats')
          .select('id')
          .or(
            'and(user1_id.eq.$currentUserId,user2_id.eq.$userId),and(user1_id.eq.$userId,user2_id.eq.$currentUserId)',
          )
          .maybeSingle();

      String chatId;
      if (existing != null) {
        chatId = existing['id'];
      } else {
        final response = await supabase
            .from('chats')
            .insert({
              'user1_id': currentUserId,
              'user2_id': userId,
              'created_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        chatId = response['id'];
      }

      Get.back();

      Get.toNamed(
        '/chat_detail',
        arguments: {
          'chatId': chatId,
          'otherUserId': userId,
          'userName': userName,
          'userAvatar': avatar,
        },
      );
    } catch (e) {
      Get.back();
      print('Start chat error: $e');
      Get.snackbar(
        'Xato',
        'Chat ochishda xato',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        title: const Text(
          'Foydalanuvchilar',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: filterUsers,
              decoration: InputDecoration(
                hintText: 'Qidirish...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppConstants.primaryColor,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          filterUsers('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
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
                          Icons.person_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Foydalanuvchilar topilmadi',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final fullName =
                          '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
                              .trim();
                      final displayName = fullName.isEmpty
                          ? (user['username'] ?? 'User')
                          : fullName;

                      return InkWell(
                        onTap: () {
                          Get.toNamed(
                            '/other_profile',
                            arguments: {'userId': user['id']},
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppConstants.primaryColor
                                    .withOpacity(0.1),
                                backgroundImage:
                                    user['profile_photo_url'] != null &&
                                        user['profile_photo_url']!.isNotEmpty
                                    ? NetworkImage(user['profile_photo_url']!)
                                    : null,
                                child:
                                    user['profile_photo_url'] == null ||
                                        user['profile_photo_url']!.isEmpty
                                    ? Text(
                                        displayName[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: AppConstants.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
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
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '@${user['username']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Message button
                              IconButton(
                                onPressed: () => startChatWithUser(
                                  user['id'],
                                  displayName,
                                  user['profile_photo_url'],
                                ),
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ],
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
