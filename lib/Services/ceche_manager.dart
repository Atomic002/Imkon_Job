import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AppCacheManager {
  static const String _postsBoxName = 'posts_cache';
  static const String _categoriesBoxName = 'categories_cache';
  static const String _userDataBoxName = 'user_data_cache';
  static const String _imagesBoxName = 'images_cache';

  // ✅ Kesh muddati - 6 soat
  static const Duration _cacheValidDuration = Duration(hours: 6);

  // Singleton pattern
  static final AppCacheManager _instance = AppCacheManager._internal();
  factory AppCacheManager() => _instance;
  AppCacheManager._internal();

  late Box<dynamic> _postsBox;
  late Box<dynamic> _categoriesBox;
  late Box<dynamic> _userDataBox;
  late Box<dynamic> _imagesBox;

  // Initialize cache
  Future<void> init() async {
    await Hive.initFlutter();

    _postsBox = await Hive.openBox(_postsBoxName);
    _categoriesBox = await Hive.openBox(_categoriesBoxName);
    _userDataBox = await Hive.openBox(_userDataBoxName);
    _imagesBox = await Hive.openBox(_imagesBoxName);

    // Eski keshlarni tozalash
    _clearExpiredCache();
  }

  // ==================== POSTS CACHE ====================

  /// Barcha e'lonlarni keshga saqlash
  Future<void> cachePosts(List<Map<String, dynamic>> posts) async {
    try {
      final cacheData = {
        'posts': posts,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await _postsBox.put('all_posts', cacheData);
      print('✅ ${posts.length} ta e\'lon keshga saqlandi');
    } catch (e) {
      print('❌ Keshga saqlashda xatolik: $e');
    }
  }

  /// Keshdan e'lonlarni olish
  Future<List<Map<String, dynamic>>?> getCachedPosts() async {
    try {
      final data = _postsBox.get('all_posts');
      if (data == null) {
        print('ℹ️ Keshda ma\'lumot yo\'q');
        return null;
      }

      final timestamp = data['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Kesh muddatini tekshirish
      if (now - timestamp > _cacheValidDuration.inMilliseconds) {
        print('⏰ Kesh eskirgan, yangilash kerak');
        return null;
      }

      final posts = List<Map<String, dynamic>>.from(data['posts']);
      print('✅ Keshdan ${posts.length} ta e\'lon yuklandi');
      return posts;
    } catch (e) {
      print('❌ Keshdan olishda xatolik: $e');
      return null;
    }
  }

  /// Bitta e'lonni keshga saqlash
  Future<void> cachePost(String postId, Map<String, dynamic> post) async {
    try {
      await _postsBox.put('post_$postId', {
        'post': post,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('❌ Post keshga saqlanmadi: $e');
    }
  }

  /// Bitta e'lonni keshdan olish
  Future<Map<String, dynamic>?> getCachedPost(String postId) async {
    try {
      final data = _postsBox.get('post_$postId');
      if (data == null) return null;

      final timestamp = data['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - timestamp > _cacheValidDuration.inMilliseconds) {
        return null;
      }

      return Map<String, dynamic>.from(data['post']);
    } catch (e) {
      print('❌ Post keshdan olinmadi: $e');
      return null;
    }
  }

  // ==================== CATEGORIES CACHE ====================

  Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    try {
      await _categoriesBox.put('all_categories', {
        'categories': categories,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Kategoriyalar keshga saqlandi');
    } catch (e) {
      print('❌ Kategoriyalar saqlanmadi: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedCategories() async {
    try {
      final data = _categoriesBox.get('all_categories');
      if (data == null) return null;

      final timestamp = data['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Kategoriyalar uchun uzoqroq muddat - 24 soat
      if (now - timestamp > Duration(hours: 24).inMilliseconds) {
        return null;
      }

      return List<Map<String, dynamic>>.from(data['categories']);
    } catch (e) {
      print('❌ Kategoriyalar olinmadi: $e');
      return null;
    }
  }

  // ==================== USER DATA CACHE ====================

  Future<void> cacheUserProfile(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      await _userDataBox.put('user_$userId', {
        'data': userData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('❌ User data saqlanmadi: $e');
    }
  }

  Future<Map<String, dynamic>?> getCachedUserProfile(String userId) async {
    try {
      final data = _userDataBox.get('user_$userId');
      if (data == null) return null;

      final timestamp = data['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // User data uchun 24 soat
      if (now - timestamp > Duration(hours: 24).inMilliseconds) {
        return null;
      }

      return Map<String, dynamic>.from(data['data']);
    } catch (e) {
      print('❌ User data olinmadi: $e');
      return null;
    }
  }

  // ==================== IMAGE CACHE ====================

  /// Rasmni keshga saqlash va path olish
  Future<String?> getCachedImagePath(String imageUrl) async {
    try {
      final file = await DefaultCacheManager().getSingleFile(imageUrl);
      return file.path;
    } catch (e) {
      print('❌ Rasm yuklanmadi: $e');
      return null;
    }
  }

  /// Rasmlarni oldindan yuklash (background)
  Future<void> prefetchImages(List<String> imageUrls) async {
    try {
      for (final url in imageUrls) {
        DefaultCacheManager().downloadFile(url);
      }
      print('✅ ${imageUrls.length} ta rasm prefetch qilindi');
    } catch (e) {
      print('❌ Prefetch xatolik: $e');
    }
  }

  /// Rasm keshda borligini tekshirish
  Future<bool> isImageCached(String imageUrl) async {
    try {
      final fileInfo = await DefaultCacheManager().getFileFromCache(imageUrl);
      return fileInfo != null;
    } catch (e) {
      return false;
    }
  }

  // ==================== CACHE STATISTICS ====================

  Future<Map<String, dynamic>> getCacheStats() async {
    return {
      'posts_count': _postsBox.length,
      'categories_count': _categoriesBox.length,
      'users_count': _userDataBox.length,
      'total_items':
          _postsBox.length + _categoriesBox.length + _userDataBox.length,
    };
  }

  // ==================== CLEAR CACHE ====================

  /// Barcha keshni tozalash
  Future<void> clearAllCache() async {
    try {
      await _postsBox.clear();
      await _categoriesBox.clear();
      await _userDataBox.clear();
      await _imagesBox.clear();
      await DefaultCacheManager().emptyCache();
      print('✅ Barcha kesh tozalandi');
    } catch (e) {
      print('❌ Kesh tozalashda xatolik: $e');
    }
  }

  /// Faqat eskirgan keshlarni tozalash
  Future<void> _clearExpiredCache() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Posts keshini tekshirish
      for (var key in _postsBox.keys) {
        final data = _postsBox.get(key);
        if (data != null && data['timestamp'] != null) {
          final age = now - data['timestamp'];
          // 7 kundan eski keshlarni o'chirish
          if (age > Duration(days: 7).inMilliseconds) {
            await _postsBox.delete(key);
          }
        }
      }

      print('✅ Eski keshlar tozalandi');
    } catch (e) {
      print('❌ Eski kesh tozalashda xatolik: $e');
    }
  }

  /// Rasmlar keshini tozalash (30 kundan eski)
  Future<void> clearOldImageCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      print('✅ Rasmlar keshi tozalandi');
    } catch (e) {
      print('❌ Rasmlar keshi tozalanmadi: $e');
    }
  }

  /// Faqat postlar keshini tozalash
  Future<void> clearPostsCache() async {
    try {
      await _postsBox.clear();
      print('✅ Postlar keshi tozalandi');
    } catch (e) {
      print('❌ Xatolik: $e');
    }
  }
}
