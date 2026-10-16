class TimeSlot {
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final String? bookingId;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.bookingId,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      bookingId: json['bookingId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
      'bookingId': bookingId,
    };
  }
}

class WorkingHours {
  final String day; // 'monday', 'tuesday', etc.
  final String startTime;
  final String endTime;
  final bool isAvailable;

  WorkingHours({
    required this.day,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      day: json['day'] ?? '',
      startTime: json['startTime'] ?? '09:00',
      endTime: json['endTime'] ?? '17:00',
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
    };
  }
}

class AvailabilityModel {
  final String id;
  final String providerId;
  final DateTime date;
  final List<TimeSlot> timeSlots;
  final bool isAvailable;
  final String note;
  final List<WorkingHours>? workingHours;
  final String? blockReason; // For blocked dates (holidays, vacation)
  final DateTime createdAt;
  final DateTime updatedAt;

  AvailabilityModel({
    required this.id,
    required this.providerId,
    required this.date,
    required this.timeSlots,
    required this.isAvailable,
    required this.note,
    this.workingHours,
    this.blockReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
      id: json['_id']?.toString() ?? '',
      providerId: json['provider']?.toString() ?? '',
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      timeSlots: (json['timeSlots'] as List?)
          ?.map((slot) => TimeSlot.fromJson(slot))
          .toList() ?? [],
      isAvailable: json['isAvailable'] ?? true,
      note: json['note'] ?? '',
      workingHours: (json['workingHours'] as List?)
          ?.map((hours) => WorkingHours.fromJson(hours))
          .toList(),
      blockReason: json['blockReason'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'provider': providerId,
      'date': date.toIso8601String(),
      'timeSlots': timeSlots.map((slot) => slot.toJson()).toList(),
      'isAvailable': isAvailable,
      'note': note,
      'workingHours': workingHours?.map((hours) => hours.toJson()).toList(),
      'blockReason': blockReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  List<TimeSlot> get availableSlots => 
      timeSlots.where((slot) => slot.isAvailable).toList();
  
  List<TimeSlot> get bookedSlots => 
      timeSlots.where((slot) => !slot.isAvailable).toList();
}