import 'package:supabase_flutter/supabase_flutter.dart';

class SearchService {
  final _supabase = Supabase.instance.client;

  // Kategoriyalarni olish
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('id, name, icon_url')
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Kategoriyalarni yuklashda xato: $e');
    }
  }

  // Sub kategoriyalarni olish
  Future<List<Map<String, dynamic>>> getSubCategories(int categoryId) async {
    try {
      final response = await _supabase
          .from('sub_categories')
          .select('id, name, category_id')
          .eq('category_id', categoryId)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Sub kategoriyalarni yuklashda xato: $e');
    }
  }

  // Postlarni qidirish
  Future<List<Map<String, dynamic>>> searchPosts({
    String? searchQuery,
    String? userType, // 'employer' or 'job_seeker'
    int? categoryId,
    int? subCategoryId,
    String? region,
    String? district,
  }) async {
    try {
      var query = _supabase
          .from('posts')
          .select('''
            *,
            users!posts_user_id_fkey(id, full_name, avatar_url, user_type),
            categories!posts_category_id_fkey(id, name, icon_url),
            sub_categories!posts_sub_category_id_fkey(id, name)
          ''')
          .eq('is_active', true)
          .eq('status', 'approved');

      // Search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'title.ilike.%$searchQuery%,description.ilike.%$searchQuery%',
        );
      }

      // User type filter (ish beruvchi yoki ish qidiruvchi)
      if (userType != null) {
        query = query.eq('users.user_type', userType);
      }

      // Category filter
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      // Sub category filter
      if (subCategoryId != null) {
        query = query.eq('sub_category_id', subCategoryId);
      }

      // Location filter
      if (region != null && region.isNotEmpty) {
        if (district != null && district.isNotEmpty) {
          query = query.ilike('location', '%$region%$district%');
        } else {
          query = query.ilike('location', '%$region%');
        }
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Postlarni qidirishda xato: $e');
    }
  }

  // Ko'p qidirilgan so'zlar (mashhur qidiruvlar)
  Future<List<String>> getPopularSearches() async {
    // Bu yerda siz search_history jadvalidan yoki analytics dan olishingiz mumkin
    // Hozircha statik qaytaramiz, keyin API ga ulanadi
    return [
      'Flutter Developer',
      'React Developer',
      'UI Designer',
      'Mobile App Developer',
      'Backend Developer',
      'Frontend Developer',
    ];
  }
}
