class PostModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String salary;
  final String companyName;
  final String? companyLogo;
  final String userId;
  final int likes;
  final int views;
  final DateTime createdAt;
  final List<String>? imageUrls;
  final String? videoUrl;

  PostModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.salary,
    required this.companyName,
    this.companyLogo,
    required this.userId,
    this.likes = 0,
    this.views = 0,
    required this.createdAt,
    this.imageUrls,
    this.videoUrl,
  });

  // Factory constructor - Firestore dan ma'lumot olish
  factory PostModel.fromFirestore(doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PostModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'other',
      location: data['location'] ?? 'Belgilanmagan',
      salary: data['salary'] ?? 'Kelishiladi',
      companyName: data['companyName'] ?? '',
      companyLogo: data['companyLogo'],
      userId: data['userId'] ?? '',
      likes: data['likes'] ?? 0,
      views: data['views'] ?? 0,
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : null,
      videoUrl: data['videoUrl'],
      createdAt: DateTime(data['createdAt'].toDate()),
    );
  }

  get Timestamp => null;

  // Firestore ga saqlash uchun Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'salary': salary,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'userId': userId,
      'likes': likes,
      'views': views,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
    };
  }

  // CopyWith method - immutable object uchun
  PostModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    String? salary,
    String? companyName,
    String? companyLogo,
    String? userId,
    int? likes,
    int? views,
    DateTime? createdAt,
    List<String>? imageUrls,
    String? videoUrl,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      salary: salary ?? this.salary,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      userId: userId ?? this.userId,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      createdAt: createdAt ?? this.createdAt,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}

class Timestamp {}
