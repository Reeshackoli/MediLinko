import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- Auth & Onboarding ---
import '../../models/user_role.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/auth/registration_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/profile_wizard/profile_wizard_screen.dart';

// --- Dashboards ---
import '../../screens/dashboards/user_dashboard.dart';
import '../../screens/dashboards/doctor_dashboard.dart';
import '../../screens/dashboards/pharmacist_dashboard.dart';

// --- User Profile ---
import '../../screens/profile/user_profile_view_screen.dart';
import '../../screens/profile/user_profile_edit_screen.dart';

// --- Doctor Profile ---
import '../../screens/profile/doctor_profile_view_screen.dart';
import '../../screens/profile/doctor_profile_edit_screen.dart';

// --- Pharmacist Profile ---
import '../../screens/profile/pharmacist_profile_view_screen.dart';
import '../../screens/profile/pharmacist_profile_edit_screen.dart';

// --- Features ---
import '../../screens/medicine_stock/medicine_list_screen.dart';
import '../../screens/medicine_stock/add_medicine_screen.dart';
import '../../screens/medicine_tracker/medicine_calendar_screen.dart';
import '../../screens/maps/doctors_map_screen.dart';
import '../../screens/maps/pharmacist_map_screen.dart';
import '../../screens/appointments/book_appointment_screen.dart';
import '../../screens/appointments/appointment_list_screen.dart';
import '../../screens/appointments/doctor_appointments_screen.dart';
import '../../screens/patients/patient_management_screen.dart';
import '../../screens/patients/patient_profile_view_screen.dart';

// --- Models ---
import '../../models/appointment_model.dart';
import '../../models/doctor_location_model.dart';


final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    // ------------------- Auth & Onboarding -------------------
    GoRoute(
      path: '/',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        final role = state.extra as UserRole? ?? UserRole.user;
        return RegistrationScreen(role: role);
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/profile-wizard',
      builder: (context, state) => const ProfileWizardScreen(),
    ),

    // ------------------- User Routes -------------------
    GoRoute(
      path: '/user-dashboard',
      builder: (context, state) => const UserDashboardScreen(),
    ),
    GoRoute(
      path: '/user-dashboard/profile',
      builder: (context, state) => const UserProfileViewScreen(),
    ),
    GoRoute(
      path: '/user-dashboard/profile/edit',
      builder: (context, state) => const UserProfileEditScreen(),
    ),

    // ------------------- Doctor Routes -------------------
    GoRoute(
      path: '/doctor-dashboard',
      builder: (context, state) => const DoctorDashboardScreen(),
    ),
    GoRoute(
      path: '/doctor-dashboard/profile',
      builder: (context, state) => const DoctorProfileViewScreen(),
    ),
    GoRoute(
      path: '/doctor-dashboard/profile/edit',
      builder: (context, state) => const DoctorProfileEditScreen(),
    ),

    // ------------------- Pharmacist Routes -------------------
    GoRoute(
      path: '/pharmacist-dashboard',
      builder: (context, state) => const PharmacistDashboardScreen(),
    ),
    GoRoute(
      path: '/pharmacist-dashboard/profile',
      builder: (context, state) => const PharmacistProfileViewScreen(),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => const PharmacistProfileEditScreen(),
        ),
      ],
    ),

    // ------------------- Medicine Management -------------------
    GoRoute(
      path: '/pharmacist/medicines',
      builder: (context, state) => const MedicineListScreen(),
    ),
    GoRoute(
      path: '/pharmacist/medicines/add',
      builder: (context, state) => const AddMedicineScreen(),
    ),

    // ------------------- Shared Features -------------------
    GoRoute(
      path: '/medicine-tracker',
      builder: (context, state) => const MedicineCalendarScreen(),
    ),
    GoRoute(
      path: '/doctors-map',
      builder: (context, state) => const DoctorsMapScreen(),
    ),
    GoRoute(
      path: '/pharmacies-map',
      builder: (context, state) => const PharmaciesMapScreen(),
    ),
    GoRoute(
      path: '/book-appointment',
      builder: (context, state) {
        final extra = state.extra;

        late final DoctorInfo doctor;

        if (extra is DoctorLocationModel) {
          doctor = DoctorInfo.fromJson(extra.toDoctorInfoJson());
        } else if (extra is DoctorInfo) {
          doctor = extra;
        } else {
          throw Exception('Invalid doctor data');
        }

        return BookAppointmentScreen(doctor: doctor);
      },
    ),
    GoRoute(
      path: '/appointments',
      builder: (context, state) => const AppointmentListScreen(),
    ),
    GoRoute(
      path: '/doctor/appointments',
      builder: (context, state) => const DoctorAppointmentsScreen(),
    ),
    GoRoute(
      path: '/doctor/patients',
      builder: (context, state) => const PatientManagementScreen(),
    ),
    GoRoute(
      path: '/doctor/patients/:patientId',
      builder: (context, state) {
        final patientId = state.pathParameters['patientId']!;
        final patientName = state.uri.queryParameters['name'] ?? 'Patient';
        return PatientProfileViewScreen(
          patientId: patientId,
          patientName: patientName,
        );
      },
    ),
  ],
);
