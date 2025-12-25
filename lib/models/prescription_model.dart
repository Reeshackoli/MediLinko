import 'appointment_model.dart' show DoctorInfo, PatientInfo;

class PrescriptionModel {
  final String id;
  final String doctorId;
  final String patientId;
  final String type; // 'text' or 'image'
  final String content;
  final String diagnosis;
  final String notes;
  final DateTime createdAt;
  
  // Populated fields
  final DoctorInfo? doctor;
  final PatientInfo? patient;

  PrescriptionModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.type,
    required this.content,
    this.diagnosis = '',
    this.notes = '',
    required this.createdAt,
    this.doctor,
    this.patient,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['_id'] ?? '',
      doctorId: json['doctor'] is String ? json['doctor'] : (json['doctor']?['_id'] ?? ''),
      patientId: json['patient'] is String ? json['patient'] : (json['patient']?['_id'] ?? ''),
      type: json['type'] ?? 'text',
      content: json['content'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      doctor: json['doctor'] is Map ? DoctorInfo.fromJson(json['doctor']) : null,
      patient: json['patient'] is Map ? PatientInfo.fromJson(json['patient']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'doctor': doctorId,
      'patient': patientId,
      'type': type,
      'content': content,
      'diagnosis': diagnosis,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
