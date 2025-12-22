class AppointmentModel {
  final String id;
  final String userId;
  final String doctorId;
  final String date;
  final String time;
  final String symptoms;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated doctor details
  final DoctorInfo? doctor;
  
  // Populated user details (for doctors viewing appointments)
  final PatientInfo? patient;
  
  // Patient health profile (embedded in appointment response)
  final PatientProfile? patientProfile;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.symptoms,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.doctor,
    this.patient,
    this.patientProfile,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['_id'] ?? '',
      userId: json['userId'] is String ? json['userId'] : json['userId']?['_id'] ?? '',
      doctorId: json['doctorId'] is String ? json['doctorId'] : json['doctorId']?['_id'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      symptoms: json['symptoms'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      doctor: json['doctorId'] is Map ? DoctorInfo.fromJson(json['doctorId']) : null,
      patient: json['userId'] is Map ? PatientInfo.fromJson(json['userId']) : null,
      patientProfile: json['patientProfile'] != null ? PatientProfile.fromJson(json['patientProfile']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'doctorId': doctorId,
      'date': date,
      'time': time,
      'symptoms': symptoms,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? userId,
    String? doctorId,
    String? date,
    String? time,
    String? symptoms,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DoctorInfo? doctor,
    PatientInfo? patient,
    PatientProfile? patientProfile,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      doctorId: doctorId ?? this.doctorId,
      date: date ?? this.date,
      time: time ?? this.time,
      symptoms: symptoms ?? this.symptoms,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      doctor: doctor ?? this.doctor,
      patient: patient ?? this.patient,
      patientProfile: patientProfile ?? this.patientProfile,
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String get formattedDate {
    try {
      final dateObj = DateTime.parse(date);
      return '${dateObj.day}/${dateObj.month}/${dateObj.year}';
    } catch (e) {
      return date;
    }
  }

  String get formattedTime {
    return time;
  }
}

class DoctorInfo {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? specialization;
  final String? clinicName;
  final dynamic clinicAddress;
  final num? consultationFee;
  final double? clinicLatitude;
  final double? clinicLongitude;

  DoctorInfo({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.specialization,
    this.clinicName,
    this.clinicAddress,
    this.consultationFee,
    this.clinicLatitude,
    this.clinicLongitude,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      specialization: json['specialization'],
      clinicName: json['clinicName'],
      clinicAddress: json['clinicAddress'],
      consultationFee: json['consultationFee'],
      clinicLatitude: json['clinicLatitude']?.toDouble(),
      clinicLongitude: json['clinicLongitude']?.toDouble(),
    );
  }
}

class PatientInfo {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;

  PatientInfo({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'],
      phone: json['phone'],
    );
  }
}

class PatientProfile {
  final int? age;
  final String? gender;
  final String? city;
  final String? bloodGroup;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> currentMedications;
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactPhone;

  PatientProfile({
    this.age,
    this.gender,
    this.city,
    this.bloodGroup,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.currentMedications = const [],
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactPhone,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      age: json['age'],
      gender: json['gender'],
      city: json['city'],
      bloodGroup: json['bloodGroup'],
      allergies: json['allergies'] != null 
          ? List<String>.from(json['allergies']) 
          : [],
      medicalConditions: json['medicalConditions'] != null 
          ? List<String>.from(json['medicalConditions']) 
          : [],
      currentMedications: json['currentMedications'] != null 
          ? List<String>.from(json['currentMedications']) 
          : [],
      emergencyContactName: json['emergencyContactName'],
      emergencyContactRelationship: json['emergencyContactRelationship'],
      emergencyContactPhone: json['emergencyContactPhone'],
    );
  }
}

