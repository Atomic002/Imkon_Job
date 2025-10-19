import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('search'.tr),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          // Search TextField
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'E\'lonlar qidiring...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Popular searches
          Text(
            'Mashhur qidiruv',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSearchChip('Flutter Developer'),
              _buildSearchChip('React Developer'),
              _buildSearchChip('UI Designer'),
              _buildSearchChip('Mobile App'),
            ],
          ),
          const SizedBox(height: 20),

          // Categories
          Text(
            'Kategoriyalar',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildCategoryCard('💻', 'IT'),
              _buildCategoryCard('🏗️', 'Qurilish'),
              _buildCategoryCard('📚', 'Ta\'lim'),
              _buildCategoryCard('🛎️', 'Xizmatlar'),
              _buildCategoryCard('🚗', 'Transport'),
              _buildCategoryCard('🎨', 'Dizayn'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String label) {
    return Chip(
      label: Text(label),
      onDeleted: () {
        // Search filter
      },
      backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
      labelStyle: const TextStyle(color: AppConstants.primaryColor),
    );
  }

  Widget _buildCategoryCard(String icon, String label) {
    return GestureDetector(
      onTap: () {
        // Category tap
        print('Category tapped: $label');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
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
