import '../models/booking_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class BookingService {
  final ApiService _api = ApiService();

  Future<BookingModel> createBooking({
    required String provider,
    required String categoryName,
    required String bookingDate,
    required String address,
  }) async {
    final response = await _api.post(ApiConstants.bookings, {
      'provider': provider,
      'categoryName': categoryName,
      'bookingDate': bookingDate,
      'address': address,
    });
    return BookingModel.fromJson(asMap(response));
  }

  Future<List<BookingModel>> getMyBookings() async {
    final response = await _api.get(ApiConstants.bookings);
    if (response is! List) return [];
    return response.map((item) => BookingModel.fromJson(asMap(item))).toList();
  }

  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required String status,
    String? otp, // 🔥 Added option for secure clearance values
  }) async {
    final body = <String, dynamic>{
      'status': status,
      if (otp != null && otp.isNotEmpty) 'otp': otp,
    };

    final response = await _api.put(
      '${ApiConstants.bookings}/$bookingId/status',
      body,
    );
    return BookingModel.fromJson(asMap(response));
  }
}
