class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String profileImage;
  final String category;
  final double priceStarting;
  final int experienceYears;
  final bool isAvailable;
  final double rating;
  final String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    this.profileImage = '',
    this.category = '',
    this.priceStarting = 0,
    this.experienceYears = 0,
    this.isAvailable = true,
    this.rating = 5,
    this.token,
  });

  bool get isProvider => role == 'provider';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer',
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'] ?? '',
      category: json['category'] ?? '',
      priceStarting: (json['priceStarting'] as num?)?.toDouble() ?? 0,
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 5,
      token: json['token'],
    );
  }
}
