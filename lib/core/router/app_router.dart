import 'package:go_router/go_router.dart';
import '../../models/user_role.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/auth/registration_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/profile_wizard/profile_wizard_screen.dart';
import '../../screens/dashboards/user_dashboard.dart';
import '../../screens/dashboards/doctor_dashboard.dart';
import '../../screens/dashboards/pharmacist_dashboard.dart';
import '../../screens/medicine_stock/medicine_list_screen.dart';
import '../../screens/medicine_stock/add_medicine_screen.dart';
import '../../screens/profile/user_profile_view_screen.dart';
import '../../screens/profile/user_profile_edit_screen.dart';
import '../../screens/profile/doctor_profile_view_screen.dart';
import '../../screens/profile/doctor_profile_edit_screen.dart';
import '../../screens/maps/doctors_map_screen.dart';
import '../../screens/appointments/book_appointment_screen.dart';
import '../../screens/appointments/appointment_list_screen.dart';
import '../../screens/appointments/doctor_appointments_screen.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_location_model.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
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
    GoRoute(
      path: '/pharmacist-dashboard',
      builder: (context, state) => const PharmacistDashboardScreen(),
    ),
    GoRoute(
      path: '/pharmacist/medicines',
      builder: (context, state) => const MedicineListScreen(),
    ),
    GoRoute(
      path: '/pharmacist/medicines/add',
      builder: (context, state) => const AddMedicineScreen(),
    ),
    GoRoute(
      path: '/doctors-map',
      builder: (context, state) => const DoctorsMapScreen(),
    ),
    GoRoute(
      path: '/book-appointment',
      builder: (context, state) {
        final extra = state.extra;
        
        // Handle both DoctorLocationModel (from map) and DoctorInfo (from other sources)
        DoctorInfo doctor;
        if (extra is DoctorLocationModel) {
          // Convert DoctorLocationModel to DoctorInfo
          doctor = DoctorInfo.fromJson(extra.toDoctorInfoJson());
        } else if (extra is DoctorInfo) {
          doctor = extra;
        } else {
          throw Exception('Invalid doctor data type');
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
  ],
);
