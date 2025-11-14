import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:version1/Widgets/filter_post_card.dart';
import 'package:version1/config/constants.dart';
import 'package:version1/controller/filter_controller.dart';

class FilterScreen extends StatelessWidget {
  const FilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FilterController(), permanent: false);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Qidiruv va Filtr'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterBottomSheet(context, controller),
            tooltip: 'Filtrlarni sozlash',
          ),
          Obx(() {
            if (controller.hasActiveFilters()) {
              return IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.red),
                onPressed: controller.resetFilters,
                tooltip: 'Filtrlarni tozalash',
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        // Loading holati
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Qidirilmoqda...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // Qidiruv hali bajarilmagan
        if (!controller.isSearchPerformed.value) {
          return _buildEmptyState(context, controller);
        }

        // Natija topilmadi
        if (controller.filteredPosts.isEmpty) {
          return _buildNoResultsState(context, controller);
        }

        // Natijalar ro'yxati
        return _buildResultsList(controller);
      }),
      floatingActionButton: Obx(() {
        if (controller.selectedPostType.value != null &&
            !controller.isLoading.value) {
          return FloatingActionButton.extended(
            onPressed: () => _showFilterBottomSheet(context, controller),
            backgroundColor: AppConstants.primaryColor,
            icon: const Icon(Icons.tune, color: Colors.white),
            label: const Text(
              'Filtr',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  // ✅ FILTER BOTTOM SHEET
  void _showFilterBottomSheet(
    BuildContext context,
    FilterController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Qidiruv Filtri',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Filter content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search input
                    Obx(
                      () => TextField(
                        controller: controller.searchController,
                        decoration: InputDecoration(
                          hintText: 'E\'lon nomini kiriting...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppConstants.primaryColor,
                          ),
                          suffixIcon: controller.searchText.value.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: controller.clearSearchText,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppConstants.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Post Type selector
                    _buildSectionTitle('📋 E\'lon Turi', required: true),
                    const SizedBox(height: 12),
                    Obx(() => _buildPostTypeSelector(controller)),
                    const SizedBox(height: 28),

                    // Other filters (shown only when post type selected)
                    Obx(() {
                      if (controller.selectedPostType.value != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category
                            _buildExpandableSection(
                              title: 'Kategoriya',
                              icon: Icons.category_rounded,
                              value:
                                  controller.selectedCategory.value?['name'] ??
                                  'Tanlash',
                              isSelected:
                                  controller.selectedCategory.value != null,
                              onTap: () =>
                                  _showCategoryBottomSheet(context, controller),
                              onClear: controller.selectedCategory.value != null
                                  ? controller.clearCategory
                                  : null,
                            ),
                            const SizedBox(height: 12),

                            // Subcategory
                            if (controller.selectedCategory.value != null &&
                                controller.subCategories.isNotEmpty)
                              Column(
                                children: [
                                  _buildExpandableSection(
                                    title: 'Sub-kategoriya',
                                    icon: Icons.subdirectory_arrow_right,
                                    value:
                                        controller
                                            .selectedSubCategory
                                            .value?['name'] ??
                                        'Tanlash',
                                    isSelected:
                                        controller.selectedSubCategory.value !=
                                        null,
                                    onTap: () => _showSubCategoryBottomSheet(
                                      context,
                                      controller,
                                    ),
                                    onClear:
                                        controller.selectedSubCategory.value !=
                                            null
                                        ? controller.clearSubCategory
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),

                            // Location
                            _buildExpandableSection(
                              title: 'Manzil',
                              icon: Icons.location_on_rounded,
                              value: controller.getLocationDisplay(),
                              isSelected:
                                  controller.selectedRegion.value != null,
                              onTap: () =>
                                  _showLocationBottomSheet(context, controller),
                              onClear: controller.selectedRegion.value != null
                                  ? controller.clearLocation
                                  : null,
                            ),
                            const SizedBox(height: 28),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Active filters chips
                    Obx(() {
                      if (controller.hasActiveFilters()) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('🏷️ Aktiv Filtrlar'),
                            const SizedBox(height: 12),
                            _buildActiveFiltersChips(controller),
                            const SizedBox(height: 24),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Search button
                    Obx(() {
                      if (controller.canSearch()) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    controller.applyFilters();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: controller.isLoading.value
                                  ? Colors.grey
                                  : AppConstants.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Qidirish',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Qidirish uchun e\'lon turini tanlang',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ POST TYPE SELECTOR
  Widget _buildPostTypeSelector(FilterController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPostTypeCard(
                controller,
                'employee_needed',
                '💼',
                'Ishchi kerak',
                controller.selectedPostType.value == 'employee_needed',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPostTypeCard(
                controller,
                'job_needed',
                '👤',
                'Ish kerak',
                controller.selectedPostType.value == 'job_needed',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPostTypeCard(
                controller,
                'one_time_job',
                '🛠️',
                'Bir martalik ish',
                controller.selectedPostType.value == 'one_time_job',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPostTypeCard(
                controller,
                'service_offering',
                '🤝',
                'Xizmat',
                controller.selectedPostType.value == 'service_offering',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostTypeCard(
    FilterController controller,
    String type,
    String emoji,
    String title,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => controller.selectPostType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppConstants.primaryColor, Color(0xFF6A5AE0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ SECTION TITLE
  Widget _buildSectionTitle(String title, {bool required = false}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  // ✅ EXPANDABLE SECTION
  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppConstants.primaryColor.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppConstants.primaryColor
                    : Colors.grey[600],
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected && onClear != null)
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Colors.red,
                ),
                onPressed: onClear,
              )
            else
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ✅ ACTIVE FILTERS CHIPS
  Widget _buildActiveFiltersChips(FilterController controller) {
    List<Widget> chips = [];

    if (controller.searchText.value.isNotEmpty) {
      chips.add(
        _buildFilterChip(
          label: '🔎 ${controller.searchText.value}',
          onDeleted: controller.clearSearchText,
        ),
      );
    }

    if (controller.selectedCategory.value != null) {
      chips.add(
        _buildFilterChip(
          label: '📂 ${controller.selectedCategory.value!['name']}',
          onDeleted: controller.clearCategory,
        ),
      );
    }

    if (controller.selectedSubCategory.value != null) {
      chips.add(
        _buildFilterChip(
          label: '📁 ${controller.selectedSubCategory.value!['name']}',
          onDeleted: controller.clearSubCategory,
        ),
      );
    }

    if (controller.selectedRegion.value != null) {
      chips.add(
        _buildFilterChip(
          label: '📍 ${controller.getLocationDisplay()}',
          onDeleted: controller.clearLocation,
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close_rounded, size: 18),
      onDeleted: onDeleted,
      backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
      labelStyle: const TextStyle(
        fontSize: 13,
        color: AppConstants.primaryColor,
        fontWeight: FontWeight.w600,
      ),
      deleteIconColor: Colors.red,
      side: BorderSide(
        color: AppConstants.primaryColor.withOpacity(0.3),
        width: 1.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  // ✅ RESULTS LIST
  // FilterScreen ichidagi _buildResultsList funksiyasini shunday o'zgartiring:

  Widget _buildResultsList(FilterController controller) {
    return Column(
      children: [
        // Results count header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(
                () => Text(
                  '${controller.filteredPosts.length} ta e\'lon topildi',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sort_rounded),
                onPressed: () {
                  // Sorting options
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.applyFilters,
            color: AppConstants.primaryColor,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.filteredPosts.length,
              // ✅ ASOSIY TUZATISH: itemExtent qo'shildi
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final post = controller.filteredPosts[index];
                return FilterPostCard(
                  post: post,
                  onLike: () => controller.toggleLike(post.id),
                  isLiked: controller.isPostLiked(post.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ✅ EMPTY STATE
  Widget _buildEmptyState(BuildContext context, FilterController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 80,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Qidiruv Boshlang!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'E\'lonlarni qidirish uchun\nfiltrlarni sozlang',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _showFilterBottomSheet(context, controller),
                icon: const Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  'Filtrlarni Ochish',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NO RESULTS STATE
  Widget _buildNoResultsState(
    BuildContext context,
    FilterController controller,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 80,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Natija Topilmadi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Boshqa filtrlarni\nsinab ko\'ring',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: controller.resetFilters,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(
                        'Tozalash',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showFilterBottomSheet(context, controller),
                      icon: const Icon(Icons.tune, color: Colors.white),
                      label: const Text(
                        'O\'zgartirish',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ CATEGORY BOTTOM SHEET
  void _showCategoryBottomSheet(
    BuildContext context,
    FilterController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kategoriya Tanlang',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.categories.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.categories.length,
                  itemBuilder: (context, index) {
                    final category = controller.categories[index];
                    final isSelected =
                        controller.selectedCategory.value?['id'] ==
                        category['id'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          controller.selectCategory(category);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppConstants.primaryColor.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppConstants.primaryColor
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppConstants.primaryColor
                                        : AppConstants.textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppConstants.primaryColor,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ SUBCATEGORY BOTTOM SHEET
  void _showSubCategoryBottomSheet(
    BuildContext context,
    FilterController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sub-kategoriya Tanlang',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                if (controller.subCategories.isEmpty) {
                  return const Center(child: Text('Sub-kategoriya topilmadi'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.subCategories.length,
                  itemBuilder: (context, index) {
                    final subCategory = controller.subCategories[index];
                    final isSelected =
                        controller.selectedSubCategory.value?['id'] ==
                        subCategory['id'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          controller.selectSubCategory(subCategory);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppConstants.primaryColor.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppConstants.primaryColor
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  subCategory['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppConstants.primaryColor
                                        : AppConstants.textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppConstants.primaryColor,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ LOCATION BOTTOM SHEET
  void _showLocationBottomSheet(
    BuildContext context,
    FilterController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Manzil Tanlang',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Obx(() {
                    if (controller.selectedRegion.value == null) {
                      // Show regions list
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.regions.length,
                        itemBuilder: (context, index) {
                          final region = controller.regions[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                controller.selectRegion(region);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.location_city,
                                        color: AppConstants.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        region,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }

                    // Show districts list
                    final selectedRegion = controller.selectedRegion.value!;
                    final districts =
                        controller.districts[selectedRegion] ?? [];

                    return Column(
                      children: [
                        // Back button
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: InkWell(
                            onTap: () {
                              controller.selectedRegion.value = null;
                              controller.selectedDistrict.value = null;
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_back, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      selectedRegion,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Whole region option
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: InkWell(
                            onTap: () {
                              controller.selectWholeRegion();
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppConstants.primaryColor,
                                    Color(0xFF6A5AE0),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppConstants.primaryColor
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Butun viloyat',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(),
                        ),
                        const SizedBox(height: 8),
                        // Districts list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: districts.length,
                            itemBuilder: (context, index) {
                              final district = districts[index];
                              final isSelected =
                                  controller.selectedDistrict.value == district;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    controller.selectDistrict(district);
                                    Navigator.pop(context);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppConstants.primaryColor
                                                .withOpacity(0.1)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppConstants.primaryColor
                                            : Colors.grey.shade300,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            district,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? AppConstants.primaryColor
                                                  : AppConstants.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: AppConstants.primaryColor,
                                            size: 24,
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
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
