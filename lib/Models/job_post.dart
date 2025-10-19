class JobPost {
  final String id;
  final String title;
  final String description;
  final String company;
  final String location;
  final String salaryMin;
  final String salaryMax;
  final int views;
  int likes;
  final String categoryId;
  final int? categoryIdNum;
  final String userId;
  final List<String>? imageUrls;
  final DateTime createdAt;

  JobPost({
    required this.id,
    required this.title,
    required this.description,
    required this.company,
    required this.location,
    required this.salaryMin,
    required this.salaryMax,
    required this.views,
    required this.likes,
    required this.categoryId,
    this.categoryIdNum,
    required this.userId,
    this.imageUrls,
    required this.createdAt,
  });

  factory JobPost.fromJson(Map<String, dynamic> json) {
    // Images listini olib olish
    List<String> imageUrls = [];
    if (json['post_images'] != null && json['post_images'] is List) {
      imageUrls = (json['post_images'] as List)
          .map((img) => img['image_url'] as String)
          .toList();
    }

    return JobPost(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Nomi yo\'q',
      description: json['description'] as String? ?? '',
      company: json['company_name'] as String? ?? 'Nomi yo\'q',
      location: json['location'] as String? ?? 'Joyi yo\'q',
      salaryMin: (json['salary_min'] ?? 0).toString(),
      salaryMax: (json['salary_max'] ?? 0).toString(),
      views: json['views_count'] as int? ?? 0,
      likes: json['likes_count'] as int? ?? 0,
      categoryId: (json['category_id'] ?? 1).toString(),
      categoryIdNum: json['category_id'] as int?,
      userId: json['user_id'] as String? ?? '',
      imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String getSalaryRange() {
    if (salaryMin == '0' || salaryMax == '0') {
      return 'Kelishiladi';
    }
    return '$salaryMin - $salaryMax UZS';
  }

  String getCategoryName(int? catId) {
    final categories = {
      1: 'IT',
      2: 'Qurilish',
      3: 'Ta\'lim',
      4: 'Xizmat',
      5: 'Transport',
    };
    return categories[catId ?? 1] ?? 'Boshqa';
  }
}
