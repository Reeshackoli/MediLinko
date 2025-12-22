import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_wizard_provider.dart';
import 'user_profile/user_personal_step.dart';
import 'user_profile/user_health_step.dart';
import 'user_profile/user_emergency_step.dart';
import 'doctor_profile/doctor_basic_step.dart';
import 'doctor_profile/doctor_clinic_step.dart';
import 'doctor_profile/doctor_verification_step.dart';
import 'doctor_profile/doctor_timings_step.dart';
import 'pharmacist_profile/pharmacist_owner_step.dart';
import 'pharmacist_profile/pharmacist_pharmacy_step.dart';
import 'pharmacist_profile/pharmacist_verification_step.dart';

class ProfileWizardScreen extends ConsumerWidget {
  const ProfileWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentStep = ref.watch(wizardStepProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    final steps = _getStepsForRole(user.role);
    final totalSteps = steps.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: currentStep > 0,
        leading: currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(wizardStepProvider.notifier).state = currentStep - 1;
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            _ProgressIndicator(
              currentStep: currentStep,
              totalSteps: totalSteps,
            ),
            // Step Content
            Expanded(
              child: steps[currentStep],
            ),
            // Navigation Buttons
            _NavigationButtons(
              currentStep: currentStep,
              totalSteps: totalSteps,
              onNext: () => _handleNext(context, ref, user),
              onSkip: () => _handleSkip(ref, currentStep, totalSteps),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getStepsForRole(UserRole role) {
    switch (role) {
      case UserRole.user:
        return const [
          UserPersonalStep(),
          UserHealthStep(),
          UserEmergencyStep(),
        ];
      case UserRole.doctor:
        return const [
          DoctorBasicStep(),
          DoctorClinicStep(),
          DoctorVerificationStep(),
          DoctorTimingsStep(),
        ];
      case UserRole.pharmacist:
        return const [
          PharmacistOwnerStep(),
          PharmacistPharmacyStep(),
          PharmacistVerificationStep(),
        ];
    }
  }

  void _handleNext(BuildContext context, WidgetRef ref, user) {
    final currentStep = ref.read(wizardStepProvider);
    final steps = _getStepsForRole(user.role);

    if (currentStep < steps.length - 1) {
      ref.read(wizardStepProvider.notifier).state = currentStep + 1;
    } else {
      _completeWizard(context, ref, user);
    }
  }

  void _handleSkip(WidgetRef ref, int currentStep, int totalSteps) {
    if (currentStep < totalSteps - 1) {
      ref.read(wizardStepProvider.notifier).state = currentStep + 1;
    }
  }

  void _completeWizard(BuildContext context, WidgetRef ref, user) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final error = await ref.read(profileWizardProvider.notifier).buildUserProfile(user);
    
    // Dismiss loading
    if (context.mounted) Navigator.pop(context);

    if (error != null) {
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Success - update local user and navigate
    final updatedUser = ref.read(profileWizardProvider.notifier).buildLocalUserModel(user);
    ref.read(authProvider.notifier).updateUser(updatedUser);
    ref.read(wizardStepProvider.notifier).state = 0;

    // Navigate to appropriate dashboard
    if (context.mounted) {
      switch (user.role) {
        case UserRole.user:
          context.go('/user-dashboard');
          break;
        case UserRole.doctor:
          context.go('/doctor-dashboard');
          break;
        case UserRole.pharmacist:
          context.go('/pharmacist-dashboard');
          break;
      }
    }
  }
}

class _ProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _ProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${currentStep + 1} of $totalSteps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '${((currentStep + 1) / totalSteps * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (currentStep + 1) / totalSteps,
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}

class _NavigationButtons extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _NavigationButtons({
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isLastStep)
            Expanded(
              child: OutlinedButton(
                onPressed: onSkip,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Skip'),
              ),
            ),
          if (!isLastStep) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
                shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
              ),
              child: Text(
                isLastStep ? 'Complete' : 'Continue',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
