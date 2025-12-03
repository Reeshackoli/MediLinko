class DoctorLocationModel {
  final String id;
  final String fullName;
  final String? clinicName;
  final double latitude;
  final double longitude;
  final String? specialization;
  final String? experience;
  final String? consultationFee;
  final double? distance; // Distance in meters
  final String? city;
  final String? clinicAddress;
  final List<String>? availableDays;
  final List<String>? timeSlots;

  DoctorLocationModel({
    required this.id,
    required this.fullName,
    this.clinicName,
    required this.latitude,
    required this.longitude,
    this.specialization,
    this.experience,
    this.consultationFee,
    this.distance,
    this.city,
    this.clinicAddress,
    this.availableDays,
    this.timeSlots,
  });

  factory DoctorLocationModel.fromJson(Map<String, dynamic> json) {
    return DoctorLocationModel(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? 'Unknown Doctor',
      clinicName: json['clinicName'],
      latitude: (json['clinicLatitude'] ?? 0).toDouble(),
      longitude: (json['clinicLongitude'] ?? 0).toDouble(),
      specialization: json['specialization'],
      experience: json['experience']?.toString(),
      consultationFee: json['consultationFee']?.toString(),
      distance: json['distance']?.toDouble(),
      city: json['city'],
      clinicAddress: json['clinicAddress'],
      availableDays: json['availableDays'] != null
          ? List<String>.from(json['availableDays'])
          : null,
      timeSlots: json['timeSlots'] != null
          ? List<String>.from(json['timeSlots'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'clinicName': clinicName,
      'clinicLatitude': latitude,
      'clinicLongitude': longitude,
      'specialization': specialization,
      'experience': experience,
      'consultationFee': consultationFee,
      'distance': distance,
      'city': city,
      'clinicAddress': clinicAddress,
      'availableDays': availableDays,
      'timeSlots': timeSlots,
    };
  }

  String get distanceText {
    if (distance == null) return '';
    if (distance! < 1000) {
      return '${distance!.round()} m away';
    } else {
      return '${(distance! / 1000).toStringAsFixed(1)} km away';
    }
  }

  DoctorLocationModel copyWith({
    String? id,
    String? fullName,
    String? clinicName,
    double? latitude,
    double? longitude,
    String? specialization,
    String? experience,
    String? consultationFee,
    double? distance,
    String? city,
    String? clinicAddress,
    List<String>? availableDays,
    List<String>? timeSlots,
  }) {
    return DoctorLocationModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      clinicName: clinicName ?? this.clinicName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      specialization: specialization ?? this.specialization,
      experience: experience ?? this.experience,
      consultationFee: consultationFee ?? this.consultationFee,
      distance: distance ?? this.distance,
      city: city ?? this.city,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      availableDays: availableDays ?? this.availableDays,
      timeSlots: timeSlots ?? this.timeSlots,
    );
  }

  /// Convert DoctorLocationModel to DoctorInfo for appointment booking
  /// DoctorInfo is from appointment_model.dart
  Map<String, dynamic> toDoctorInfoJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': null, // Not available in location model
      'phone': null, // Not available in location model
      'specialization': specialization,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'consultationFee': consultationFee != null ? num.tryParse(consultationFee!) : null,
      'clinicLatitude': latitude,
      'clinicLongitude': longitude,
    };
  }
}
