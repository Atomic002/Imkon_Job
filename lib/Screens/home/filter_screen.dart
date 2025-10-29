import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:version1/Widgets/filter_post_card.dart';
import 'package:version1/config/constants.dart';
import 'package:version1/controller/filter_controller.dart';

// =====================================================
// 1. ASOSIY FILTER SCREEN (FAQAT NATIJALAR)
// =====================================================
class FilterScreen extends StatelessWidget {
  const FilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FilterController(), permanent: false);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('filter'.tr),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        actions: [
          // Filter tugmasi - Bottom Sheet ochish uchun
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterBottomSheet(context, controller),
            tooltip: 'Filtr sozlamalari',
          ),
          Obx(() {
            if (controller.hasActiveFilters()) {
              return IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: controller.resetFilters,
                tooltip: 'Filtrlarni tozalash',
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Qidirilmoqda...'),
              ],
            ),
          );
        }

        if (!controller.isSearchPerformed.value) {
          return _buildEmptyState(context, controller);
        }

        if (controller.filteredPosts.isEmpty) {
          return _buildNoResultsState(context, controller);
        }

        return _buildResultsList(controller);
      }),
    );
  }

  // =====================================================
  // 2. FILTER BOTTOM SHEET - PASTDAN CHIQADIGAN
  // =====================================================
  void _showFilterBottomSheet(
    BuildContext context,
    FilterController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtr sozlamalari',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Filter Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search TextField
                    Obx(
                      () => TextField(
                        controller: controller.searchController,
                        decoration: InputDecoration(
                          hintText: 'Sarlovha bo\'yicha qidirish...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: controller.searchText.value.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: controller.clearSearchText,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppConstants.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Post Type Selection
                    _buildSectionTitle('E\'lon turi'),
                    const SizedBox(height: 12),
                    Obx(() => _buildPostTypeSelector(controller)),
                    const SizedBox(height: 24),

                    // Category Selection
                    Obx(() {
                      if (controller.selectedPostType.value != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildExpandableSection(
                              title: 'Kategoriya',
                              icon: Icons.category_rounded,
                              value:
                                  controller.selectedCategory.value?['name'] ??
                                  'Tanlash',
                              onTap: () =>
                                  _showCategoryBottomSheet(context, controller),
                            ),
                            const SizedBox(height: 12),

                            if (controller.selectedCategory.value != null &&
                                controller.subCategories.isNotEmpty)
                              _buildExpandableSection(
                                title: 'Sub kategoriya',
                                icon: Icons.subdirectory_arrow_right,
                                value:
                                    controller
                                        .selectedSubCategory
                                        .value?['name'] ??
                                    'Tanlash',
                                onTap: () => _showSubCategoryBottomSheet(
                                  context,
                                  controller,
                                ),
                              ),
                            if (controller.selectedCategory.value != null &&
                                controller.subCategories.isNotEmpty)
                              const SizedBox(height: 12),

                            _buildExpandableSection(
                              title: 'Manzil',
                              icon: Icons.location_on_rounded,
                              value: controller.getLocationDisplay(),
                              onTap: () =>
                                  _showLocationBottomSheet(context, controller),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Active Filters Chips
                    Obx(() {
                      if (controller.hasActiveFilters()) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Faol filtrlar'),
                            const SizedBox(height: 12),
                            _buildActiveFiltersChips(controller),
                            const SizedBox(height: 24),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Apply Button
                    Obx(() {
                      if (controller.canSearch()) {
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: controller.isLoading.value
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    controller.applyFilters();
                                  },
                            icon: controller.isLoading.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.search, color: Colors.white),
                            label: Text(
                              controller.isLoading.value
                                  ? 'Qidirilmoqda...'
                                  : 'Qidirish',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: controller.isLoading.value
                                  ? Colors.grey
                                  : AppConstants.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
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

  // =====================================================
  // 3. CATEGORY BOTTOM SHEET
  // =====================================================
  void _showCategoryBottomSheet(
    BuildContext context,
    FilterController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kategoriya tanlang',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.categories.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
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
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          controller.selectCategory(category);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppConstants.primaryColor.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
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

  // =====================================================
  // 4. SUB-CATEGORY BOTTOM SHEET
  // =====================================================
  void _showSubCategoryBottomSheet(
    BuildContext context,
    FilterController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sub kategoriya tanlang',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: Obx(() {
                if (controller.subCategories.isEmpty) {
                  return const Center(
                    child: Text('Sub kategoriyalar mavjud emas'),
                  );
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
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          controller.selectSubCategory(subCategory);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppConstants.primaryColor.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
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

  // =====================================================
  // 5. LOCATION BOTTOM SHEET
  // =====================================================
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
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Manzil tanlang',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: Obx(() {
                    if (controller.selectedRegion.value == null) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.regions.length,
                        itemBuilder: (context, index) {
                          final region = controller.regions[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                controller.selectRegion(region);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
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
                                      size: 16,
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

                    final selectedRegion = controller.selectedRegion.value!;
                    final districts =
                        controller.districts[selectedRegion] ?? [];

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: InkWell(
                            onTap: () {
                              controller.selectedRegion.value = null;
                              controller.selectedDistrict.value = null;
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_back, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedRegion,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: InkWell(
                            onTap: () {
                              controller.selectWholeRegion(); // ✅ Yangi metod
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppConstants.primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.location_city,
                                    color: AppConstants.primaryColor,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Butun viloyat/shahar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: districts.length,
                            itemBuilder: (context, index) {
                              final district = districts[index];
                              final isSelected =
                                  controller.selectedDistrict.value == district;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () {
                                    controller.selectDistrict(district);
                                    Navigator.pop(context);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppConstants.primaryColor
                                                .withOpacity(0.1)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
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

  // =====================================================
  // 6. POST TYPE SELECTOR
  // =====================================================
  Widget _buildPostTypeSelector(FilterController controller) {
    final selectedType = controller.selectedPostType.value;

    return Row(
      children: [
        Expanded(
          child: _buildPostTypeCard(
            controller,
            'employee_needed',
            '💼',
            'Hodim kerak',
            selectedType == 'employee_needed',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPostTypeCard(
            controller,
            'job_needed',
            '👤',
            'Ish kerak',
            selectedType == 'job_needed',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPostTypeCard(
            controller,
            'one_time_job',
            '🛠️',
            'Bir martalik',
            selectedType == 'one_time_job',
          ),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 7. RESULTS LIST - POST CARDLAR
  // =====================================================
  Widget _buildResultsList(FilterController controller) {
    return RefreshIndicator(
      onRefresh: controller.applyFilters,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.filteredPosts.length,
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
    );
  }

  // =====================================================
  // 8. HELPER WIDGETS - CLASS ICHIDA
  // =====================================================
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppConstants.textPrimary,
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppConstants.primaryColor, size: 20),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

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
          label: controller.selectedCategory.value!['name'],
          onDeleted: controller.clearCategory,
        ),
      );
    }

    if (controller.selectedSubCategory.value != null) {
      chips.add(
        _buildFilterChip(
          label: controller.selectedSubCategory.value!['name'],
          onDeleted: controller.clearSubCategory,
        ),
      );
    }

    if (controller.selectedRegion.value != null) {
      chips.add(
        _buildFilterChip(
          label: controller.getLocationDisplay(),
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
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDeleted,
      backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: AppConstants.primaryColor,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: AppConstants.primaryColor.withOpacity(0.3)),
    );
  }

  Widget _buildEmptyState(BuildContext context, FilterController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Qidirish uchun tayyor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yuqoridagi filter tugmasini bosib\nqidiruv parametrlarini tanlang',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showFilterBottomSheet(context, controller),
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            label: const Text(
              'Filtr ochish',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(
    BuildContext context,
    FilterController controller,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Hech narsa topilmadi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Filtrlarni o\'zgartirib\nyana urinib ko\'ring',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showFilterBottomSheet(context, controller),
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            label: const Text(
              'Filtrlarni o\'zgartirish',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
