import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../services/profile_service.dart';

class ProfileWizardNotifier extends StateNotifier<Map<String, dynamic>> {
  ProfileWizardNotifier() : super({});

  void updateField(String key, dynamic value) {
    state = {...state, key: value};
    // Auto-save to backend
    _autoSaveStep();
  }

  void updateMultipleFields(Map<String, dynamic> fields) {
    state = {...state, ...fields};
    // Auto-save to backend
    _autoSaveStep();
  }

  // Auto-save step to backend
  Future<void> _autoSaveStep() async {
    if (state.isNotEmpty) {
      try {
        await ProfileService.updateWizardStep(state);
      } catch (e) {
        // Silently fail - data is still in local state
      }
    }
  }

  void clearData() {
    state = {};
  }

  // Build and save complete profile to backend
  Future<String?> buildUserProfile(UserModel baseUser) async {
    try {
      final completeData = <String, dynamic>{
        ...state,
        'isProfileComplete': true,
      };

      // Transform emergency contact fields for user role
      if (baseUser.role == UserRole.user) {
        // Convert flat emergency contact fields to nested structure
        if (state.containsKey('emergencyContactName') || 
            state.containsKey('emergencyPhone')) {
          completeData['emergencyContact'] = {
            'name': state['emergencyContactName'],
            'phone': state['emergencyPhone'],
          };
          // Remove old flat fields
          completeData.remove('emergencyContactName');
          completeData.remove('emergencyPhone');
          completeData.remove('relationship');
        }
      }
      
      // Transform clinic address for doctor role
      if (baseUser.role == UserRole.doctor) {
        if (state.containsKey('fullAddress') || 
            state.containsKey('city') || 
            state.containsKey('pincode')) {
          completeData['clinicAddress'] = {
            'fullAddress': state['fullAddress'],
            'city': state['city'],
            'pincode': state['pincode'],
          };
          completeData.remove('fullAddress');
          completeData.remove('city');
          completeData.remove('pincode');
        }
        // Convert string values to numbers
        if (state.containsKey('experience')) {
          completeData['experience'] = int.tryParse(state['experience'].toString()) ?? 0;
        }
        if (state.containsKey('consultationFee')) {
          completeData['consultationFee'] = int.tryParse(state['consultationFee'].toString()) ?? 0;
        }
      }
      
      // Transform pharmacy data for pharmacist role
      if (baseUser.role == UserRole.pharmacist) {
        // Rename pharmacyName to storeName
        if (state.containsKey('pharmacyName')) {
          completeData['storeName'] = state['pharmacyName'];
          completeData.remove('pharmacyName');
        }
        
        // Transform store address
        if (state.containsKey('fullAddress') || 
            state.containsKey('city') || 
            state.containsKey('pincode')) {
          completeData['storeAddress'] = {
            'fullAddress': state['fullAddress'],
            'city': state['city'],
            'pincode': state['pincode'],
          };
          completeData.remove('fullAddress');
          completeData.remove('city');
          completeData.remove('pincode');
        }
        
        // Transform operating hours
        if (state.containsKey('openingTime') || state.containsKey('closingTime')) {
          completeData['operatingHours'] = {
            'opening': state['openingTime'],
            'closing': state['closingTime'],
          };
          completeData.remove('openingTime');
          completeData.remove('closingTime');
        }
        
        // Rename pharmacyLicenseNumber to licenseNumber
        if (state.containsKey('pharmacyLicenseNumber')) {
          completeData['licenseNumber'] = state['pharmacyLicenseNumber'];
          completeData.remove('pharmacyLicenseNumber');
        }
        
        // Convert deliveryRadius to number
        if (state.containsKey('deliveryRadius')) {
          completeData['deliveryRadius'] = int.tryParse(state['deliveryRadius'].toString()) ?? 0;
        }
      }

      final response = await ProfileService.updateProfile(completeData);

      if (response['success']) {
        clearData();
        return null; // Success
      } else {
        return response['message'] ?? 'Failed to complete profile';
      }
    } catch (e) {
      return e.toString();
    }
  }

  // Build local user model for UI - public method
  UserModel buildLocalUserModel(UserModel baseUser) {
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
