import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/health_profile_provider.dart';
import '../../core/theme/app_theme.dart';

class UserProfileViewScreen extends ConsumerWidget {
  const UserProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(healthProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(healthProfileProvider),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/user-dashboard/profile/edit'),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('No profile data found'),
            );
          }

          // Extract data from Map - handle both old nested and new flat structure
          final firstName = profile['firstName'] as String? ?? '';
          final lastName = profile['lastName'] as String? ?? '';
          final age = profile['age'] as int? ?? 0;
          final gender = profile['gender'] as String? ?? '';
          final city = profile['city'] as String? ?? '';
          final bloodGroup = profile['bloodGroup'] as String? ?? '';
          final allergies = (profile['allergies'] as List?)?.cast<String>() ?? [];
          final medicalConditions = (profile['medicalConditions'] as List?)?.cast<String>() ?? [];
          final currentMedications = (profile['currentMedications'] as List?)?.cast<String>() ?? [];
          
          // Handle both old nested and new flat emergency contact structure
          // Prioritize flat structure over nested structure
          String emergencyContactName = profile['emergencyContactName'] as String? ?? '';
          String emergencyContactRelationship = profile['emergencyContactRelationship'] as String? ?? '';
          String emergencyContactPhone = profile['emergencyContactPhone'] as String? ?? '';
          
          // Fall back to old nested structure if flat fields are empty
          if (emergencyContactName.isEmpty && 
              profile.containsKey('emergencyContact') && 
              profile['emergencyContact'] is Map) {
            final ec = profile['emergencyContact'] as Map<String, dynamic>;
            emergencyContactName = ec['name'] as String? ?? '';
            emergencyContactPhone = ec['phone'] as String? ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryBlue,
                        child: Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Patient',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Personal Information Section
                _buildSectionTitle('Personal Information'),
                _buildInfoCard([
                  _buildInfoRow(Icons.cake, 'Age', '$age years'),
                  _buildInfoRow(Icons.person, 'Gender', gender),
                  _buildInfoRow(Icons.location_city, 'City', city),
                ]),
                const SizedBox(height: 24),

                // Health Information Section
                _buildSectionTitle('Health Information'),
                _buildInfoCard([
                  _buildInfoRow(
                    Icons.water_drop,
                    'Blood Group',
                    bloodGroup,
                  ),
                  if (allergies.isNotEmpty)
                    _buildInfoRow(
                      Icons.warning_amber,
                      'Allergies',
                      allergies.join(', '),
                    ),
                  if (medicalConditions.isNotEmpty)
                    _buildInfoRow(
                      Icons.medical_information,
                      'Medical Conditions',
                      medicalConditions.join(', '),
                    ),
                  if (currentMedications.isNotEmpty)
                    _buildInfoRow(
                      Icons.medication,
                      'Current Medications',
                      currentMedications.join(', '),
                    ),
                ]),
                const SizedBox(height: 24),

                // Emergency Contact Section
                _buildSectionTitle('Emergency Contact'),
                _buildInfoCard([
                  _buildInfoRow(
                    Icons.person,
                    'Name',
                    emergencyContactName,
                  ),
                  _buildInfoRow(
                    Icons.family_restroom,
                    'Relationship',
                    emergencyContactRelationship,
                  ),
                  _buildInfoRow(
                    Icons.phone,
                    'Phone',
                    emergencyContactPhone,
                  ),
                ]),
                const SizedBox(height: 32),

                // Edit Button (Alternative to AppBar button)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/user-dashboard/profile/edit'),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(healthProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
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
}

