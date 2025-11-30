import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/doctor_profile_provider.dart';

class DoctorProfileViewScreen extends ConsumerWidget {
  const DoctorProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(doctorProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/doctor-dashboard/profile/edit'),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(doctorProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile data'));
          }

          final gender = profile['gender'] as String?;
          final experience = profile['experience'] as int?;
          final specialization = profile['specialization'] as String?;
          final clinicName = profile['clinicName'] as String?;
          final clinicAddress = profile['clinicAddress'] as Map?;
          final consultationFee = profile['consultationFee'] as int?;
          final licenseNumber = profile['licenseNumber'] as String?;
          final availableDays = profile['availableDays'] as List?;
          final timeSlots = profile['timeSlots'] as List?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                        child: const Icon(
                          Icons.local_hospital,
                          size: 50,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        specialization ?? 'Doctor',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Basic Information
                _buildSection(
                  context,
                  'Basic Information',
                  [
                    if (gender != null)
                      _buildInfoRow(Icons.person, 'Gender', gender),
                    if (experience != null)
                      _buildInfoRow(Icons.work, 'Experience', '$experience years'),
                    if (specialization != null)
                      _buildInfoRow(Icons.medical_services, 'Specialization', specialization),
                    if (licenseNumber != null)
                      _buildInfoRow(Icons.badge, 'License Number', licenseNumber),
                  ],
                ),

                const SizedBox(height: 24),

                // Clinic Information
                _buildSection(
                  context,
                  'Clinic Information',
                  [
                    if (clinicName != null)
                      _buildInfoRow(Icons.local_hospital, 'Clinic Name', clinicName),
                    if (clinicAddress != null) ...[
                      if (clinicAddress['fullAddress'] != null)
                        _buildInfoRow(Icons.location_on, 'Address', clinicAddress['fullAddress']),
                      if (clinicAddress['city'] != null)
                        _buildInfoRow(Icons.location_city, 'City', clinicAddress['city']),
                      if (clinicAddress['pincode'] != null)
                        _buildInfoRow(Icons.pin_drop, 'Pincode', clinicAddress['pincode']),
                    ],
                    if (consultationFee != null)
                      _buildInfoRow(Icons.currency_rupee, 'Consultation Fee', '₹$consultationFee'),
                  ],
                ),

                const SizedBox(height: 24),

                // Availability
                _buildSection(
                  context,
                  'Availability',
                  [
                    if (availableDays != null && availableDays.isNotEmpty)
                      _buildChipRow(
                        Icons.calendar_today,
                        'Available Days',
                        availableDays.cast<String>(),
                      ),
                    if (timeSlots != null && timeSlots.isNotEmpty)
                      _buildChipRow(
                        Icons.access_time,
                        'Time Slots',
                        timeSlots.cast<String>(),
                      ),
                  ],
                ),

                const SizedBox(height: 32),

                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/doctor-dashboard/profile/edit'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppTheme.primaryBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipRow(IconData icon, String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: AppTheme.primaryBlue),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) => Chip(
                      label: Text(item),
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      labelStyle: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 13,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
