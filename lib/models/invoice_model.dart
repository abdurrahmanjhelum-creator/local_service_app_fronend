class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String bookingId;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String providerId;
  final String providerName;
  final String providerEmail;
  final String providerPhone;
  final String serviceName;
  final String serviceCategory;
  final double amount;
  final String currency;
  final String status;
  final DateTime bookingDate;
  final String address;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? paymentId;
  final String? transactionId;
  final double? taxAmount;
  final double? discountAmount;
  final double? totalAmount;
  final String? notes;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.providerId,
    required this.providerName,
    required this.providerEmail,
    required this.providerPhone,
    required this.serviceName,
    required this.serviceCategory,
    required this.amount,
    required this.currency,
    required this.status,
    required this.bookingDate,
    required this.address,
    required this.createdAt,
    this.paidAt,
    this.paymentMethod,
    this.paymentId,
    this.transactionId,
    this.taxAmount,
    this.discountAmount,
    this.totalAmount,
    this.notes,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['_id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      providerId: json['providerId']?.toString() ?? '',
      providerName: json['providerName'] ?? '',
      providerEmail: json['providerEmail'] ?? '',
      providerPhone: json['providerPhone'] ?? '',
      serviceName: json['serviceName'] ?? '',
      serviceCategory: json['serviceCategory'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'pending',
      bookingDate: json['bookingDate'] != null 
          ? DateTime.parse(json['bookingDate']) 
          : DateTime.now(),
      address: json['address'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      paidAt: json['paidAt'] != null 
          ? DateTime.parse(json['paidAt']) 
          : null,
      paymentMethod: json['paymentMethod'],
      paymentId: json['paymentId'],
      transactionId: json['transactionId'],
      taxAmount: (json['taxAmount'] as num?)?.toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'invoiceNumber': invoiceNumber,
      'bookingId': bookingId,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'providerId': providerId,
      'providerName': providerName,
      'providerEmail': providerEmail,
      'providerPhone': providerPhone,
      'serviceName': serviceName,
      'serviceCategory': serviceCategory,
      'amount': amount,
      'currency': currency,
      'status': status,
      'bookingDate': bookingDate.toIso8601String(),
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'transactionId': transactionId,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'notes': notes,
    };
  }

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';
}