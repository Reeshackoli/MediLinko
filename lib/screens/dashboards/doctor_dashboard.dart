import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_profile_provider.dart';
import '../../providers/appointment_provider.dart';

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final doctorProfileAsync = ref.watch(doctorProfileProvider);
    final statsAsync = ref.watch(doctorStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card - Clickable
            Card(
              child: InkWell(
                onTap: () => context.push('/doctor-dashboard/profile'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                            child: const Icon(
                              Icons.medical_services,
                              size: 32,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: doctorProfileAsync.when(
                              data: (profile) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dr. ${user?.fullName ?? 'Doctor'}',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  Text(
                                    profile?['specialization'] ?? 'Specialist',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              loading: () => const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircularProgressIndicator(),
                                ],
                              ),
                              error: (_, __) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dr. ${user?.fullName ?? 'Doctor'}',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const Text('Specialist'),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppTheme.primaryBlue),
                            onPressed: () => context.push('/doctor-dashboard/profile/edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      doctorProfileAsync.when(
                        data: (profile) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatChip(
                              label: 'Experience',
                              value: '${profile?['experience'] ?? '0'} years',
                            ),
                            _StatChip(
                              label: 'Fee',
                              value: '₹${profile?['consultationFee'] ?? '0'}',
                            ),
                          ],
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatChip(
                              label: 'Experience',
                              value: '0 years',
                            ),
                            _StatChip(
                              label: 'Fee',
                              value: '₹0',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Today's Overview
            Text(
              "Today's Overview",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: statsAsync.when(
                    data: (stats) => _OverviewCard(
                      title: 'Appointments',
                      value: stats['today']?.toString() ?? '0',
                      icon: Icons.calendar_today,
                      color: AppTheme.primaryBlue,
                    ),
                    loading: () => const _OverviewCard(
                      title: 'Appointments',
                      value: '...',
                      icon: Icons.calendar_today,
                      color: AppTheme.primaryBlue,
                    ),
                    error: (_, __) => const _OverviewCard(
                      title: 'Appointments',
                      value: '0',
                      icon: Icons.calendar_today,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _OverviewCard(
                    title: 'Patients',
                    value: '6',
                    icon: Icons.people,
                    color: AppTheme.secondaryTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _ActionButton(
              icon: Icons.calendar_month,
              title: 'Manage Appointments',
              onTap: () => context.push('/doctor/appointments'),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.people_outline,
              title: 'View Patients',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.schedule,
              title: 'Update Availability',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            doctorProfileAsync.when(
              data: (profile) => _ActionButton(
                icon: Icons.location_on_outlined,
                title: 'Clinic: ${profile?['clinicName'] ?? 'Not set'}',
                onTap: () {},
              ),
              loading: () => _ActionButton(
                icon: Icons.location_on_outlined,
                title: 'Clinic: Loading...',
                onTap: () {},
              ),
              error: (_, __) => _ActionButton(
                icon: Icons.location_on_outlined,
                title: 'Clinic: Not set',
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryBlue),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
