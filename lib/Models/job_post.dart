class JobPost {
  final String id;
  final String title;
  final String description;
  final String company;
  final String? companyLogo;
  final String location;
  final int salaryMin;
  final int salaryMax;
  int shares;
  int views;
  int likes;
  final int? categoryIdNum;
  final int? subCategoryId;
  final String userId;
  final List<String>? imageUrls;
  final DateTime createdAt;
  final String? requirementsMain;
  final String? requirementsBasic;
  final String status;
  final bool isActive;
  final int? sharesCount;
  final int? durationDays;
  final String? postType;
  final String? salaryType;
  final String? skills;
  final String? experience;
  final String? phoneNumber;
  // ✅ KATEGORIYA VA SUB-KATEGORIYA NOMLARI
  final String? categoryName;
  final String? subCategoryName;

  JobPost({
    required this.id,
    required this.title,
    required this.description,
    required this.company,
    this.companyLogo,
    required this.location,
    required this.salaryMin,
    required this.salaryMax,
    required this.shares,
    required this.views,
    required this.likes,
    this.categoryIdNum,
    this.subCategoryId,
    required this.userId,
    this.imageUrls,
    required this.createdAt,
    this.requirementsMain,
    this.requirementsBasic,
    this.status = 'approved',
    this.isActive = true,
    this.sharesCount,
    this.durationDays,
    this.postType,
    this.phoneNumber,
    this.salaryType,
    this.skills,
    this.experience,
    this.categoryName,
    this.subCategoryName,
  });

  // ✅ FROM JSON - MUKAMMAL VERSIYA
  factory JobPost.fromJson(Map<String, dynamic> json) {
    // 🖼️ Images - To'g'ri formatlash
    List<String>? imageUrls;
    if (json['post_images'] != null && json['post_images'] is List) {
      imageUrls = (json['post_images'] as List)
          .map((img) {
            if (img == null || img is! Map) return '';
            final url = img['image_url']?.toString() ?? '';
            if (url.isEmpty) return '';

            if (url.startsWith('http')) return url;
            return 'https://lebttvzssavbjkoumebf.supabase.co/storage/v1/object/public/post-images/$url';
          })
          .where((url) => url.isNotEmpty)
          .toList();

      if (imageUrls.isEmpty) imageUrls = null;
    }

    // 👤 User info - Xavfsiz olish
    String companyName = 'Kompaniya';
    String? companyLogo;

    if (json['users'] != null && json['users'] is Map) {
      final user = json['users'] as Map<String, dynamic>;
      final firstName = user['first_name']?.toString().trim() ?? '';
      final lastName = user['last_name']?.toString().trim() ?? '';
      final username = user['username']?.toString().trim() ?? '';

      companyName = '$firstName $lastName'.trim();
      if (companyName.isEmpty && username.isNotEmpty) {
        companyName = username;
      }
      if (companyName.isEmpty) {
        companyName = 'Kompaniya';
      }

      companyLogo = user['profile_photo_url']?.toString();
      if (companyLogo != null &&
          companyLogo.isNotEmpty &&
          !companyLogo.startsWith('http')) {
        companyLogo =
            'https://lebttvzssavbjkoumebf.supabase.co/storage/v1/object/public/profile_images/$companyLogo';
      }
    }

    // 📂 KATEGORIYA NOMI - Xavfsiz olish
    String? categoryName;
    if (json['categories'] != null) {
      if (json['categories'] is Map) {
        final catMap = json['categories'] as Map<String, dynamic>;
        categoryName = catMap['name']?.toString();
      } else if (json['categories'] is String) {
        categoryName = json['categories'] as String;
      }
    }

    // 🏷️ SUB-KATEGORIYA NOMI - MUKAMMAL XAVFSIZ OLISH
    String? subCategoryName;
    if (json['sub_categories'] != null) {
      if (json['sub_categories'] is Map) {
        final subCatMap = json['sub_categories'] as Map<String, dynamic>;
        subCategoryName = subCatMap['name']?.toString();
      } else if (json['sub_categories'] is String) {
        subCategoryName = json['sub_categories'] as String;
      }
    }

    // 🐛 DEBUG - Agar kerak bo'lsa commentdan chiqaring
    // print('📊 Category: $categoryName, Sub: $subCategoryName');
    // print('🔍 Raw sub_categories: ${json['sub_categories']}');

    return JobPost(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Sarlavha yo\'q',
      description: json['description']?.toString() ?? '',
      company: companyName,
      companyLogo: companyLogo,
      location: json['location']?.toString() ?? 'Joylashuv ko\'rsatilmagan',
      salaryMin: _parseInt(json['salary_min']),
      salaryMax: _parseInt(json['salary_max']),
      views: _parseInt(json['views_count']),
      likes: _parseInt(json['likes_count']),
      categoryIdNum: _parseInt(json['category_id']),
      subCategoryId: _parseInt(json['sub_category_id']),
      userId: json['user_id']?.toString() ?? '',
      imageUrls: imageUrls,
      createdAt: _parseDateTime(json['created_at']),
      requirementsMain: json['requirements_main']?.toString(),
      requirementsBasic: json['requirements_basic']?.toString(),
      status: json['status']?.toString() ?? 'approved',
      phoneNumber: json['phone_number'] as String?,
      isActive: json['is_active'] == true,
      sharesCount: _parseInt(json['shares_count']),
      durationDays: _parseInt(json['duration_days']),
      postType: json['post_type']?.toString(),
      salaryType: json['salary_type']?.toString(),
      skills: json['skills']?.toString(),
      experience: json['experience']?.toString(),
      categoryName: categoryName,
      subCategoryName: subCategoryName,
      shares: json['shares_count'] ?? 0,
    );
  }

  // 🛠️ HELPER METODLAR
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // ✅ TO JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'views_count': views,
      'likes_count': likes,
      'category_id': categoryIdNum,
      'sub_category_id': subCategoryId,
      'user_id': userId,
      'requirements_main': requirementsMain,
      'requirements_basic': requirementsBasic,
      'status': status,
      'is_active': isActive,
      'shares_count': sharesCount,
      'duration_days': durationDays,
      'created_at': createdAt.toIso8601String(),
      'post_type': postType,
      'salary_type': salaryType,
      'skills': skills,
      'phone_number': phoneNumber,
      'experience': experience,
    };
  }

  // ✅ COPY WITH
  JobPost copyWith({
    String? id,
    String? title,
    String? description,
    String? company,
    String? companyLogo,
    String? location,
    int? salaryMin,
    int? salaryMax,
    int? views,
    int? likes,
    int? categoryIdNum,
    int? subCategoryId,
    String? userId,
    List<String>? imageUrls,
    DateTime? createdAt,
    String? requirementsMain,
    String? requirementsBasic,
    String? status,
    bool? isActive,
    int? sharesCount,
    int? durationDays,
    String? postType,
    String? salaryType,
    String? skills,
    String? experience,
    String? categoryName,
    String? subCategoryName,
  }) {
    return JobPost(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      company: company ?? this.company,
      companyLogo: companyLogo ?? this.companyLogo,
      location: location ?? this.location,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      categoryIdNum: categoryIdNum ?? this.categoryIdNum,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      userId: userId ?? this.userId,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      requirementsMain: requirementsMain ?? this.requirementsMain,
      requirementsBasic: requirementsBasic ?? this.requirementsBasic,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      sharesCount: sharesCount ?? this.sharesCount,
      durationDays: durationDays ?? this.durationDays,
      postType: postType ?? this.postType,
      salaryType: salaryType ?? this.salaryType,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      categoryName: categoryName ?? this.categoryName,
      subCategoryName: subCategoryName ?? this.subCategoryName,
      shares: shares,
    );
  }

  // ✅ KATEGORIYA VA SUB-KATEGORIYA DISPLAY - MUKAMMAL
  String getCategoryDisplay() {
    // 1. Agar ikkala nom ham mavjud bo'lsa
    if (categoryName != null && categoryName!.isNotEmpty) {
      if (subCategoryName != null && subCategoryName!.isNotEmpty) {
        return '$categoryName • $subCategoryName';
      }
      return categoryName!;
    }

    // 2. Fallback - ID bo'yicha
    final catName = getCategoryName(categoryIdNum);
    if (subCategoryId != null && subCategoryId! > 0) {
      final subName = _getSubCategoryFallback(categoryIdNum, subCategoryId);
      if (subName.isNotEmpty) {
        return '$catName • $subName';
      }
    }

    return catName;
  }

  // 🔄 Sub-kategoriya fallback (agar database dan kelmasa)
  String _getSubCategoryFallback(int? catId, int? subId) {
    if (catId == null || subId == null) return '';

    // IT (1)
    if (catId == 1) {
      final subs = {
        1: 'Web Dasturlash',
        2: 'Mobile Dasturlash',
        3: 'Backend',
        4: 'DevOps',
        5: 'Data Science',
      };
      return subs[subId] ?? '';
    }

    // Qurilish (2)
    if (catId == 2) {
      final subs = {
        1: 'Arxitektura',
        2: 'Qurilish ustasi',
        3: 'Elektrik',
        4: 'Sanitariya',
      };
      return subs[subId] ?? '';
    }

    // Boshqa kategoriyalar...
    return '';
  }

  // ✅ SALARY RANGE
  String getSalaryRange() {
    if (salaryMin == 0 && salaryMax == 0) {
      return 'Kelishiladi';
    }

    if (salaryMin == 0) {
      return '${_formatMoney(salaryMax)} gacha';
    }

    if (salaryMax == 0) {
      return '${_formatMoney(salaryMin)} dan';
    }

    if (salaryMin == salaryMax) {
      return _formatMoney(salaryMin);
    }

    return '${_formatMoney(salaryMin)} - ${_formatMoney(salaryMax)}';
  }

  // ✅ FORMAT MONEY - Yaxshilangan
  String _formatMoney(int amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      final formatted = millions.toStringAsFixed(
        millions.truncateToDouble() == millions ? 0 : 1,
      );
      return '$formatted mln so\'m';
    }

    if (amount >= 1000) {
      final thousands = amount / 1000;
      final formatted = thousands.toStringAsFixed(
        thousands.truncateToDouble() == thousands ? 0 : 1,
      );
      return '$formatted ming so\'m';
    }

    return '$amount so\'m';
  }

  // ✅ CATEGORY NAME
  String getCategoryName(int? catId) {
    if (categoryName != null && categoryName!.isNotEmpty) {
      return categoryName!;
    }

    if (catId == null) return 'Boshqa';

    final categories = {
      1: 'IT va Dasturlash',
      2: 'Qurilish',
      3: 'Ta\'lim',
      4: 'Xizmat ko\'rsatish',
      5: 'Transport',
      6: 'Sog\'liqni saqlash',
      7: 'Savdo',
      8: 'Marketing',
      9: 'Dizayn',
      10: 'Moliya',
    };

    return categories[catId] ?? 'Boshqa';
  }

  // ✅ CATEGORY EMOJI
  String getCategoryEmoji(int? catId) {
    if (catId == null) return '📁';

    final emojis = {
      1: '💻',
      2: '🏗️',
      3: '📚',
      4: '🛎️',
      5: '🚗',
      6: '🏥',
      7: '🛒',
      8: '📊',
      9: '🎨',
      10: '💰',
    };

    return emojis[catId] ?? '📁';
  }

  // ✅ IS NEW
  bool get isNew {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays < 3;
  }

  // ✅ FORMATTED DATE
  String getFormattedDate() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Hozir';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} daqiqa oldin';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} soat oldin';
    } else if (difference.inDays == 1) {
      return 'Kecha';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} kun oldin';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks hafta oldin';
    } else {
      return '${createdAt.day}.${createdAt.month}.${createdAt.year}';
    }
  }

  // ✅ IS EXPIRED
  bool get isExpired {
    if (durationDays == null) return false;
    final expiryDate = createdAt.add(Duration(days: durationDays!));
    return DateTime.now().isAfter(expiryDate);
  }

  // ✅ DAYS REMAINING
  int? get daysRemaining {
    if (durationDays == null) return null;
    final expiryDate = createdAt.add(Duration(days: durationDays!));
    final difference = expiryDate.difference(DateTime.now());
    return difference.inDays >= 0 ? difference.inDays : 0;
  }

  // ✅ HAS SALARY
  bool get hasSalary => salaryMin > 0 || salaryMax > 0;

  // ✅ HAS IMAGES
  bool get hasImages => imageUrls != null && imageUrls!.isNotEmpty;

  @override
  String toString() {
    return 'JobPost{id: $id, title: $title, company: $company, postType: $postType, category: $categoryName, subCategory: $subCategoryName}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobPost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
