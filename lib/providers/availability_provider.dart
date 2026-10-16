import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/availability_model.dart';
import '../services/availability_service.dart';

class AvailabilityState {
  final bool isLoading;
  final String? errorMessage;
  final List<AvailabilityModel> availability;
  final AvailabilityModel? selectedAvailability;

  AvailabilityState({
    this.isLoading = false,
    this.errorMessage,
    this.availability = const [],
    this.selectedAvailability,
  });

  AvailabilityState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<AvailabilityModel>? availability,
    AvailabilityModel? selectedAvailability,
  }) {
    return AvailabilityState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      availability: availability ?? this.availability,
      selectedAvailability: selectedAvailability ?? this.selectedAvailability,
    );
  }
}

class AvailabilityNotifier extends Notifier<AvailabilityState> {
  late AvailabilityService _availabilityService;

  @override
  AvailabilityState build() {
    _availabilityService = ref.watch(availabilityServiceProvider);
    return AvailabilityState();
  }

  Future<bool> createAvailability({
    required String date,
    required List<Map<String, dynamic>> timeSlots,
    String? note,
    String? blockReason,
    List<Map<String, dynamic>>? workingHours,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _availabilityService.createAvailability(
        date: date,
        timeSlots: timeSlots,
        note: note,
        blockReason: blockReason,
        workingHours: workingHours,
      );

      if (result['success']) {
        final newAvailability = result['availability'] as AvailabilityModel;
        state = state.copyWith(
          isLoading: false,
          availability: [...state.availability, newAvailability],
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error creating availability: $e',
      );
      return false;
    }
  }

  Future<bool> updateAvailability({
    required String availabilityId,
    List<Map<String, dynamic>>? timeSlots,
    bool? isAvailable,
    String? note,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _availabilityService.updateAvailability(
        availabilityId: availabilityId,
        timeSlots: timeSlots,
        isAvailable: isAvailable,
        note: note,
      );

      if (result['success']) {
        final updatedAvailability = result['availability'] as AvailabilityModel;
        final updatedList = state.availability.map((avail) {
          return avail.id == availabilityId ? updatedAvailability : avail;
        }).toList();

        state = state.copyWith(
          isLoading: false,
          availability: updatedList,
          selectedAvailability: updatedAvailability,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error updating availability: $e',
      );
      return false;
    }
  }

  Future<bool> getAvailability({
    required String providerId,
    required String startDate,
    required String endDate,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _availabilityService.getAvailability(
        providerId: providerId,
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success']) {
        state = state.copyWith(
          isLoading: false,
          availability: result['availability'],
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error getting availability: $e',
      );
      return false;
    }
  }

  Future<bool> getMyAvailability({
    required String startDate,
    required String endDate,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _availabilityService.getMyAvailability(
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success']) {
        state = state.copyWith(
          isLoading: false,
          availability: result['availability'],
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error getting availability: $e',
      );
      return false;
    }
  }

  Future<bool> deleteAvailability(String availabilityId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _availabilityService.deleteAvailability(availabilityId);

      if (result['success']) {
        final updatedList = state.availability
            .where((avail) => avail.id != availabilityId)
            .toList();

        state = state.copyWith(
          isLoading: false,
          availability: updatedList,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error deleting availability: $e',
      );
      return false;
    }
  }

  void selectAvailability(AvailabilityModel availability) {
    state = state.copyWith(selectedAvailability: availability);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<bool> checkBookingConflicts({
    required String providerId,
    required String date,
    required List<Map<String, dynamic>> newTimeSlots,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _availabilityService.checkBookingConflicts(
        providerId: providerId,
        date: date,
        newTimeSlots: newTimeSlots,
      );

      if (result['success']) {
        state = state.copyWith(isLoading: false);
        return result['hasConflicts'] ?? false;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error checking conflicts: $e',
      );
      return false;
    }
  }
}

final availabilityServiceProvider = Provider<AvailabilityService>((ref) {
  return AvailabilityService();
});

final availabilityProvider = NotifierProvider<AvailabilityNotifier, AvailabilityState>(AvailabilityNotifier.new);