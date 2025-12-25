import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prescription_model.dart';
import '../models/appointment_model.dart' show DoctorInfo, PatientInfo;
import '../services/prescription_service.dart';

// Doctor's patients provider
final doctorPatientsProvider = StateNotifierProvider<DoctorPatientsNotifier, AsyncValue<List<PatientInfo>>>((ref) {
  return DoctorPatientsNotifier();
});

class DoctorPatientsNotifier extends StateNotifier<AsyncValue<List<PatientInfo>>> {
  DoctorPatientsNotifier() : super(const AsyncValue.loading());

  Future<void> loadPatients() async {
    state = const AsyncValue.loading();
    
    final response = await PrescriptionService.getDoctorPatients();
    
    if (response['success'] == true) {
      final patients = response['patients'] as List<PatientInfo>;
      state = AsyncValue.data(patients);
    } else {
      state = AsyncValue.error(
        response['message'] ?? 'Failed to load patients',
        StackTrace.current,
      );
    }
  }
}

// Doctor's prescriptions provider
final doctorPrescriptionsProvider = StateNotifierProvider<DoctorPrescriptionsNotifier, AsyncValue<List<PrescriptionModel>>>((ref) {
  return DoctorPrescriptionsNotifier();
});

class DoctorPrescriptionsNotifier extends StateNotifier<AsyncValue<List<PrescriptionModel>>> {
  DoctorPrescriptionsNotifier() : super(const AsyncValue.loading());

  Future<void> loadPrescriptions({String? patientId}) async {
    state = const AsyncValue.loading();
    
    final response = await PrescriptionService.getDoctorPrescriptions(patientId: patientId);
    
    if (response['success'] == true) {
      final prescriptions = response['prescriptions'] as List<PrescriptionModel>;
      state = AsyncValue.data(prescriptions);
    } else {
      state = AsyncValue.error(
        response['message'] ?? 'Failed to load prescriptions',
        StackTrace.current,
      );
    }
  }

  Future<Map<String, dynamic>> createPrescription({
    required String patientId,
    required String type,
    required String content,
    String? diagnosis,
    String? notes,
  }) async {
    final response = await PrescriptionService.createPrescription(
      patientId: patientId,
      type: type,
      content: content,
      diagnosis: diagnosis,
      notes: notes,
    );

    if (response['success'] == true) {
      // Reload prescriptions
      await loadPrescriptions();
    }

    return response;
  }
}

// Patient's doctors provider
final patientDoctorsProvider = StateNotifierProvider<PatientDoctorsNotifier, AsyncValue<List<DoctorInfo>>>((ref) {
  return PatientDoctorsNotifier();
});

class PatientDoctorsNotifier extends StateNotifier<AsyncValue<List<DoctorInfo>>> {
  PatientDoctorsNotifier() : super(const AsyncValue.loading());

  Future<void> loadDoctors() async {
    state = const AsyncValue.loading();
    
    final response = await PrescriptionService.getPatientDoctors();
    
    if (response['success'] == true) {
      final doctors = response['doctors'] as List<DoctorInfo>;
      state = AsyncValue.data(doctors);
    } else {
      state = AsyncValue.error(
        response['message'] ?? 'Failed to load doctors',
        StackTrace.current,
      );
    }
  }
}

// Patient's prescriptions provider
final patientPrescriptionsProvider = StateNotifierProvider<PatientPrescriptionsNotifier, AsyncValue<List<PrescriptionModel>>>((ref) {
  return PatientPrescriptionsNotifier();
});

class PatientPrescriptionsNotifier extends StateNotifier<AsyncValue<List<PrescriptionModel>>> {
  PatientPrescriptionsNotifier() : super(const AsyncValue.loading());

  Future<void> loadPrescriptions({String? doctorId}) async {
    state = const AsyncValue.loading();
    
    final response = await PrescriptionService.getPatientPrescriptions(doctorId: doctorId);
    
    if (response['success'] == true) {
      final prescriptions = response['prescriptions'] as List<PrescriptionModel>;
      state = AsyncValue.data(prescriptions);
    } else {
      state = AsyncValue.error(
        response['message'] ?? 'Failed to load prescriptions',
        StackTrace.current,
      );
    }
  }
}
