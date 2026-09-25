class ReviewModel {
  final String id;
  final String customerName;
  final String customerImage;
  final int rating;
  final String comment;

  ReviewModel({
    required this.id,
    required this.customerName,
    required this.customerImage,
    required this.rating,
    required this.comment,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    String name = 'Customer';
    String image = '';
    if (json['customer'] is Map) {
      name = json['customer']['name'] ?? 'Customer';
      image = json['customer']['profileImage'] ?? '';
    }

    return ReviewModel(
      id: json['_id']?.toString() ?? '',
      customerName: name,
      customerImage: image,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] ?? '',
    );
  }
}
