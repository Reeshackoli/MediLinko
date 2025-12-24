class UserMedicine {
  final String id;
  final String userId;
  final String medicineName;
  final String dosage;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;
  final List<MedicineDose> doses;

  UserMedicine({
    required this.id,
    required this.userId,
    required this.medicineName,
    required this.dosage,
    this.startDate,
    this.endDate,
    this.notes,
    this.isActive = true,
    this.doses = const [],
  });

  factory UserMedicine.fromJson(Map<String, dynamic> json) {
    return UserMedicine(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      medicineName: json['medicineName'] ?? '',
      dosage: json['dosage'] ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
      doses: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicineName': medicineName,
      'dosage': dosage,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }
}

class MedicineDose {
  final String time;
  final String? instruction;
  final String frequency;
  final List<int>? daysOfWeek;

  MedicineDose({
    required this.time,
    this.instruction,
    this.frequency = 'daily',
    this.daysOfWeek,
  });

  factory MedicineDose.fromJson(Map<String, dynamic> json) {
    return MedicineDose(
      time: json['time'] ?? '',
      instruction: json['instruction'],
      frequency: json['frequency'] ?? 'daily',
      daysOfWeek: json['daysOfWeek'] != null 
        ? List<int>.from(json['daysOfWeek'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      if (instruction != null && instruction!.isNotEmpty) 'instruction': instruction,
      'frequency': frequency,
      if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
    };
  }
}
