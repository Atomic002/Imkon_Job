import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version1/Screens/home/user_profile_screen.dart';
import '../Models/job_post.dart';
import '../config/constants.dart';

class FilterPostCard extends StatefulWidget {
  final JobPost post;
  final VoidCallback onLike;
  final bool isLiked;

  const FilterPostCard({
    Key? key,
    required this.post,
    required this.onLike,
    required this.isLiked,
  }) : super(key: key);

  @override
  State<FilterPostCard> createState() => _FilterPostCardState();
}

class _FilterPostCardState extends State<FilterPostCard> {
  int _currentImageIndex = 0;
  bool _isViewRecorded = false;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordView();
    });
  }

  Future<void> _recordView() async {
    if (_isViewRecorded) return;

    try {
      final userId = _supabase.auth.currentUser?.id;

      String? deviceId;
      if (userId == null) {
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      }

      List<dynamic> existingViews;

      if (userId != null) {
        existingViews = await _supabase
            .from('post_views')
            .select()
            .eq('post_id', widget.post.id)
            .eq('user_id', userId)
            .limit(1);
      } else {
        existingViews = await _supabase
            .from('post_views')
            .select()
            .eq('post_id', widget.post.id)
            .eq('device_id', deviceId!)
            .limit(1);
      }

      if (existingViews.isNotEmpty) {
        if (mounted) {
          setState(() => _isViewRecorded = true);
        }
        return;
      }

      try {
        await _supabase.from('post_views').insert({
          'post_id': widget.post.id,
          'user_id': userId,
          'device_id': deviceId,
          'viewed_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          setState(() {
            _isViewRecorded = true;
            widget.post.views++;
          });
        }
      } catch (insertError) {
        if (insertError.toString().contains('23505') ||
            insertError.toString().contains('duplicate key')) {
          if (mounted) {
            setState(() => _isViewRecorded = true);
          }
        } else {
          rethrow;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isViewRecorded = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.post.hasImages;

    return GestureDetector(
      onTap: () => _showPostDetailsBottomSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            if (hasImages) _buildImageCarousel() else _buildPlaceholder(),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostTypeBadge(),
                  const SizedBox(height: 12),
                  _buildTitleSection(),
                  if (widget.post.description.isNotEmpty)
                    _buildDescriptionSection(),
                  const SizedBox(height: 12),
                  _buildLocationSection(),
                  const SizedBox(height: 12),
                  _buildCategorySection(),
                  const SizedBox(height: 12),
                  _buildSalarySection(),
                  const SizedBox(height: 16),
                  _buildStatsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTypeBadge() {
    final postType = widget.post.postType;
    if (postType == null) return const SizedBox.shrink();

    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (postType) {
      case 'employee_needed':
        badgeColor = Colors.blue;
        badgeIcon = Icons.person_add_alt_1;
        badgeText = 'Hodim kerak';
        break;
      case 'job_needed':
        badgeColor = Colors.green;
        badgeIcon = Icons.work_outline;
        badgeText = 'Ish kerak';
        break;
      case 'one_time_job':
        badgeColor = Colors.orange;
        badgeIcon = Icons.handyman_outlined;
        badgeText = 'Bir martalik ish';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 280,
            viewportFraction: 1.0,
            autoPlay: false,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              if (mounted) {
                setState(() => _currentImageIndex = index);
              }
            },
          ),
          items: widget.post.imageUrls!.map((imageUrl) {
            return GestureDetector(
              onTap: () => _showFullScreenImageViewer(
                context,
                widget.post.imageUrls!,
                _currentImageIndex,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppConstants.radiusLarge),
                  ),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppConstants.radiusLarge),
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (widget.post.imageUrls!.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.post.imageUrls!.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == entry.key
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }).toList(),
            ),
          ),
        if (widget.post.isNew)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Yangi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showFullScreenImageViewer(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrls: widget.post.imageUrls!,
          initialIndex: _currentImageIndex,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLarge),
        ),
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.3),
            Colors.purple.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.post.getCategoryEmoji(widget.post.categoryIdNum),
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'Imkon Job',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.post.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _navigateToUserProfile(),
          child: Row(
            children: [
              if (widget.post.companyLogo != null)
                CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(widget.post.companyLogo!),
                  backgroundColor: Colors.grey[300],
                ),
              if (widget.post.companyLogo != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.post.company,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: AppConstants.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          widget.post.description,
          style: const TextStyle(
            fontSize: 13,
            color: AppConstants.textSecondary,
            height: 1.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Row(
      children: [
        const Icon(
          Icons.location_on_rounded,
          size: 16,
          color: AppConstants.primaryColor,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.post.location,
            style: const TextStyle(
              fontSize: 13,
              color: AppConstants.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.category_rounded,
            size: 18,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.getCategoryDisplay(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                if (widget.post.subCategoryName != null &&
                    widget.post.subCategoryName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.subdirectory_arrow_right,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.post.subCategoryName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_rounded, size: 20, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                widget.post.getSalaryRange(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          if (widget.post.salaryType != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getSalaryTypeText(widget.post.salaryType!),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getSalaryTypeText(String salaryType) {
    switch (salaryType) {
      case 'daily':
        return 'Kunlik';
      case 'monthly':
        return 'Oylik';
      case 'freelance':
        return 'Freelance';
      default:
        return salaryType;
    }
  }

  Widget _buildStatsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.visibility_outlined,
              color: AppConstants.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              '${widget.post.views}',
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onLike,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: widget.isLiked
                            ? Colors.red
                            : AppConstants.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.post.likes}',
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _sharePost(),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(
                    Icons.share_outlined,
                    color: AppConstants.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(
          widget.post.getFormattedDate(),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _sharePost() async {
    try {
      final postLink = 'https://imkonjob.uz/post/${widget.post.id}';

      final shareText =
          '''
📢 ${widget.post.title}

🏢 ${widget.post.company}
📍 ${widget.post.location}
💰 ${widget.post.getSalaryRange()}
${widget.post.salaryType != null ? '⏰ ${_getSalaryTypeText(widget.post.salaryType!)}' : ''}

${widget.post.description.length > 150 ? widget.post.description.substring(0, 150) + '...' : widget.post.description}

🔗 To'liq ma'lumot: $postLink

📱 ImkonJob - Ish topish oson!
''';

      final result = await Share.share(shareText, subject: widget.post.title);

      if (result.status == ShareResultStatus.success) {
        await _supabase
            .from('posts')
            .update({'shares_count': (widget.post.sharesCount ?? 0) + 1})
            .eq('id', widget.post.id);
      }
    } catch (e) {
      print('Share error: $e');
    }
  }

  void _navigateToUserProfile() {
    Get.to(
      () => OtherUserProfilePage(userId: widget.post.userId),
      transition: Transition.rightToLeft,
    );
  }

  void _showPostDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXLarge),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPostTypeBadge(),
                    const SizedBox(height: 16),
                    Text(
                      widget.post.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildUserInfoCard(),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.location_on_rounded,
                      'Joylashuv',
                      widget.post.location,
                    ),
                    const SizedBox(height: 16),
                    _buildSalaryCard(),
                    const SizedBox(height: 20),
                    if (widget.post.categoryIdNum != null) ...[
                      _buildCategoryRow(),
                      const SizedBox(height: 24),
                    ],
                    if (widget.post.description.isNotEmpty) ...[
                      const Text(
                        'Tasnif',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.post.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppConstants.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (widget.post.requirementsMain != null &&
                        widget.post.requirementsMain!.isNotEmpty) ...[
                      const Text(
                        'Asosiy Talablar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          widget.post.requirementsMain!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppConstants.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (widget.post.requirementsBasic != null &&
                        widget.post.requirementsBasic!.isNotEmpty) ...[
                      const Text(
                        'Qo\'shimcha Talablar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          widget.post.requirementsBasic!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppConstants.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (widget.post.skills != null &&
                        widget.post.skills!.isNotEmpty) ...[
                      const Text(
                        'Ko\'nikmalar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.post.skills!.split(',').map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              skill.trim(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (widget.post.experience != null &&
                        widget.post.experience!.isNotEmpty) ...[
                      _buildDetailRow(
                        Icons.work_history_rounded,
                        'Tajriba',
                        widget.post.experience!,
                      ),
                      const SizedBox(height: 20),
                    ],
                    _buildDetailedStatsRow(),
                    const SizedBox(height: 24),
                    _buildApplyButton(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return GestureDetector(
      onTap: () => _navigateToUserProfile(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: widget.post.companyLogo != null
                  ? NetworkImage(widget.post.companyLogo!)
                  : null,
              backgroundColor: Colors.grey[300],
              child: widget.post.companyLogo == null
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.company,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Profilga o\'tish',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: AppConstants.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApplyForJob() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        Get.snackbar(
          'Xatolik',
          'Ariza berish uchun tizimga kiring',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      if (currentUserId == widget.post.userId) {
        Get.snackbar(
          'Xatolik',
          'O\'z postingizga ariza bera olmaysiz',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

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
                  Text('Ariza tayyorlanmoqda...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      String chatId = await _getOrCreateChat(currentUserId, widget.post.userId);

      String applicationMessage = _prepareApplicationMessage();

      Get.back();

      final result = await Get.toNamed(
        '/chat_detail',
        arguments: {
          'chatId': chatId,
          'otherUserId': widget.post.userId,
          'userName': widget.post.company,
          'userAvatar': widget.post.companyLogo,
          'initialMessage': applicationMessage,
        },
      );

      if (result == true) {
        Get.snackbar(
          'Muvaffaqiyatli',
          'Arizangiz yuborildi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Apply error: $e');
      Get.snackbar(
        'Xatolik',
        'Ariza yuborishda xatolik yuz berdi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<String> _getOrCreateChat(
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      final existingChats = await _supabase
          .from('chats')
          .select('id')
          .or(
            'and(user1_id.eq.$currentUserId,user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.$currentUserId)',
          )
          .limit(1);

      if (existingChats.isNotEmpty) {
        return existingChats[0]['id'] as String;
      }

      final newChat = await _supabase
          .from('chats')
          .insert({
            'user1_id': currentUserId,
            'user2_id': otherUserId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return newChat['id'] as String;
    } catch (e) {
      print('Get or create chat error: $e');
      rethrow;
    }
  }

  String _prepareApplicationMessage() {
    final postType = widget.post.postType;
    String greeting = '';

    if (postType == 'employee_needed') {
      greeting = '👋 Assalomu aleykum!\n\n';
      greeting +=
          '🔹 *"${widget.post.title}"* lavozimiga ariza bermoqchiman.\n\n';
    } else if (postType == 'one_time_job') {
      greeting = '👋 Assalomu aleykum!\n\n';
      greeting +=
          '🔹 *"${widget.post.title}"* loyihasi ustida ishlashga tayyorman.\n\n';
    } else {
      greeting = '👋 Assalomu aleykum!\n\n';
      greeting +=
          '🔹 *"${widget.post.title}"* e\'loningizga qiziqish bildirdim.\n\n';
    }

    String message = greeting;

    message += '📋 *E\'lon ma\'lumotlari:*\n';
    message += '• Kompaniya: ${widget.post.company}\n';
    message += '• Joylashuv: ${widget.post.location}\n';
    message += '• Maosh: ${widget.post.getSalaryRange()}\n';

    if (widget.post.categoryIdNum != null) {
      message += '• Kategoriya: ${widget.post.getCategoryDisplay()}\n';
    }

    message += '\n';
    message += '✅ Ushbu ish bo\'yicha batafsil ma\'lumot olishni istardim.\n';
    message +=
        '📞 Qo\'shimcha savollaringiz bo\'lsa, javob berishga tayyorman.\n\n';
    message += 'Hurmat bilan! 🤝';

    return message;
  }

  Widget _buildSalaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.post.postType == 'one_time_job'
                    ? 'Loyiha Byudjeti'
                    : 'Maosh',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (widget.post.salaryType != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getSalaryTypeText(widget.post.salaryType!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.post.getSalaryRange(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategoriya',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.post.getCategoryEmoji(widget.post.categoryIdNum),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.post.getCategoryDisplay(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          icon: Icons.visibility_outlined,
          value: widget.post.views.toString(),
          label: 'Ko\'rishlar',
        ),
        _buildStatItem(
          icon: Icons.favorite_outline,
          value: widget.post.likes.toString(),
          label: 'Yoqtirishlar',
        ),
        GestureDetector(
          onTap: () => _sharePost(),
          child: Column(
            children: [
              Icon(
                Icons.share_outlined,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ulashish',
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () async {
          Navigator.pop(context);
          await _handleApplyForJob();
        },
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: const Text(
          'Ariza berish',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppConstants.primaryColor),
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
                value.isEmpty ? 'Ma\'lumot yo\'q' : value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppConstants.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ✅ TO'LIQ EKRAN RASM KO'RISH
class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    Key? key,
    required this.imageUrls,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, TransformationController> _transformationControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    for (int i = 0; i < widget.imageUrls.length; i++) {
      _transformationControllers[i] = TransformationController();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _transformationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _resetZoom(int index) {
    if (_transformationControllers[index] != null) {
      _transformationControllers[index]!.value = Matrix4.identity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (mounted) {
                setState(() => _currentIndex = index);
              }
              if (_currentIndex != index) {
                _resetZoom(_currentIndex);
              }
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                transformationController: _transformationControllers[index],
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.imageUrls.asMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        entry.key,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: _currentIndex == entry.key ? 32 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentIndex == entry.key
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
