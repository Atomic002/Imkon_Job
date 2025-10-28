import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version1/Models/job_post.dart';
import 'package:version1/config/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String userId;

  const OtherUserProfilePage({Key? key, required this.userId})
    : super(key: key);

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? userInfo;
  List<JobPost> activePosts = [];
  List<JobPost> completedPosts = [];
  bool isLoading = true;

  late TabController _tabController;

  // Stats
  int totalViews = 0;
  int totalLikes = 0;
  int totalShares = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => isLoading = true);

      // ✅ Load FULL user info with ALL fields from database
      final userResponse = await supabase
          .from('users')
          .select('''
            id,
            username,
            email,
            first_name,
            last_name,
            bio,
            profile_photo_url,
            user_type,
            is_email_verified,
            location,
            rating,
            created_at,
            updated_at,
            is_active,
            phone_number
          ''')
          .eq('id', widget.userId)
          .single();

      // Load user posts
      final postsResponse = await supabase
          .from('posts')
          .select('''
            id,
            user_id,
            title,
            description,
            category_id,
            sub_category_id,
            location,
            status,
            salary_type,
            salary_min,
            salary_max,
            requirements_main,
            requirements_basic,
            views_count,
            likes_count,
            shares_count,
            duration_days,
            is_active,
            created_at,
            post_type,
            skills,
            experience,
            users!inner(first_name, last_name, profile_photo_url, username),
            post_images(image_url)
          ''')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      // Parse posts
      final List<JobPost> allPosts = [];
      for (var item in postsResponse) {
        try {
          final post = JobPost.fromJson(item);
          allPosts.add(post);
        } catch (e) {
          print('Parse post error: $e');
        }
      }

      // Split into active and completed
      final active = allPosts
          .where((p) => p.status == 'approved' && p.isActive)
          .toList();
      final completed = allPosts
          .where((p) => p.status != 'approved' || !p.isActive)
          .toList();

      // Calculate stats
      int views = 0;
      int likes = 0;
      int shares = 0;
      for (var post in allPosts) {
        views += post.views;
        likes += post.likes;
        shares += post.sharesCount ?? 0;
      }

      setState(() {
        userInfo = userResponse;
        activePosts = active;
        completedPosts = completed;
        totalViews = views;
        totalLikes = likes;
        totalShares = shares;
        isLoading = false;
      });
    } catch (e) {
      print('Load user data error: $e');
      setState(() => isLoading = false);

      Get.snackbar(
        'Xato',
        'Foydalanuvchi ma\'lumotlarini yuklashda xato',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // ✅ CALL USER - Open phone dialer
  // ✅ IMPROVED CALL USER METHOD
  Future<void> _callUser() async {
    try {
      final phoneNumber = userInfo?['phone_number'];

      if (phoneNumber == null || phoneNumber.isEmpty) {
        Get.snackbar(
          'Ma\'lumot yo\'q',
          'Bu foydalanuvchining telefon raqami mavjud emas',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          icon: const Icon(Icons.phone_disabled, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Telefon raqamini tozalash (faqat raqamlar qoldirish)
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Tel URI yaratish
      final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);

      print('Calling: $cleanPhone'); // Debug uchun

      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Xato',
          'Qo\'ng\'iroq qilish imkoni yo\'q. Telefon ilovasi ochilmadi.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('Call error: $e');
      Get.snackbar(
        'Xato',
        'Qo\'ng\'iroq qilishda xato yuz berdi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // other_user_profile_page.dart da _startChat metodini to'g'rilang:

  Future<void> _startChat() async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        Get.snackbar(
          'Xato',
          'Iltimos, tizimga kiring',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      if (currentUserId == widget.userId) {
        Get.snackbar(
          'Xato',
          'O\'zingiz bilan chat qila olmaysiz',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final existing = await supabase
          .from('chats')
          .select('id')
          .or(
            'and(user1_id.eq.$currentUserId,user2_id.eq.${widget.userId}),and(user1_id.eq.${widget.userId},user2_id.eq.$currentUserId)',
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
              'user2_id': widget.userId,
              'created_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        chatId = response['id'];
      }

      Get.back(); // Close loading dialog

      // ✅ TO'G'RI NAVIGATSIYA
      Get.toNamed(
        '/chat_detail',
        arguments: {
          'chatId': chatId,
          'otherUserId': widget.userId,
          'userName': _getUserFullName(),
          'userAvatar': userInfo?['profile_photo_url'],
        },
      );
    } catch (e) {
      Get.back();
      print('Start chat error: $e');
      Get.snackbar(
        'Xato',
        'Chat ochishda xato: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  String _getUserFullName() {
    if (userInfo == null) return 'User';
    final firstName = userInfo!['first_name'] ?? '';
    final lastName = userInfo!['last_name'] ?? '';
    return '$firstName $lastName'.trim().isEmpty
        ? (userInfo!['username'] ?? 'User')
        : '$firstName $lastName';
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Noma\'lum';
    try {
      DateTime dt = DateTime.parse(date.toString());
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (e) {
      return 'Noma\'lum';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppConstants.textPrimary,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (userInfo == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppConstants.textPrimary,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Foydalanuvchi topilmadi',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final fullName = _getUserFullName();
    final username = userInfo!['username'] ?? '';
    final bio = userInfo!['bio'] ?? '';
    final avatarUrl = userInfo!['profile_photo_url'];
    final totalPosts = activePosts.length + completedPosts.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
            onPressed: _showMoreOptions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppConstants.primaryColor.withOpacity(
                          0.1,
                        ),
                        backgroundImage:
                            avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Text(
                                fullName.isNotEmpty
                                    ? fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
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
                            _buildStatColumn(totalPosts.toString(), 'Postlar'),
                            _buildStatColumn(
                              totalViews.toString(),
                              'Ko\'rishlar',
                            ),
                            _buildStatColumn(totalLikes.toString(), 'Likelar'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Name
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  if (username.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '@$username',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                  ],

                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        bio,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ✅ FULL USER INFO CARD
            _buildFullUserInfoCard(),

            const SizedBox(height: 12),

            // Stats Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatChip(
                    Icons.grid_on,
                    '${activePosts.length}',
                    'Aktiv',
                    Colors.green,
                  ),
                  _buildStatChip(
                    Icons.check_circle_outline,
                    '${completedPosts.length}',
                    'Tugagan',
                    Colors.grey,
                  ),
                  _buildStatChip(
                    Icons.share_outlined,
                    totalShares.toString(),
                    'Ulashish',
                    Colors.blue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppConstants.primaryColor,
                labelColor: AppConstants.primaryColor,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: 'Aktiv (${activePosts.length})'),
                  Tab(text: 'Tugagan (${completedPosts.length})'),
                ],
              ),
            ),

            // Posts
            SizedBox(
              height: 500,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsList(activePosts, 'Hozircha aktiv post yo\'q'),
                  _buildPostsList(
                    completedPosts,
                    'Hozircha tugagan post yo\'q',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FULL USER INFO CARD
  Widget _buildFullUserInfoCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ma\'lumotlar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildInfoRow(
            Icons.alternate_email,
            'Username',
            '@${userInfo!['username'] ?? 'N/A'}',
          ),
          const Divider(height: 24),

          _buildInfoRow(
            Icons.phone_outlined,
            'Telefon',
            userInfo!['phone_number'] ?? 'Kiritilmagan',
          ),
          const Divider(height: 24),

          _buildInfoRow(
            Icons.location_on_outlined,
            'Manzil',
            userInfo!['location'] ?? 'Kiritilmagan',
          ),
          const Divider(height: 24),

          _buildInfoRow(
            Icons.badge_outlined,
            'Akkount turi',
            userInfo!['user_type'] == 'job_seeker'
                ? 'Ish qidiruvchi'
                : 'Ish beruvchi',
          ),
          const Divider(height: 24),

          _buildInfoRow(
            Icons.star_outlined,
            'Reyting',
            '${userInfo!['rating'] ?? 0.0} ⭐',
          ),
          const Divider(height: 24),

          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Ro\'yxatdan o\'tdi',
            _formatDate(userInfo!['created_at']),
          ),
          const Divider(height: 24),

          _buildInfoRow(
            Icons.circle,
            'Holat',
            userInfo!['is_active'] == true ? 'Aktiv' : 'Nofaol',
            trailing: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: userInfo!['is_active'] == true
                    ? Colors.green
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppConstants.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppConstants.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildActionButtons() {
    final currentUserId = supabase.auth.currentUser?.id;
    final isOwnProfile = currentUserId == widget.userId;

    if (isOwnProfile) {
      return ElevatedButton(
        onPressed: () => Get.back(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Bu sizning profilingiz',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    return Row(
      children: [
        // ✅ CALL BUTTON
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _callUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.phone, size: 20),
            label: const Text(
              'Qo\'ng\'iroq',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // MESSAGE BUTTON
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _startChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: const Text(
              'Xabar',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostsList(List<JobPost> posts, String emptyMessage) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) => _buildPostCard(posts[index]),
    );
  }

  Widget _buildPostCard(JobPost post) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.hasImages)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  post.imageUrls!.first,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.getSalaryRange(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPostStat(Icons.visibility, post.views.toString()),
                      const SizedBox(width: 16),
                      _buildPostStat(Icons.favorite, post.likes.toString()),
                      const SizedBox(width: 16),
                      _buildPostStat(
                        Icons.share,
                        (post.sharesCount ?? 0).toString(),
                      ),
                      const Spacer(),
                      Text(
                        post.getFormattedDate(),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Profilni ulashish'),
              onTap: () => Get.back(),
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Shikoyat qilish'),
              onTap: () => Get.back(),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block qilish'),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
