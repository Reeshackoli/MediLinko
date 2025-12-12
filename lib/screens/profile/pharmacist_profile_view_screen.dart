import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/pharmacist_profile_provider.dart';

class PharmacistProfileViewScreen extends ConsumerWidget {
  const PharmacistProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(pharmacistProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/pharmacist-dashboard/profile/edit'),
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
                onPressed: () => ref.refresh(pharmacistProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          // DEBUG: Print the entire profile to console
          print('========= RAW PROFILE DATA =========');
          print(profile);
          print('====================================');
          
          if (profile == null) {
            print('⚠️ Profile is NULL');
            return const Center(child: Text('No profile data'));
          }

          // Personal info
          String? fullName;
          String? phone;
          String? email;
          if (profile['userId'] is Map) {
            final userId = profile['userId'] as Map<dynamic, dynamic>;
            fullName = userId['fullName'] as String?;
            phone = userId['phone'] as String?;
            email = userId['email'] as String?;
          }
          
          print('👤 Full Name: $fullName');
          print('📞 Phone: $phone');
          print('📧 Email: $email');
          
          // Pharmacist specific info
          final licenseNumber = profile['licenseNumber'] as String?;
          final verificationStatus = profile['verificationStatus'] as String?;
          final storeName = profile['storeName'] as String?;
          final storeAddress = profile['storeAddress'] as Map?;
          final deliveryRadius = profile['deliveryRadius'] as int?;
          final operatingHours = profile['operatingHours'] as Map?;
          final servicesOffered = profile['servicesOffered'] as List?;
          
          print('🏪 Store Name: $storeName');
          print('📍 Store Address: $storeAddress');
          print('🆔 License: $licenseNumber');
          print('⏰ Operating Hours: $operatingHours');
          print('🚚 Delivery Radius: $deliveryRadius');
          print('💊 Services: $servicesOffered');

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
                          Icons.local_pharmacy,
                          size: 50,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName ?? 'Pharmacist',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (storeName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          storeName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Personal Information Card
                _buildSection(
                  context,
                  'Personal Information',
                  [
                    if (fullName != null)
                      _buildInfoRow(Icons.person, 'Full Name', fullName),
                    if (phone != null)
                      _buildInfoRow(Icons.phone, 'Phone', phone),
                    if (email != null)
                      _buildInfoRow(Icons.email, 'Email', email),
                  ],
                ),

                const SizedBox(height: 24),

                // License Information Card
                _buildSection(
                  context,
                  'License Information',
                  [
                    if (licenseNumber != null)
                      _buildInfoRow(Icons.badge, 'License Number', licenseNumber),
                  ],
                ),

                const SizedBox(height: 24),

                // Store Information Card
                _buildSection(
                  context,
                  'Store Information',
                  [
                    if (storeName != null)
                      _buildInfoRow(Icons.store, 'Store Name', storeName),
                    if (storeAddress != null) ...[
                      if (storeAddress['street'] != null)
                        _buildInfoRow(
                            Icons.location_on, 'Street', storeAddress['street']),
                      if (storeAddress['city'] != null)
                        _buildInfoRow(
                            Icons.location_city, 'City', storeAddress['city']),
                      if (storeAddress['state'] != null)
                        _buildInfoRow(Icons.map, 'State', storeAddress['state']),
                      if (storeAddress['pincode'] != null)
                        _buildInfoRow(
                            Icons.pin_drop, 'Pincode', storeAddress['pincode']),
                    ],
                    if (deliveryRadius != null)
                      _buildInfoRow(Icons.delivery_dining, 'Delivery Radius',
                          '$deliveryRadius km'),
                  ],
                ),

                const SizedBox(height: 24),

                // Operating Hours Card
                if (operatingHours != null)
                  _buildSection(
                    context,
                    'Operating Hours',
                    [
                      if (operatingHours['open'] != null &&
                          operatingHours['close'] != null)
                        _buildInfoRow(
                          Icons.access_time,
                          'Timings',
                          '${operatingHours['open']} - ${operatingHours['close']}',
                        ),
                      if (operatingHours['days'] != null &&
                          (operatingHours['days'] as List).isNotEmpty)
                        _buildChipRow(
                          Icons.calendar_today,
                          'Operating Days',
                          (operatingHours['days'] as List).cast<String>(),
                        ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Services Offered Card
                if (servicesOffered != null && servicesOffered.isNotEmpty)
                  _buildSection(
                    context,
                    'Services Offered',
                    [
                      _buildChipRow(
                        Icons.medical_services,
                        'Available Services',
                        servicesOffered.cast<String>(),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),

                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/pharmacist-dashboard/profile/edit'),
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