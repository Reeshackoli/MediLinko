class AppConstants {
  // App Info
  static const String appName = 'MediLinko';
  static const String appTagline = 'Your Smart Healthcare Companion';

  // Blood Groups
  static const List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // Genders
  static const List<String> genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  // Relationships
  static const List<String> relationships = [
    'Spouse',
    'Parent',
    'Sibling',
    'Child',
    'Friend',
    'Other',
  ];

  // Specializations
  static const List<String> specializations = [
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Orthopedic',
    'Gynecologist',
    'Neurologist',
    'Psychiatrist',
    'Dentist',
    'ENT Specialist',
    'Ophthalmologist',
    'Other',
  ];

  // Days of Week
  static const List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Time Slots
  static const List<String> timeSlots = [
    'Morning (9 AM - 12 PM)',
    'Afternoon (12 PM - 4 PM)',
    'Evening (4 PM - 8 PM)',
    'Night (8 PM - 11 PM)',
  ];

  // Pharmacy Services
  static const List<String> pharmacyServices = [
    'Prescription Medicines',
    'OTC Medicines',
    'Home Delivery',
    'Medical Equipment',
    'Health Checkup',
    '24/7 Service',
  ];

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPhoneLength = 10;
}
