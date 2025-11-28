enum UserRole {
  user,
  doctor,
  pharmacist;

  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.pharmacist:
        return 'Pharmacist';
    }
  }

  String get description {
    switch (this) {
      case UserRole.user:
        return 'Book appointments & manage health';
      case UserRole.doctor:
        return 'Manage clinic & consultations';
      case UserRole.pharmacist:
        return 'Manage pharmacy & deliveries';
    }
  }
}
