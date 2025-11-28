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
      path: '/doctor-dashboard',
      builder: (context, state) => const DoctorDashboardScreen(),
    ),
    GoRoute(
      path: '/pharmacist-dashboard',
      builder: (context, state) => const PharmacistDashboardScreen(),
    ),
  ],
);
