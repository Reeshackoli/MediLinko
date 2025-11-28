import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';

class ProfileWizardNotifier extends StateNotifier<Map<String, dynamic>> {
  ProfileWizardNotifier() : super({});

  void updateField(String key, dynamic value) {
    state = {...state, key: value};
  }

  void updateMultipleFields(Map<String, dynamic> fields) {
    state = {...state, ...fields};
  }

  void clearData() {
    state = {};
  }

  UserModel buildUserProfile(UserModel baseUser) {
    switch (baseUser.role) {
      case UserRole.user:
        return baseUser.copyWith(
          ageOrDob: state['ageOrDob'] as String?,
          gender: state['gender'] as String?,
          city: state['city'] as String?,
          bloodGroup: state['bloodGroup'] as String?,
          allergies: state['allergies'] as List<String>?,
          medicalConditions: state['medicalConditions'] as List<String>?,
          currentMedicines: state['currentMedicines'] as List<String>?,
          emergencyContactName: state['emergencyContactName'] as String?,
          relationship: state['relationship'] as String?,
          emergencyPhone: state['emergencyPhone'] as String?,
          isProfileComplete: true,
        );

      case UserRole.doctor:
        return baseUser.copyWith(
          gender: state['gender'] as String?,
          experience: state['experience'] as String?,
          specialization: state['specialization'] as String?,
          clinicName: state['clinicName'] as String?,
          fullAddress: state['fullAddress'] as String?,
          city: state['city'] as String?,
          pincode: state['pincode'] as String?,
          consultationFee: state['consultationFee'] as String?,
          licenseNumber: state['licenseNumber'] as String?,
          documentUrl: state['documentUrl'] as String?,
          availableDays: state['availableDays'] as List<String>?,
          timeSlots: state['timeSlots'] as List<String>?,
          isProfileComplete: true,
        );

      case UserRole.pharmacist:
        return baseUser.copyWith(
          altPhone: state['altPhone'] as String?,
          pharmacyName: state['pharmacyName'] as String?,
          fullAddress: state['fullAddress'] as String?,
          city: state['city'] as String?,
          pincode: state['pincode'] as String?,
          openingTime: state['openingTime'] as String?,
          closingTime: state['closingTime'] as String?,
          pharmacyLicenseNumber: state['pharmacyLicenseNumber'] as String?,
          documentUrl: state['documentUrl'] as String?,
          servicesOffered: state['servicesOffered'] as List<String>?,
          deliveryRadius: state['deliveryRadius'] as String?,
          isProfileComplete: true,
        );
    }
  }
}

final profileWizardProvider =
    StateNotifierProvider<ProfileWizardNotifier, Map<String, dynamic>>((ref) {
  return ProfileWizardNotifier();
});

// Current wizard step provider
final wizardStepProvider = StateProvider<int>((ref) => 0);
