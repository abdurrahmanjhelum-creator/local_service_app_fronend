class BookingModel {
  final String id;
  final String customerId;
  final String providerId;
  final String categoryName;
  final String bookingDate;
  final String address;
  final String status;
  final String createdAt;
  final Map<String, dynamic>? customerData;
  final Map<String, dynamic>? providerData;
  
  // ======= 🚀 NEW SECURITY & REVIEW MODEL FIELDS ADDED =======
  final double bookedPrice;    // 💰 Frozen Snapshot price at booking creation time
  final String? completionOtp; // 🔒 4-digit code shown to customer for job clearance
  final bool isReviewed;       // ⭐ Flag to check if customer has already submitted a review

  BookingModel({
    required this.id,
    required this.customerId,
    required this.providerId,
    required this.categoryName,
    required this.bookingDate,
    required this.address,
    required this.status,
    required this.createdAt,
    required this.bookedPrice, 
    required this.isReviewed, 
    this.completionOtp,
    this.customerData,
    this.providerData,
  });

  String get otherName {
    return customerData?['name'] ?? providerData?['name'] ?? 'User';
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id']?.toString() ??
        json['id']?.toString() ??
        json['bookingId']?.toString() ??
        '';

    return BookingModel(
      id: rawId.trim(),
      customerId: _idFrom(json['customer']),
      providerId: _idFrom(json['provider']),
      categoryName: json['categoryName'] ?? '',
      bookingDate: json['bookingDate']?.toString() ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt']?.toString() ?? '',
      
      bookedPrice: double.tryParse(json['bookedPrice']?.toString() ?? '0') ?? 0.0,
      completionOtp: json['completionOtp']?.toString(),
      
      // 🔥 Robust Boolean Parsing Fix: Matches true, "true", 1, etc.
      isReviewed: json['isReviewed'] == true || json['isReviewed']?.toString() == 'true',
      
      customerData: _mapFrom(json['customer']),
      providerData: _mapFrom(json['provider']),
    );
  }

  static String _idFrom(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is Map) {
      return (value['_id']?.toString() ?? value['id']?.toString() ?? '').trim();
    }
    return value.toString().trim();
  }

  static Map<String, dynamic>? _mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
