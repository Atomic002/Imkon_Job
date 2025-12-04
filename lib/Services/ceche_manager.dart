import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

/// ✅ GetStorage-based Cache Manager (Hive emas!)
class AppCacheManager {
  final _storage = GetStorage();

  static const String _postsKey = 'cached_posts';
  static const String _lastUpdateKey = 'posts_last_update';
  static const Duration _cacheExpiry = Duration(hours: 1);

  /// ✅ Init metodi (GetStorage allaqachon main.dart'da init qilingan)
  Future<void> init() async {
    try {
      print('✅ CacheManager ready (using GetStorage)');
    } catch (e) {
      print('⚠️ CacheManager init warning: $e');
    }
  }

  /// ✅ Postlarni keshga saqlash
  Future<void> cachePosts(List<Map<String, dynamic>> posts) async {
    try {
      if (posts.isEmpty) {
        print('⚠️ Empty posts list - skipping cache');
        return;
      }

      // JSON string'ga aylantirish (GetStorage uchun)
      final jsonString = jsonEncode(posts);
      await _storage.write(_postsKey, jsonString);
      await _storage.write(_lastUpdateKey, DateTime.now().toIso8601String());

      print('💾 ${posts.length} ta post keshga saqlandi');
    } catch (e) {
      print('❌ Cache save error: $e');
      // Non-blocking - xato bo'lsa ham davom etamiz
    }
  }

  /// ✅ Keshdan postlarni olish
  Future<List<Map<String, dynamic>>?> getCachedPosts() async {
    try {
      // Kesh mavjudligini tekshirish
      if (!_storage.hasData(_postsKey)) {
        print('ℹ️ No cached posts found');
        return null;
      }

      // Kesh muddatini tekshirish
      final lastUpdate = _storage.read(_lastUpdateKey);
      if (lastUpdate != null) {
        final lastUpdateTime = DateTime.parse(lastUpdate as String);
        final now = DateTime.now();

        if (now.difference(lastUpdateTime) > _cacheExpiry) {
          print(
            '⏰ Cache expired (${now.difference(lastUpdateTime).inMinutes} minutes old)',
          );
          return null;
        }
      }

      // Keshdan o'qish
      final cachedData = _storage.read(_postsKey);
      if (cachedData == null) {
        print('ℹ️ Cached data is null');
        return null;
      }

      // JSON parse qilish
      final List<dynamic> decoded = jsonDecode(cachedData as String);
      final posts = decoded.map((e) => e as Map<String, dynamic>).toList();

      print('✅ ${posts.length} ta post keshdan yuklandi');
      return posts;
    } catch (e) {
      print('❌ Cache read error: $e');
      // Xato bo'lsa null qaytaramiz
      return null;
    }
  }

  /// ✅ Keshni tozalash
  Future<void> clearCache() async {
    try {
      await _storage.remove(_postsKey);
      await _storage.remove(_lastUpdateKey);
      print('🗑️ Cache cleared');
    } catch (e) {
      print('❌ Cache clear error: $e');
    }
  }

  /// ✅ Barcha keshni tozalash
  Future<void> clearAllCache() async {
    try {
      await _storage.erase();
      print('🗑️ All cache cleared');
    } catch (e) {
      print('❌ Clear all cache error: $e');
    }
  }

  /// ✅ Rasmlarni prefetch qilish (non-blocking)
  Future<void> prefetchImages(List<String> imageUrls) async {
    if (imageUrls.isEmpty) return;

    print('🖼️ Prefetching ${imageUrls.length} images...');

    int successCount = 0;
    int errorCount = 0;

    // Parallel prefetch (async)
    final futures = imageUrls.take(10).map((url) async {
      try {
        final response = await http
            .head(Uri.parse(url), headers: {'Connection': 'keep-alive'})
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          successCount++;
        } else {
          errorCount++;
        }
      } catch (e) {
        errorCount++;
      }
    });

    await Future.wait(futures);

    if (successCount > 0) {
      print('✅ $successCount ta rasm prefetch qilindi');
    }
    if (errorCount > 0) {
      print('⚠️ $errorCount ta rasm prefetch qilinmadi');
    }
  }

  /// ✅ Kesh ma'lumotlarini olish
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final hasCache = _storage.hasData(_postsKey);
      final lastUpdate = _storage.read(_lastUpdateKey);

      if (!hasCache) {
        return {
          'has_cache': false,
          'last_update': null,
          'age_minutes': null,
          'is_expired': true,
        };
      }

      DateTime? lastUpdateTime;
      int? ageMinutes;
      bool isExpired = true;

      if (lastUpdate != null) {
        lastUpdateTime = DateTime.parse(lastUpdate as String);
        ageMinutes = DateTime.now().difference(lastUpdateTime).inMinutes;
        isExpired = ageMinutes > _cacheExpiry.inMinutes;
      }

      return {
        'has_cache': true,
        'last_update': lastUpdateTime?.toIso8601String(),
        'age_minutes': ageMinutes,
        'is_expired': isExpired,
      };
    } catch (e) {
      print('❌ Get cache info error: $e');
      return {'has_cache': false, 'error': e.toString()};
    }
  }
}
