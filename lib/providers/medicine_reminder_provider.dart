import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants/api_config.dart';
import '../services/token_service.dart';

/// Model for a medicine reminder
class MedicineReminder {
  final String medicineId;
  final String? doseId;
  final String medicineName;
  final String dosage;
  final String time;
  final String? instruction;
  final String? notes;
  final bool isTaken;

  MedicineReminder({
    required this.medicineId,
    this.doseId,
    required this.medicineName,
    required this.dosage,
    required this.time,
    this.instruction,
    this.notes,
    required this.isTaken,
  });

  MedicineReminder copyWith({
    String? medicineId,
    String? doseId,
    String? medicineName,
    String? dosage,
    String? time,
    String? instruction,
    String? notes,
    bool? isTaken,
  }) {
    return MedicineReminder(
      medicineId: medicineId ?? this.medicineId,
      doseId: doseId ?? this.doseId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      instruction: instruction ?? this.instruction,
      notes: notes ?? this.notes,
      isTaken: isTaken ?? this.isTaken,
    );
  }

  /// Unique key for this reminder (medicineId + time)
  String get uniqueKey => '${medicineId}_$time';
}

/// State for medicine reminders
class MedicineReminderState {
  final List<MedicineReminder> reminders;
  final bool isLoading;
  final String? error;
  final String currentDate;

  MedicineReminderState({
    this.reminders = const [],
    this.isLoading = false,
    this.error,
    String? currentDate,
  }) : currentDate = currentDate ?? _getTodayDate();

  static String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  MedicineReminderState copyWith({
    List<MedicineReminder>? reminders,
    bool? isLoading,
    String? error,
    String? currentDate,
  }) {
    return MedicineReminderState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentDate: currentDate ?? this.currentDate,
    );
  }

  int get completedCount => reminders.where((r) => r.isTaken).length;
  int get totalCount => reminders.length;
  double get progressPercent => totalCount > 0 ? completedCount / totalCount : 0;
}

/// Notifier for medicine reminders
class MedicineReminderNotifier extends StateNotifier<MedicineReminderState> {
  MedicineReminderNotifier() : super(MedicineReminderState());

  final TokenService _tokenService = TokenService();

  /// Load reminders for a specific date (defaults to today)
  Future<void> loadReminders({String? date}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        state = state.copyWith(isLoading: false, error: 'Not authenticated');
        return;
      }

      final dateKey = date ?? MedicineReminderState._getTodayDate();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines/by-date?date=$dateKey'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List medicinesJson = data['data'] ?? [];
          final List<MedicineReminder> allReminders = [];

          for (var medJson in medicinesJson) {
            final medicineName = medJson['medicineName'] ?? 'Unknown Medicine';
            final dosage = medJson['dosage'] ?? '';
            final notes = medJson['notes'];
            final medicineId = medJson['_id'] ?? medJson['id'];
            final List takenHistory = medJson['takenHistory'] ?? [];

            final List doses = medJson['doses'] ?? [];
            for (var dose in doses) {
              final time = dose['time'] ?? '';
              final instruction = dose['instruction'];
              final doseId = dose['_id'] ?? dose['id'];

              // Convert dose time to 24-hour format for comparison
              final time24 = _convertTo24Hour(time);

              // Check if already taken today at this time
              final isTaken = takenHistory.any((h) {
                if (h['date'] != dateKey) return false;
                final historyTime = h['time'] ?? '';
                final historyTime24 = _convertTo24Hour(historyTime);
                return historyTime24 == time24;
              });

              allReminders.add(MedicineReminder(
                medicineId: medicineId,
                doseId: doseId,
                medicineName: medicineName,
                dosage: dosage,
                time: time,
                instruction: instruction,
                notes: notes,
                isTaken: isTaken,
              ));
            }
          }

          // Sort by time
          allReminders.sort((a, b) {
            final aTime = _parseTimeMinutes(a.time);
            final bTime = _parseTimeMinutes(b.time);
            return aTime.compareTo(bTime);
          });

          state = state.copyWith(
            reminders: allReminders,
            isLoading: false,
            currentDate: dateKey,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: data['message'] ?? 'Failed to load reminders',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch reminders (${response.statusCode})',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error: ${e.toString()}',
      );
    }
  }

  /// Mark a medicine as taken
  Future<bool> markAsTaken(MedicineReminder reminder) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) return false;

      final time24 = _convertTo24Hour(reminder.time);

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines/${reminder.medicineId}/mark-taken'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'date': state.currentDate,
          'time': time24,
        }),
      );

      if (response.statusCode == 200) {
        // Update local state immediately
        final updatedReminders = state.reminders.map((r) {
          if (r.medicineId == reminder.medicineId && r.time == reminder.time) {
            return r.copyWith(isTaken: true);
          }
          return r;
        }).toList();

        state = state.copyWith(reminders: updatedReminders);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Unmark a medicine as taken
  Future<bool> unmarkAsTaken(MedicineReminder reminder) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) return false;

      final time24 = _convertTo24Hour(reminder.time);

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines/${reminder.medicineId}/unmark-taken'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'date': state.currentDate,
          'time': time24,
        }),
      );

      if (response.statusCode == 200) {
        // Update local state immediately
        final updatedReminders = state.reminders.map((r) {
          if (r.medicineId == reminder.medicineId && r.time == reminder.time) {
            return r.copyWith(isTaken: false);
          }
          return r;
        }).toList();

        state = state.copyWith(reminders: updatedReminders);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Toggle taken status
  Future<bool> toggleTaken(MedicineReminder reminder) async {
    if (reminder.isTaken) {
      return await unmarkAsTaken(reminder);
    } else {
      return await markAsTaken(reminder);
    }
  }

  String _convertTo24Hour(String time12) {
    try {
      final trimmed = time12.trim();

      if (!trimmed.contains('AM') && !trimmed.contains('PM') &&
          !trimmed.contains('am') && !trimmed.contains('pm')) {
        final parts = trimmed.split(':');
        if (parts.length == 2) {
          return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
        }
        return trimmed;
      }

      final parts = trimmed.split(' ');
      if (parts.length != 2) return trimmed;

      final timePart = parts[0].split(':');
      final period = parts[1].toUpperCase();

      int hour = int.parse(timePart[0]);
      final minute = timePart[1];

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return '${hour.toString().padLeft(2, '0')}:$minute';
    } catch (e) {
      return time12;
    }
  }

  int _parseTimeMinutes(String time) {
    try {
      final time24 = _convertTo24Hour(time);
      final parts = time24.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }
}

/// Provider for medicine reminders (shared across all pages)
final medicineReminderProvider =
    StateNotifierProvider<MedicineReminderNotifier, MedicineReminderState>((ref) {
  return MedicineReminderNotifier();
});

/// Convenience provider for today's reminder count
final todayReminderCountProvider = Provider<int>((ref) {
  return ref.watch(medicineReminderProvider).totalCount;
});

/// Convenience provider for completed reminder count
final completedReminderCountProvider = Provider<int>((ref) {
  return ref.watch(medicineReminderProvider).completedCount;
});
