import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

// User appointments provider
final userAppointmentsProvider = StateNotifierProvider<UserAppointmentsNotifier, AsyncValue<List<AppointmentModel>>>((ref) {
  return UserAppointmentsNotifier();
});

class UserAppointmentsNotifier extends StateNotifier<AsyncValue<List<AppointmentModel>>> {
  UserAppointmentsNotifier() : super(const AsyncValue.loading());

  Future<void> loadAppointments({String? status}) async {
    state = const AsyncValue.loading();
    
    final response = await AppointmentService.getUserAppointments(status: status);
    
    if (response['success'] == true) {
      final appointments = response['appointments'] as List<AppointmentModel>;
      state = AsyncValue.data(appointments);
    } else {
      state = AsyncValue.error(
        response['message'] ?? 'Failed to load appointments',
        StackTrace.current,
      );
    }
  }

  Future<bool> bookAppointment({
    required String doctorId,
    required String date,
    required String time,
    String? symptoms,
  }) async {
    final response = await AppointmentService.bookAppointment(
      doctorId: doctorId,
      date: date,
      time: time,
      symptoms: symptoms,
    );

    if (response['success'] == true) {
      // Reload appointments after booking
      await loadAppointments();
      return true;
    }
    
    return false;
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    final response = await AppointmentService.updateAppointmentStatus(
      appointmentId: appointmentId,
      status: 'cancelled',
    );

    if (response['success'] == true) {
      // Reload appointments
      await loadAppointments();
      return true;
    }
    
    return false;
  }
}

// Doctor appointments provider
final doctorAppointmentsProvider = StateNotifierProvider<DoctorAppointmentsNotifier, AsyncValue<List<AppointmentModel>>>((ref) {
  return DoctorAppointmentsNotifier();
});

class DoctorAppointmentsNotifier extends StateNotifier<AsyncValue<List<AppointmentModel>>> {
  DoctorAppointmentsNotifier() : super(const AsyncValue.loading());

  Future<void> loadAppointments({String? status, String? date}) async {
    state = const AsyncValue.loading();
    
    final response = await AppointmentService.getDoctorAppointments(status: status, date: date);
    
    if (response['success'] == true) {
      final appointments = response['appointments'] as List<AppointmentModel>;
      state = AsyncValue.data(appointments);
    } else {
      state = AsyncValue.error(
        response['message'] ?? 'Failed to load appointments',
        StackTrace.current,
      );
    }
  }

  Future<bool> updateStatus(String appointmentId, String status) async {
    final response = await AppointmentService.updateAppointmentStatus(
      appointmentId: appointmentId,
      status: status,
    );

    if (response['success'] == true) {
      // Reload appointments
      await loadAppointments();
      return true;
    }
    
    return false;
  }
}

// Available slots provider - simple caching solution
final availableSlotsProvider = FutureProvider.family<List<String>, Map<String, String>>((ref, params) async {
  final response = await AppointmentService.getAvailableSlots(
    doctorId: params['doctorId']!,
    date: params['date']!,
  );

  if (response['success'] == true) {
    return List<String>.from(response['availableSlots'] ?? []);
  }
  
  return [];
});

// Doctor stats provider
final doctorStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final response = await AppointmentService.getAppointmentStats();

  if (response['success'] == true && response['stats'] != null) {
    final stats = response['stats'] as Map<String, dynamic>;
    return {
      'total': stats['total'] ?? 0,
      'today': stats['today'] ?? 0,
      'patients': stats['patients'] ?? 0,
      'pending': stats['pending'] ?? 0,
      'approved': stats['approved'] ?? 0,
    };
  }
  
  return {
    'total': 0,
    'today': 0,
    'patients': 0,
    'pending': 0,
    'approved': 0,
  };
});
