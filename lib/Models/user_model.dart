class UserModel {
  final String id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? bio;
  final String? location;
  final String? profilePhotoUrl;
  final String userType;
  final bool isActive;
  final double rating;
  final String? createdAt;
  final String? updatedAt;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.bio,
    this.location,
    this.profilePhotoUrl,
    required this.userType,
    this.fcmToken,
    required this.isActive,
    required this.rating,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? username;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      bio: json['bio'],
      location: json['location'],
      profilePhotoUrl: json['profile_photo_url'],
      userType: json['user_type'] ?? 'job_seeker',
      isActive: json['is_active'] ?? true,
      rating: (json['rating'] is int)
          ? (json['rating'] as int).toDouble()
          : (json['rating'] ?? 0.0).toDouble(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      fcmToken: json['fcm_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "username": username,
      "first_name": firstName,
      "last_name": lastName,
      "phone_number": phoneNumber,
      "bio": bio,
      "location": location,
      "profile_photo_url": profilePhotoUrl,
      "user_type": userType,
      "is_active": isActive,
      "rating": rating,
      "created_at": createdAt,
      "updated_at": updatedAt,
      "fcm_token": fcmToken,
    };
  }
}
