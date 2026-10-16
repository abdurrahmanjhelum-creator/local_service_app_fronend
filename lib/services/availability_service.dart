import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../utils/token_manager.dart';
import '../models/availability_model.dart';

class AvailabilityService {
  final String _baseUrl = ApiConstants.baseUrl;

  // Create availability for a specific date
  Future<Map<String, dynamic>> createAvailability({
    required String date,
    required List<Map<String, dynamic>> timeSlots,
    String? note,
    String? blockReason,
    List<Map<String, dynamic>>? workingHours,
  }) async {
    try {
      final token = await TokenManager.getToken();
      final body = <String, dynamic>{
        'date': date,
        'timeSlots': timeSlots,
      };
      
      if (note != null) body['note'] = note;
      if (blockReason != null) body['blockReason'] = blockReason;
      if (workingHours != null) body['workingHours'] = workingHours;

      final response = await http.post(
        Uri.parse('$_baseUrl/availability'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'availability': AvailabilityModel.fromJson(data),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to create availability',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating availability: $e',
      };
    }
  }

  // Update availability for a specific date
  Future<Map<String, dynamic>> updateAvailability({
    required String availabilityId,
    List<Map<String, dynamic>>? timeSlots,
    bool? isAvailable,
    String? note,
  }) async {
    try {
      final token = await TokenManager.getToken();
      final body = <String, dynamic>{};
      
      if (timeSlots != null) body['timeSlots'] = timeSlots;
      if (isAvailable != null) body['isAvailable'] = isAvailable;
      if (note != null) body['note'] = note;

      final response = await http.put(
        Uri.parse('$_baseUrl/availability/$availabilityId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'availability': AvailabilityModel.fromJson(data),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update availability',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating availability: $e',
      };
    }
  }

  // Get availability for a date range
  Future<Map<String, dynamic>> getAvailability({
    required String providerId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/availability')
            .replace(queryParameters: {
          'providerId': providerId,
          'startDate': startDate,
          'endDate': endDate,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final availability = (data as List)
            .map((json) => AvailabilityModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'availability': availability,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to get availability',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error getting availability: $e',
      };
    }
  }

  // Get provider's own availability
  Future<Map<String, dynamic>> getMyAvailability({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final token = await TokenManager.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/availability/my')
            .replace(queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final availability = (data as List)
            .map((json) => AvailabilityModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'availability': availability,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to get availability',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error getting availability: $e',
      };
    }
  }

  // Delete availability for a specific date
  Future<Map<String, dynamic>> deleteAvailability(String availabilityId) async {
    try {
      final token = await TokenManager.getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/availability/$availabilityId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to delete availability',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting availability: $e',
      };
    }
  }

  // Check if a specific time slot is available
  Future<Map<String, dynamic>> checkSlotAvailability({
    required String providerId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/availability/check')
            .replace(queryParameters: {
          'providerId': providerId,
          'date': date,
          'startTime': startTime,
          'endTime': endTime,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'isAvailable': data['isAvailable'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to check slot availability',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking slot availability: $e',
      };
    }
  }

  // Advanced booking conflict detection
  Future<Map<String, dynamic>> checkBookingConflicts({
    required String providerId,
    required String date,
    required List<Map<String, dynamic>> newTimeSlots,
  }) async {
    try {
      final token = await TokenManager.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/availability/check-conflicts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'providerId': providerId,
          'date': date,
          'timeSlots': newTimeSlots,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'hasConflicts': data['hasConflicts'] ?? false,
          'conflicts': data['conflicts'] ?? [],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to check conflicts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking conflicts: $e',
      };
    }
  }
}