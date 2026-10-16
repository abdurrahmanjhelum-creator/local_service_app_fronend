import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/availability_model.dart';
import '../../providers/availability_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class AvailabilityCalendarScreen extends ConsumerStatefulWidget {
  const AvailabilityCalendarScreen({super.key});

  @override
  ConsumerState<AvailabilityCalendarScreen> createState() => _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState extends ConsumerState<AvailabilityCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<TimeSlot>> _timeSlotsByDate = {};
  final Map<String, WorkingHours> _workingHours = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAvailabilityForMonth();
    _initializeWorkingHours();
  }

  void _initializeWorkingHours() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (final day in days) {
      _workingHours[day] = WorkingHours(
        day: day,
        startTime: '09:00',
        endTime: '17:00',
        isAvailable: day != 'sunday', // Sunday off by default
      );
    }
  }

  Future<void> _loadAvailabilityForMonth() async {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    await ref.read(availabilityProvider.notifier).getMyAvailability(
      startDate: firstDay.toIso8601String(),
      endDate: lastDay.toIso8601String(),
    );

    if (mounted) {
      setState(() {
        _timeSlotsByDate = _buildTimeSlotsMap();
      });
    }
  }

  Map<DateTime, List<TimeSlot>> _buildTimeSlotsMap() {
    final map = <DateTime, List<TimeSlot>>{};
    for (final availability in ref.read(availabilityProvider).availability) {
      final dateKey = DateTime(
        availability.date.year,
        availability.date.month,
        availability.date.day,
      );
      map[dateKey] = availability.timeSlots;
    }
    return map;
  }

  Future<void> _showTimeSlotDialog(DateTime date) async {
    final existingSlots = _timeSlotsByDate[DateTime(date.year, date.month, date.day)] ?? [];
    
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => TimeSlotDialog(
        date: date,
        existingSlots: existingSlots,
      ),
    );

    if (result != null && mounted) {
      // Check for conflicts before saving
      final user = ref.read(authProvider).user;
      if (user != null) {
        final hasConflicts = await ref.read(availabilityProvider.notifier).checkBookingConflicts(
          providerId: user.id,
          date: date.toIso8601String(),
          newTimeSlots: result,
        );

        if (hasConflicts && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Warning: Time slot conflicts detected with existing bookings'),
              backgroundColor: Colors.orange,
            ),
          );
          // Still allow saving but show warning
        }
      }

      await ref.read(availabilityProvider.notifier).createAvailability(
        date: date.toIso8601String(),
        timeSlots: result,
      );

      await _loadAvailabilityForMonth();
    }
  }

  Future<void> _showWorkingHoursDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Working Hours Configuration'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _workingHours.length,
            itemBuilder: (context, index) {
              final day = _workingHours.keys.elementAt(index);
              final hours = _workingHours[day]!;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            day[0].toUpperCase() + day.substring(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: hours.isAvailable,
                            onChanged: (value) {
                              setState(() {
                                _workingHours[day] = WorkingHours(
                                  day: day,
                                  startTime: hours.startTime,
                                  endTime: hours.endTime,
                                  isAvailable: value,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                      if (hours.isAvailable) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Start',
                                  hintText: '09:00',
                                ),
                                controller: TextEditingController(
                                  text: hours.startTime,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _workingHours[day] = WorkingHours(
                                      day: day,
                                      startTime: value,
                                      endTime: hours.endTime,
                                      isAvailable: true,
                                    );
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'End',
                                  hintText: '17:00',
                                ),
                                controller: TextEditingController(
                                  text: hours.endTime,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _workingHours[day] = WorkingHours(
                                      day: day,
                                      startTime: hours.startTime,
                                      endTime: value,
                                      isAvailable: true,
                                    );
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Working hours saved')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockDate(DateTime date) async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${date.toString().split(' ')[0]}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why do you want to block this date?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g., Holiday, Vacation, Personal',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context, reasonController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Block Date'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await ref.read(availabilityProvider.notifier).createAvailability(
        date: date.toIso8601String(),
        timeSlots: [],
        note: result,
      );
      await _loadAvailabilityForMonth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final availabilityState = ref.watch(availabilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability Calendar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule),
            onPressed: _showWorkingHoursDialog,
            tooltip: 'Working Hours',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailabilityForMonth,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: Column(
          children: [
            // Calendar
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _loadAvailabilityForMonth();
                },
                eventLoader: (day) {
                  final dateKey = DateTime(day.year, day.month, day.day);
                  return _timeSlotsByDate[dateKey] ?? [];
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle: TextStyle(color: Colors.red[700]),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Selected day info
            if (_selectedDay != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Selected: ${_selectedDay!.toString().split(' ')[0]}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _showTimeSlotDialog(_selectedDay!),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Slots'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _blockDate(_selectedDay!),
                                  icon: const Icon(Icons.block),
                                  label: const Text('Block Date'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final dateKey = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
                            final slots = _timeSlotsByDate[dateKey] ?? [];
                            if (slots.isEmpty) {
                              return const Text('No time slots set for this day');
                            } else {
                              return Column(
                                children: slots.map((slot) {
                                  return ListTile(
                                    leading: Icon(
                                      slot.isAvailable ? Icons.check_circle : Icons.cancel,
                                      color: slot.isAvailable ? Colors.green : Colors.red,
                                    ),
                                    title: Text('${slot.startTime} - ${slot.endTime}'),
                                    subtitle: slot.isAvailable 
                                        ? const Text('Available')
                                        : const Text('Booked'),
                                  );
                                }).toList(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const Spacer(),

            // Error message
            if (availabilityState.errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        availabilityState.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => ref.read(availabilityProvider.notifier).clearError(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TimeSlotDialog extends StatefulWidget {
  final DateTime date;
  final List<TimeSlot> existingSlots;

  const TimeSlotDialog({
    super.key,
    required this.date,
    required this.existingSlots,
  });

  @override
  State<TimeSlotDialog> createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends State<TimeSlotDialog> {
  final List<Map<String, dynamic>> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    // Load existing slots
    for (final slot in widget.existingSlots) {
      _timeSlots.add({
        'startTime': slot.startTime,
        'endTime': slot.endTime,
        'isAvailable': slot.isAvailable,
      });
    }
  }

  void _addTimeSlot() {
    setState(() {
      _timeSlots.add({
        'startTime': '09:00',
        'endTime': '10:00',
        'isAvailable': true,
      });
    });
  }

  void _addTimeSlotWithPreset(String startTime, String endTime) {
    setState(() {
      _timeSlots.add({
        'startTime': startTime,
        'endTime': endTime,
        'isAvailable': true,
      });
    });
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _timeSlots.removeAt(index);
    });
  }

  void _updateTimeSlot(int index, String field, String value) {
    setState(() {
      _timeSlots[index][field] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Time Slots for ${widget.date.toString().split(' ')[0]}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Add Presets
            const Text(
              'Quick Add Presets',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('30 min', () => _addTimeSlotWithPreset('09:00', '09:30')),
                _buildPresetChip('1 hour', () => _addTimeSlotWithPreset('09:00', '10:00')),
                _buildPresetChip('2 hours', () => _addTimeSlotWithPreset('09:00', '11:00')),
                _buildPresetChip('3 hours', () => _addTimeSlotWithPreset('09:00', '12:00')),
              ],
            ),
            const Divider(height: 24),
            
            // Existing Time Slots
            const Text(
              'Time Slots',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_timeSlots.length, (index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Start Time',
                                hintText: '09:00',
                              ),
                              controller: TextEditingController(
                                text: _timeSlots[index]['startTime'],
                              ),
                              onChanged: (value) => _updateTimeSlot(index, 'startTime', value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'End Time',
                                hintText: '10:00',
                              ),
                              controller: TextEditingController(
                                text: _timeSlots[index]['endTime'],
                              ),
                              onChanged: (value) => _updateTimeSlot(index, 'endTime', value),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeTimeSlot(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            ElevatedButton.icon(
              onPressed: _addTimeSlot,
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Time Slot'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_timeSlots.isNotEmpty) {
              Navigator.pop(context, _timeSlots);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}