import 'package:go_router/go_router.dart';

// --- Splash Screen ---
import '../../screens/splash_screen.dart';

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
import '../../screens/doctors/public_doctor_profile_screen.dart';

// --- Pharmacist Profile ---
import '../../screens/profile/pharmacist_profile_view_screen.dart';
import '../../screens/profile/pharmacist_profile_edit_screen.dart';

// --- Features ---
import '../../screens/medicine_stock/medicine_list_screen.dart';
import '../../screens/medicine_stock/add_medicine_screen.dart';
import '../../screens/medicine_stock/edit_medicine_screen.dart';
import '../../screens/medicine_tracker/medicine_tracker_screen_new.dart';
import '../../screens/maps/doctors_map_screen.dart';
import '../../screens/maps/pharmacies_map_screen.dart';
import '../../screens/appointments/book_appointment_screen.dart';
import '../../screens/appointments/appointment_list_screen.dart';
import '../../screens/appointments/doctor_appointments_screen.dart';
import '../../screens/patients/patient_management_screen.dart';
import '../../screens/patients/patient_profile_view_screen.dart';

// --- Prescriptions ---
import '../../screens/prescriptions/doctor_prescriptions_screen.dart';
import '../../screens/prescriptions/create_prescription_screen.dart';
import '../../screens/prescriptions/user_prescriptions_screen.dart';
import '../../screens/prescriptions/prescription_details_screen.dart';

// --- Emergency ---
import '../../screens/emergency/emergency_screen.dart';

// --- Notifications ---
import '../../screens/notifications/notifications_screen.dart';

// --- Models ---
import '../../models/appointment_model.dart' show AppointmentModel, DoctorInfo, PatientInfo, DoctorProfile, PatientProfile;
import '../../models/doctor_location_model.dart';

// --- Main for navigator key ---
import '../../main.dart';

// --- Providers ---


final GoRouter router = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/splash',
  routes: [
    // ------------------- Splash Screen -------------------
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    
    // ------------------- Auth & Onboarding -------------------
    GoRoute(
      path: '/',
      builder: (context, state) => const OnboardingScreen(),
    ),
    
    // ------------------- Emergency -------------------
    GoRoute(
      path: '/emergency',
      builder: (context, state) => const EmergencyScreen(),
    ),
    
    // ------------------- Notifications -------------------
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
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
    GoRoute(
      path: '/pharmacist/medicines/edit/:id',
      builder: (context, state) {
        final medicineId = state.pathParameters['id']!;
        return EditMedicineScreen(medicineId: medicineId);
      },
    ),

    // ------------------- Shared Features -------------------
    GoRoute(
      path: '/medicine-tracker',
      builder: (context, state) => const MedicineTrackerScreen(),
    ),
    GoRoute(
      path: '/doctors-map',
      builder: (context, state) => const DoctorsMapScreen(),
    ),
    GoRoute(
      path: '/doctor-profile/:doctorId',
      builder: (context, state) {
        final doctor = state.extra as DoctorLocationModel;
        return PublicDoctorProfileScreen(doctor: doctor);
      },
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
    
    // ------------------- Prescription Routes -------------------
    // Doctor prescription routes
    GoRoute(
      path: '/doctor/prescriptions',
      builder: (context, state) => const DoctorPrescriptionsScreen(),
    ),
    GoRoute(
      path: '/doctor/prescriptions/create',
      builder: (context, state) {
        final patient = state.extra as PatientInfo;
        return CreatePrescriptionScreen(patient: patient);
      },
    ),
    
    // User prescription routes
    GoRoute(
      path: '/user/prescriptions',
      builder: (context, state) => const UserPrescriptionsScreen(),
    ),
    GoRoute(
      path: '/user/prescriptions/:doctorId',
      builder: (context, state) {
        final doctor = state.extra as DoctorInfo;
        return PrescriptionDetailsScreen(doctor: doctor);
      },
    ),
  ],
);
