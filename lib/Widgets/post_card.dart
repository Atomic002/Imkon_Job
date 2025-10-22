import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import '../Models/job_post.dart';
import '../config/constants.dart';

class PostCard extends StatefulWidget {
  final JobPost post;
  final VoidCallback onLike;
  final bool isLiked;
  final VoidCallback onTap;

  const PostCard({
    Key? key,
    required this.post,
    required this.onLike,
    required this.isLiked,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.post.hasImages;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: GestureDetector(
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
              // ========== IMAGE SECTION ==========
              if (hasImages) _buildImageCarousel() else _buildPlaceholder(),

              // ========== CONTENT SECTION ==========
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title & Company
                      _buildTitleSection(),

                      // Description
                      if (widget.post.description.isNotEmpty)
                        _buildDescriptionSection(),

                      const SizedBox(height: 12),

                      // Location & Category
                      _buildLocationCategorySection(),

                      const SizedBox(height: 12),

                      // Salary
                      _buildSalarySection(),

                      const SizedBox(height: 16),

                      // Views & Likes
                      _buildStatsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== IMAGE CAROUSEL ==========
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
            return Container(
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
            );
          }).toList(),
        ),

        // Image indicators
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

        // New badge
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

  // ========== PLACEHOLDER ==========
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
              'JobHub',
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

  // ========== TITLE SECTION ==========
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
        Row(
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
                  color: AppConstants.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========== DESCRIPTION SECTION ==========
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          widget.post.description,
          style: const TextStyle(
            fontSize: 12,
            color: AppConstants.textSecondary,
            height: 1.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ========== LOCATION & CATEGORY ==========
  Widget _buildLocationCategorySection() {
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
              fontSize: 12,
              color: AppConstants.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.post.getCategoryEmoji(widget.post.categoryIdNum),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 4),
              Text(
                widget.post.getCategoryName(widget.post.categoryIdNum),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========== SALARY SECTION ==========
  Widget _buildSalarySection() {
    return Row(
      children: [
        const Icon(
          Icons.payments_rounded,
          size: 18,
          color: AppConstants.primaryColor,
        ),
        const SizedBox(width: 6),
        Text(
          widget.post.getSalaryRange(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
      ],
    );
  }

  // ========== STATS SECTION ==========
  Widget _buildStatsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Views
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

        // Likes
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onLike,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    widget.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: widget.isLiked
                        ? Colors.red
                        : AppConstants.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
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

        // Date
        Text(
          widget.post.getFormattedDate(),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  // ========== BOTTOM SHEET ==========
  void _showPostDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXLarge),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.post.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Company
                    _buildDetailRow(
                      Icons.business_rounded,
                      'Kompaniya',
                      widget.post.company,
                    ),
                    const SizedBox(height: 12),

                    // Location
                    _buildDetailRow(
                      Icons.location_on_rounded,
                      'Joylashuv',
                      widget.post.location,
                    ),
                    const SizedBox(height: 16),

                    // Salary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Oylik To\'lovi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
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
                    ),
                    const SizedBox(height: 20),

                    // Category
                    Row(
                      children: [
                        const Text(
                          'Kategoriya:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.post.getCategoryEmoji(
                                  widget.post.categoryIdNum,
                                ),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.post.getCategoryName(
                                  widget.post.categoryIdNum,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'Tasnifi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.post.description.isEmpty
                          ? 'Tasnif ma\'lumoti yo\'q'
                          : widget.post.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                        height: 1.6,
                      ),
                    ),

                    // Requirements Main
                    if (widget.post.requirementsMain != null &&
                        widget.post.requirementsMain!.isNotEmpty) ...[
                      const SizedBox(height: 24),
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
                    ],

                    // Requirements Basic
                    if (widget.post.requirementsBasic != null &&
                        widget.post.requirementsBasic!.isNotEmpty) ...[
                      const SizedBox(height: 16),
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
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
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
                    ],

                    const SizedBox(height: 24),

                    // Stats Row
                    Row(
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
                        _buildStatItem(
                          icon: Icons.calendar_today_outlined,
                          value: widget.post.getFormattedDate(),
                          label: 'Sana',
                        ),
                      ],
                    ),

                    // Expiry Warning
                    if (widget.post.daysRemaining != null &&
                        widget.post.daysRemaining! <= 7 &&
                        widget.post.daysRemaining! > 0) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'E\'lon ${widget.post.daysRemaining} kundan keyin tugaydi',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showApplicationDialog(context);
                        },
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
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
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
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

  // ========== APPLICATION DIALOG ==========
  void _showApplicationDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Ariza Yuborildi!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Arizangiz muvaffaqiyatli yuborildi!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '✅ Arizangiz ko\'rib chiqilmoqda',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '📧 Natija tez orada xabar qilinadi',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '🔔 Bildirishnomalarni kuzatib boring',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Yopish',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ========== DETAIL ROW ==========
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

  // ========== STAT ITEM ==========
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
