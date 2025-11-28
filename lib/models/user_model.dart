import 'user_role.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final bool isProfileComplete;

  // User-specific fields
  final String? ageOrDob;
  final String? gender;
  final String? city;
  final String? bloodGroup;
  final List<String>? allergies;
  final List<String>? medicalConditions;
  final List<String>? currentMedicines;
  final String? emergencyContactName;
  final String? relationship;
  final String? emergencyPhone;

  // Doctor-specific fields
  final String? experience;
  final String? specialization;
  final String? clinicName;
  final String? fullAddress;
  final String? pincode;
  final String? consultationFee;
  final String? licenseNumber;
  final String? documentUrl;
  final List<String>? availableDays;
  final List<String>? timeSlots;

  // Pharmacist-specific fields
  final String? altPhone;
  final String? pharmacyName;
  final String? openingTime;
  final String? closingTime;
  final String? pharmacyLicenseNumber;
  final List<String>? servicesOffered;
  final String? deliveryRadius;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.isProfileComplete = false,
    this.ageOrDob,
    this.gender,
    this.city,
    this.bloodGroup,
    this.allergies,
    this.medicalConditions,
    this.currentMedicines,
    this.emergencyContactName,
    this.relationship,
    this.emergencyPhone,
    this.experience,
    this.specialization,
    this.clinicName,
    this.fullAddress,
    this.pincode,
    this.consultationFee,
    this.licenseNumber,
    this.documentUrl,
    this.availableDays,
    this.timeSlots,
    this.altPhone,
    this.pharmacyName,
    this.openingTime,
    this.closingTime,
    this.pharmacyLicenseNumber,
    this.servicesOffered,
    this.deliveryRadius,
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    bool? isProfileComplete,
    String? ageOrDob,
    String? gender,
    String? city,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? medicalConditions,
    List<String>? currentMedicines,
    String? emergencyContactName,
    String? relationship,
    String? emergencyPhone,
    String? experience,
    String? specialization,
    String? clinicName,
    String? fullAddress,
    String? pincode,
    String? consultationFee,
    String? licenseNumber,
    String? documentUrl,
    List<String>? availableDays,
    List<String>? timeSlots,
    String? altPhone,
    String? pharmacyName,
    String? openingTime,
    String? closingTime,
    String? pharmacyLicenseNumber,
    List<String>? servicesOffered,
    String? deliveryRadius,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      ageOrDob: ageOrDob ?? this.ageOrDob,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      currentMedicines: currentMedicines ?? this.currentMedicines,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      relationship: relationship ?? this.relationship,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      experience: experience ?? this.experience,
      specialization: specialization ?? this.specialization,
      clinicName: clinicName ?? this.clinicName,
      fullAddress: fullAddress ?? this.fullAddress,
      pincode: pincode ?? this.pincode,
      consultationFee: consultationFee ?? this.consultationFee,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      documentUrl: documentUrl ?? this.documentUrl,
      availableDays: availableDays ?? this.availableDays,
      timeSlots: timeSlots ?? this.timeSlots,
      altPhone: altPhone ?? this.altPhone,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      pharmacyLicenseNumber: pharmacyLicenseNumber ?? this.pharmacyLicenseNumber,
      servicesOffered: servicesOffered ?? this.servicesOffered,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
    );
  }
}
