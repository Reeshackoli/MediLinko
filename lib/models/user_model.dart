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

  // Factory constructor for creating UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse role from string
    UserRole role;
    try {
      role = UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.user,
      );
    } catch (e) {
      role = UserRole.user;
    }

    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: role,
      isProfileComplete: json['isProfileComplete'] ?? false,
      ageOrDob: json['ageOrDob'],
      gender: json['gender'],
      city: json['city'],
      bloodGroup: json['bloodGroup'],
      allergies: json['allergies'] != null
          ? List<String>.from(json['allergies'])
          : null,
      medicalConditions: json['medicalConditions'] != null
          ? List<String>.from(json['medicalConditions'])
          : null,
      currentMedicines: json['currentMedicines'] != null
          ? List<String>.from(json['currentMedicines'])
          : null,
      emergencyContactName: json['emergencyContactName'],
      relationship: json['relationship'],
      emergencyPhone: json['emergencyPhone'],
      experience: json['experience'],
      specialization: json['specialization'],
      clinicName: json['clinicName'],
      fullAddress: json['fullAddress'],
      pincode: json['pincode'],
      consultationFee: json['consultationFee'],
      licenseNumber: json['licenseNumber'],
      documentUrl: json['documentUrl'],
      availableDays: json['availableDays'] != null
          ? List<String>.from(json['availableDays'])
          : null,
      timeSlots: json['timeSlots'] != null
          ? List<String>.from(json['timeSlots'])
          : null,
      altPhone: json['altPhone'],
      pharmacyName: json['pharmacyName'],
      openingTime: json['openingTime'],
      closingTime: json['closingTime'],
      pharmacyLicenseNumber: json['pharmacyLicenseNumber'],
      servicesOffered: json['servicesOffered'] != null
          ? List<String>.from(json['servicesOffered'])
          : null,
      deliveryRadius: json['deliveryRadius'],
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role.name,
      'isProfileComplete': isProfileComplete,
      'ageOrDob': ageOrDob,
      'gender': gender,
      'city': city,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'currentMedicines': currentMedicines,
      'emergencyContactName': emergencyContactName,
      'relationship': relationship,
      'emergencyPhone': emergencyPhone,
      'experience': experience,
      'specialization': specialization,
      'clinicName': clinicName,
      'fullAddress': fullAddress,
      'pincode': pincode,
      'consultationFee': consultationFee,
      'licenseNumber': licenseNumber,
      'documentUrl': documentUrl,
      'availableDays': availableDays,
      'timeSlots': timeSlots,
      'altPhone': altPhone,
      'pharmacyName': pharmacyName,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'pharmacyLicenseNumber': pharmacyLicenseNumber,
      'servicesOffered': servicesOffered,
      'deliveryRadius': deliveryRadius,
    };
  }
}
