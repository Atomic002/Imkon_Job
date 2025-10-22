class JobPost {
  final String id;
  final String title;
  final String description;
  final String company;
  final String? companyLogo;
  final String location;
  final int salaryMin;
  final int salaryMax;
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

  JobPost({
    required this.id,
    required this.title,
    required this.description,
    required this.company,
    this.companyLogo,
    required this.location,
    required this.salaryMin,
    required this.salaryMax,
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
  });

  // ✅ FROM JSON - Supabase dan kelgan ma'lumotlarni parse qilish (users bilan)
  factory JobPost.fromJson(Map<String, dynamic> json) {
    // Images listini olib olish
    List<String>? imageUrls;
    if (json['post_images'] != null && json['post_images'] is List) {
      imageUrls = (json['post_images'] as List)
          .map((img) => img['image_url'] as String)
          .toList();
    }

    // ✅ users jadvalidan ma'lumot olish (profiles emas!)
    String companyName = 'Kompaniya';
    String? companyLogo;

    if (json['users'] != null && json['users'] is Map) {
      final user = json['users'] as Map<String, dynamic>;
      final firstName = user['first_name'] as String? ?? '';
      final lastName = user['last_name'] as String? ?? '';
      final username = user['username'] as String? ?? '';

      // To'liq ismni yaratish
      companyName = '$firstName $lastName'.trim();

      // Agar ism yo'q bo'lsa, username ishlatish
      if (companyName.isEmpty && username.isNotEmpty) {
        companyName = username;
      }

      // Hali ham bo'sh bo'lsa, default qiymat
      if (companyName.isEmpty) {
        companyName = 'Kompaniya';
      }

      companyLogo = user['profile_photo_url'] as String?;
    }

    return JobPost(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Sarlavha yo\'q',
      description: json['description'] as String? ?? '',
      company: companyName,
      companyLogo: companyLogo,
      location: json['location'] as String? ?? 'Joylashuv ko\'rsatilmagan',
      salaryMin: json['salary_min'] as int? ?? 0,
      salaryMax: json['salary_max'] as int? ?? 0,
      views: json['views_count'] as int? ?? 0,
      likes: json['likes_count'] as int? ?? 0,
      categoryIdNum: json['category_id'] as int?,
      subCategoryId: json['sub_category_id'] as int?,
      userId: json['user_id'] as String? ?? '',
      imageUrls: imageUrls,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      requirementsMain: json['requirements_main'] as String?,
      requirementsBasic: json['requirements_basic'] as String?,
      status: json['status'] as String? ?? 'approved',
      isActive: json['is_active'] as bool? ?? true,
      sharesCount: json['shares_count'] as int?,
      durationDays: json['duration_days'] as int?,
    );
  }

  // ✅ TO JSON - Supabase ga yuborish uchun
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
    );
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

  // ✅ FORMAT MONEY
  String _formatMoney(int amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return '${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}M UZS';
    }

    if (amount >= 1000) {
      final thousands = amount / 1000;
      return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}K UZS';
    }

    return '$amount UZS';
  }

  // ✅ CATEGORY NAME
  String getCategoryName(int? catId) {
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

    if (difference.inMinutes < 60) {
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
  bool get hasSalary {
    return salaryMin > 0 || salaryMax > 0;
  }

  // ✅ HAS IMAGES
  bool get hasImages {
    return imageUrls != null && imageUrls!.isNotEmpty;
  }

  @override
  String toString() {
    return 'JobPost{id: $id, title: $title, company: $company, salary: ${getSalaryRange()}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobPost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
