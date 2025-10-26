class UserModel {
  final String id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? bio;
  final String? location;
  final String? profilePhotoUrl;
  final String userType;
  final bool? isEmailVerified;
  final bool? isActive;
  final double? rating;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.bio,
    this.location,
    this.profilePhotoUrl,
    required this.userType,
    this.isEmailVerified,
    this.isActive,
    this.rating,
    this.createdAt,
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
      email: json['email'],
      phoneNumber: json['phone_number'],
      bio: json['bio'],
      location: json['location'],
      profilePhotoUrl: json['profile_photo_url'],
      userType: json['user_type'] ?? 'job_seeker',
      isEmailVerified: json['is_email_verified'],
      isActive: json['is_active'],
      rating: json['rating']?.toDouble(),
      createdAt: json['created_at'],
    );
  }
}
