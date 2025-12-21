import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pharmacist_profile_provider.dart';
import '../../providers/medicine_provider.dart';

class PharmacistDashboardScreen extends ConsumerWidget {
  const PharmacistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final pharmacistProfileAsync = ref.watch(pharmacistProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Dashboard'),
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
            // CLICKABLE PROFILE CARD (Like image 1)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () {
                  // Navigate to profile view
                  context.push('/pharmacist-dashboard/profile');
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: pharmacistProfileAsync.when(
                    data: (profile) {
                      String? storeName;
                      dynamic userIdObj;
                      String? fullName;

                      if (profile is Map<String, dynamic>) {
                        storeName = profile['storeName'] as String?;
                        userIdObj = profile['userId'];
                        if (userIdObj is Map<String, dynamic>) {
                          fullName = userIdObj['fullName'] as String?;
                        }
                      }

                      fullName ??= user?.fullName;
                      
                      return Row(
                        children: [
                          // Avatar with first letter
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                            child: Text(
                              (fullName?.isNotEmpty == true ? fullName![0].toUpperCase() : 'P'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  fullName ?? user?.fullName ?? 'Pharmacist',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          // Edit icon
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppTheme.primaryBlue),
                            onPressed: () {
                              context.push('/pharmacist-dashboard/profile/edit');
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text('Loading...'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    error: (_, __) => Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                          child: Text(
                            user?.fullName?.isNotEmpty == true 
                                ? user!.fullName![0].toUpperCase() 
                                : 'P',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                user?.fullName ?? 'Pharmacist',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppTheme.primaryBlue),
                          onPressed: () {
                            context.push('/pharmacist-dashboard/profile/edit');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Medicine Stock Stats
            Text(
              'Medicine Stock',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final medicineStatsAsync = ref.watch(medicineStatsProvider);
                return medicineStatsAsync.when(
                  data: (stats) => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Medicines',
                              value: '${stats['totalMedicines']}',
                              icon: Icons.medical_services,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              title: 'Stock Value',
                              value: '₹${stats['totalValue'].toStringAsFixed(0)}',
                              icon: Icons.currency_rupee,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Low Stock',
                              value: '${stats['lowStockCount']}',
                              icon: Icons.warning_amber_rounded,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              title: 'Expiring Soon',
                              value: '${stats['expiringCount']}',
                              icon: Icons.access_time,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _ActionButton(
              icon: Icons.local_pharmacy,
              title: 'Find Nearby Pharmacies',
              onTap: () => context.push('/pharmacies-map'),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.medical_services,
              title: 'Manage Medicine Stock',
              onTap: () => context.push('/pharmacist/medicines'),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.receipt_long,
              title: 'View Orders',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.delivery_dining,
              title: 'Deliveries',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            pharmacistProfileAsync.when(
              data: (profile) {
                final deliveryRadius = profile?['deliveryRadius'];
                if (deliveryRadius != null) {
                  return _ActionButton(
                    icon: Icons.location_searching,
                    title: 'Delivery Radius: $deliveryRadius km',
                    onTap: () {},
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
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