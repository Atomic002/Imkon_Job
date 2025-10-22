import 'package:flutter/material.dart' hide SearchController;
import 'package:get/get.dart';
import '../../config/constants.dart';
import '/controller/search_controller.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller init qilish
    final controller = Get.put(SearchController());

    return Scaffold(
      appBar: AppBar(
        title: Text('search'.tr),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        actions: [
          Obx(
            () => controller.selectedUserType.value != null
                ? IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: controller.clearFilters,
                    tooltip: 'Filtrlarni tozalash',
                  )
                : const SizedBox(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          children: [
            // Search TextField
            TextField(
              controller: controller.searchTextController,
              decoration: InputDecoration(
                hintText: 'E\'lonlar qidiring...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: controller.searchTextController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.searchTextController.clear();
                        },
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
                fillColor: Colors.white,
              ),
              onSubmitted: (_) {
                if (controller.selectedUserType.value != null) {
                  controller.performSearch();
                }
              },
            ),
            const SizedBox(height: 20),

            // User Type Selection (Ish beruvchi / Ish qidiruvchi)
            _buildSectionTitle(context, 'Kim e\'lon qo\'ygan?'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildUserTypeCard(
                    controller,
                    'employer',
                    '💼',
                    'Ish beruvchi',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUserTypeCard(
                    controller,
                    'job_seeker',
                    '👤',
                    'Ish qidiruvchi',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Categories Section
            if (controller.selectedUserType.value != null) ...[
              _buildSectionTitle(context, 'Kategoriya tanlang'),
              const SizedBox(height: 12),
              _buildCategoriesGrid(controller),
              const SizedBox(height: 24),
            ],

            // Sub Categories Section
            if (controller.selectedCategory.value != null &&
                controller.subCategories.isNotEmpty) ...[
              _buildSectionTitle(context, 'Sub kategoriya'),
              const SizedBox(height: 12),
              _buildSubCategoriesWrap(controller),
              const SizedBox(height: 24),
            ],

            // Location Section
            if (controller.selectedCategory.value != null) ...[
              _buildSectionTitle(context, 'Manzil'),
              const SizedBox(height: 12),
              _buildLocationDropdowns(controller),
              const SizedBox(height: 24),
            ],

            // Search Button
            if (controller.selectedUserType.value != null) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.performSearch,
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
                    controller.isLoading.value ? 'Qidirilmoqda...' : 'Qidirish',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppConstants.primaryColor
                        .withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Search Results
            if (controller.searchResults.isNotEmpty) ...[
              _buildSectionTitle(
                context,
                'Natijalar (${controller.searchResults.length})',
              ),
              const SizedBox(height: 12),
              _buildSearchResults(controller),
            ] else if (controller.selectedUserType.value == null) ...[
              // Popular searches
              _buildSectionTitle(context, 'Mashhur qidiruvlar'),
              const SizedBox(height: 12),
              _buildPopularSearches(controller),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: AppConstants.textPrimary,
      ),
    );
  }

  Widget _buildUserTypeCard(
    SearchController controller,
    String type,
    String icon,
    String label,
  ) {
    return Obx(() {
      final isSelected = controller.selectedUserType.value == type;

      return GestureDetector(
        onTap: () => controller.selectUserType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppConstants.primaryColor
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppConstants.primaryColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isSelected ? 15 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppConstants.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCategoriesGrid(SearchController controller) {
    return Obx(
      () => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: controller.categories.length,
        itemBuilder: (context, index) {
          final category = controller.categories[index];
          final isSelected =
              controller.selectedCategory.value?['id'] == category['id'];

          return GestureDetector(
            onTap: () => controller.selectCategory(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category['icon_url'] ?? '📁',
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      category['name'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppConstants.primaryColor
                            : AppConstants.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubCategoriesWrap(SearchController controller) {
    return Obx(
      () => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: controller.subCategories.map((subCat) {
          final isSelected =
              controller.selectedSubCategory.value?['id'] == subCat['id'];

          return FilterChip(
            label: Text(subCat['name']),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                controller.selectSubCategory(subCat);
              } else {
                controller.selectedSubCategory.value = null;
              }
            },
            selectedColor: AppConstants.primaryColor,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppConstants.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? AppConstants.primaryColor
                  : Colors.grey.shade300,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLocationDropdowns(SearchController controller) {
    return Obx(
      () => Column(
        children: [
          // Region Dropdown
          DropdownButtonFormField<String>(
            value: controller.selectedRegion.value,
            decoration: InputDecoration(
              labelText: 'Viloyat',
              prefixIcon: const Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
              fillColor: Colors.white,
            ),
            items: controller.regions.map((region) {
              return DropdownMenuItem(value: region, child: Text(region));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.selectRegion(value);
              }
            },
          ),
          const SizedBox(height: 12),
          // District Dropdown
          if (controller.selectedRegion.value != null)
            DropdownButtonFormField<String>(
              value: controller.selectedDistrict.value,
              decoration: InputDecoration(
                labelText: 'Tuman/Shahar',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                fillColor: Colors.white,
              ),
              items:
                  (controller.districts[controller.selectedRegion.value] ?? [])
                      .map((district) {
                        return DropdownMenuItem(
                          value: district,
                          child: Text(district),
                        );
                      })
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.selectDistrict(value);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPopularSearches(SearchController controller) {
    return Obx(
      () => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: controller.popularSearches.map((search) {
          return ActionChip(
            label: Text(search),
            onPressed: () {
              controller.selectPopularSearch(search);
            },
            backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
            labelStyle: const TextStyle(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w500,
            ),
            side: BorderSide.none,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchResults(SearchController controller) {
    return Obx(
      () => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.searchResults.length,
        itemBuilder: (context, index) {
          final post = controller.searchResults[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to post detail
          Get.toNamed('/post-detail', arguments: post['id']);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                    backgroundImage: post['users']?['avatar_url'] != null
                        ? NetworkImage(post['users']['avatar_url'])
                        : null,
                    child: post['users']?['avatar_url'] == null
                        ? const Icon(
                            Icons.person,
                            color: AppConstants.primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['users']?['full_name'] ?? 'Anonim',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                                post['location'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post['title'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (post['categories'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            post['categories']['icon_url'] ?? '📁',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            post['categories']['name'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post['views_count'] ?? 0}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.favorite_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post['likes_count'] ?? 0}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
