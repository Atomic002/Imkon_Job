import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';

class OtherUserProfileScreen extends StatefulWidget {
  const OtherUserProfileScreen({super.key});

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late String userId;

  Map<String, dynamic>? userInfo;
  List<Map<String, dynamic>> userPosts = [];
  bool isLoading = true;
  bool isFollowing = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    userId = Get.arguments as String;
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => isLoading = true);

      // Load user info
      final userResponse = await supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      // Load user posts
      final postsResponse = await supabase
          .from('posts')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Check if following
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        final followResponse = await supabase
            .from('follows')
            .select('id')
            .eq('follower_id', currentUserId)
            .eq('following_id', userId)
            .maybeSingle();

        isFollowing = followResponse != null;
      }

      setState(() {
        userInfo = userResponse;
        userPosts = List<Map<String, dynamic>>.from(postsResponse);
        isLoading = false;
      });
    } catch (e) {
      print('Load user data error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      if (isFollowing) {
        // Unfollow
        await supabase
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', userId);
      } else {
        // Follow
        await supabase.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': userId,
        });
      }

      setState(() => isFollowing = !isFollowing);
    } catch (e) {
      print('Toggle follow error: $e');
    }
  }

  Future<void> _startChat() async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Check if chat exists
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
        // Create new chat
        final response = await supabase
            .from('chats')
            .insert({'user1_id': currentUserId, 'user2_id': userId})
            .select()
            .single();
        chatId = response['id'];
      }

      Get.toNamed(
        '/chat_detail',
        arguments: {
          'chatId': chatId,
          'otherUserId': userId,
          'userName': userInfo?['full_name'] ?? 'User',
        },
      );
    } catch (e) {
      print('Start chat error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final fullName = userInfo?['full_name'] ?? 'User';
    final username = userInfo?['username'] ?? '';
    final bio = userInfo?['bio'] ?? '';
    final avatarUrl = userInfo?['avatar_url'];
    final postsCount = userPosts.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        title: Text(
          username.isNotEmpty ? '@$username' : fullName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // More options
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppConstants.primaryColor.withOpacity(
                        0.1,
                      ),
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              fullName[0].toUpperCase(),
                              style: TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 20),

                    // Stats
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(postsCount.toString(), 'Postlar'),
                          _buildStatColumn(
                            userInfo?['followers_count']?.toString() ?? '0',
                            'Followers',
                          ),
                          _buildStatColumn(
                            userInfo?['following_count']?.toString() ?? '0',
                            'Following',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name and Bio
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          bio,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing
                              ? Colors.grey[200]
                              : AppConstants.primaryColor,
                          foregroundColor: isFollowing
                              ? Colors.black
                              : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: _startChat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Xabar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.person_add_outlined, size: 20),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppConstants.textPrimary,
              labelColor: AppConstants.textPrimary,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on)),
                Tab(icon: Icon(Icons.bookmark_border)),
              ],
            ),
          ),

          // Posts Grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPostsGrid(), _buildSavedGrid()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildPostsGrid() {
    if (userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Hozircha post yo\'q',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: userPosts.length,
      itemBuilder: (context, index) {
        final post = userPosts[index];
        return _buildPostItem(post);
      },
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post) {
    final imageUrl = post['image_url'];

    return GestureDetector(
      onTap: () {
        Get.toNamed('/post_detail', arguments: post['id']);
      },
      child: Container(
        color: Colors.grey[200],
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[400],
                      size: 40,
                    ),
                  );
                },
              )
            : Center(
                child: Icon(
                  Icons.image_outlined,
                  color: Colors.grey[400],
                  size: 40,
                ),
              ),
      ),
    );
  }

  Widget _buildSavedGrid() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Saqlangan postlar',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
