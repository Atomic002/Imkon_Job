class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? bio;
  final String? profilePhotoUrl;
  final String userType;
  final bool isEmailVerified;
  final String? location;
  final double? rating;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.bio,
    this.profilePhotoUrl,
    required this.userType,
    required this.isEmailVerified,
    this.location,
    this.rating,
    this.isActive = true,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      email: json['email'],
      bio: json['bio'],
      profilePhotoUrl: json['profile_photo_url'],
      userType: json['user_type'],
      isEmailVerified: json['is_email_verified'] ?? false,
      location: json['location'],
      rating: (json['rating'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'bio': bio,
      'profile_photo_url': profilePhotoUrl,
      'user_type': userType,
      'is_email_verified': isEmailVerified,
      'location': location,
      'rating': rating,
      'is_active': isActive,
    };
  }

  String get fullName => '$firstName $lastName';
}
