class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? bio;
  final String? location;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.bio,
    this.location,
    this.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      role: json['role'],
      bio: json['bio'],
      location: json['location'],
      profileImageUrl: json['profile_image_url'],
    );
  }
}