import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../utils/helpers.dart';

class BookingState {
  final List<BookingModel> bookings;
  final bool isLoading;
  final String? errorMessage;
  final BookingModel? currentBooking;

  BookingState({
    this.bookings = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentBooking,
  });

  BookingState copyWith({
    List<BookingModel>? bookings,
    bool? isLoading,
    String? errorMessage,
    BookingModel? currentBooking,
  }) {
    return BookingState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentBooking: currentBooking ?? this.currentBooking,
    );
  }
}

class BookingNotifier extends Notifier<BookingState> {
  final BookingService _bookingService = BookingService();

  @override
  BookingState build() => BookingState();

  Future<void> loadBookings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final bookings = await _bookingService.getMyBookings();
      
      // 🔥 Update currentBooking if it exists in the refreshed list
      BookingModel? updatedCurrent = state.currentBooking;
      if (updatedCurrent != null) {
        try {
          updatedCurrent = bookings.firstWhere((b) => b.id == updatedCurrent!.id);
        } catch (_) {}
      }

      state = state.copyWith(
        bookings: bookings, 
        currentBooking: updatedCurrent,
        isLoading: false
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: cleanError(e));
    }
  }

  Future<bool> createBooking({
    required String provider,
    required String categoryName,
    required String bookingDate,
    required String address,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _bookingService.createBooking(
        provider: provider,
        categoryName: categoryName,
        bookingDate: bookingDate,
        address: address,
      );
      await loadBookings();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: cleanError(e));
      return false;
    }
  }

  // 🔥 UPDATED NOTIFIER TO PASS SECURE COMPLETION OTP CODES TO BACKEND
  Future<bool> updateBookingStatus({
    required String bookingId,
    required String status,
    String? otp, // New optional parameter added
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _bookingService.updateBookingStatus(
        bookingId: bookingId,
        status: status,
        otp: otp, // Forwarded safely to HTTP service handler
      );
      state = state.copyWith(
        bookings: state.bookings
            .map((item) => item.id == bookingId ? updated : item)
            .toList(),
        currentBooking: updated,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: cleanError(e));
      return false;
    }
  }

  void setCurrentBooking(BookingModel booking) {
    state = state.copyWith(currentBooking: booking);
  }

  /// Real-time In-Memory State Updates from Socket Events (Zero HTTP Overhead)
  void addOrUpdateBookingInState(BookingModel booking) {
    if (booking.id.isEmpty) return;

    final targetId = booking.id.trim();
    final existingIndex =
        state.bookings.indexWhere((b) => b.id.trim() == targetId);
    List<BookingModel> updatedList;

    if (existingIndex >= 0) {
      // Update existing booking item in-place
      updatedList = List.from(state.bookings);
      updatedList[existingIndex] = booking;
    } else {
      // Prepend newly created booking
      updatedList = [booking, ...state.bookings];
    }

    BookingModel? updatedCurrent = state.currentBooking;
    if (updatedCurrent != null && updatedCurrent.id.trim() == targetId) {
      updatedCurrent = booking;
    }

    state = state.copyWith(
      bookings: updatedList,
      currentBooking: updatedCurrent,
    );
  }
}

final bookingProvider =
    NotifierProvider<BookingNotifier, BookingState>(BookingNotifier.new);
