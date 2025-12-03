import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../services/profile_service.dart';

class ProfileWizardNotifier extends StateNotifier<Map<String, dynamic>> {
  ProfileWizardNotifier() : super({});

  void updateField(String key, dynamic value) {
    state = {...state, key: value};
    // Auto-save disabled to prevent memory issues with multiple tabs
    // Data is saved when completing the wizard
  }

  void updateMultipleFields(Map<String, dynamic> fields) {
    state = {...state, ...fields};
    // Auto-save disabled to prevent memory issues with multiple tabs
    // Data is saved when completing the wizard
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

      // No transformation needed for user emergency contact fields
      // Backend now uses flat fields: emergencyContactName, emergencyContactRelationship, emergencyContactPhone
      
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
        
        // Convert availableDays and timeSlots to availableTimings format
        if (state.containsKey('availableDays') && state.containsKey('timeSlots')) {
          final days = state['availableDays'] as List<dynamic>?;
          final slots = state['timeSlots'] as List<dynamic>?;
          
          print('🔍 Converting availability data:');
          print('   Days: $days');
          print('   Slots: $slots');
          
          if (days != null && days.isNotEmpty && slots != null && slots.isNotEmpty) {
            // Parse the time slot string "09:00 - 18:00"
            String from = '09:00';
            String to = '18:00';
            
            final firstSlot = slots.first.toString();
            if (firstSlot.contains(' - ')) {
              final parts = firstSlot.split(' - ');
              if (parts.length == 2) {
                from = parts[0].trim();
                to = parts[1].trim();
              }
            }
            
            print('   Parsed times: from=$from, to=$to');
            
            // Create availableTimings array
            final availableTimings = days.map((day) => {
              'day': day.toString(),
              'from': from,
              'to': to,
            }).toList();
            
            print('   Created availableTimings: $availableTimings');
            
            completeData['availableTimings'] = availableTimings;
            completeData.remove('availableDays');
            completeData.remove('timeSlots');
          } else {
            print('⚠️ Missing days or slots data');
          }
        } else {
          print('⚠️ No availableDays or timeSlots found in state');
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
          relationship: state['emergencyContactRelationship'] as String?,
          emergencyPhone: state['emergencyContactPhone'] as String?,
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
