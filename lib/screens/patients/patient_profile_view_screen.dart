import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/profile_service.dart';

class PatientProfileViewScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;

  const PatientProfileViewScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<PatientProfileViewScreen> createState() => _PatientProfileViewScreenState();
}

class _PatientProfileViewScreenState extends ConsumerState<PatientProfileViewScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _patientData;
  Map<String, dynamic>? _healthProfile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load health profile
      final healthResponse = await ProfileService.getHealthProfile(widget.patientId);
      
      if (healthResponse['success'] == true) {
        setState(() {
          _healthProfile = healthResponse['healthProfile'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = healthResponse['message'] ?? 'Failed to load patient data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading patient data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient: ${widget.patientName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPatientData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Basic Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                                child: const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.patientName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Patient ID: ${widget.patientId.substring(0, 8)}...',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Health Information
                      if (_healthProfile != null) ...[
                        Text(
                          'Health Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        
                        // Personal Details
                        _InfoCard(
                          title: 'Personal Details',
                          icon: Icons.person_outline,
                          items: [
                            if (_healthProfile!['age'] != null)
                              _InfoItem(label: 'Age', value: '${_healthProfile!['age']} years'),
                            if (_healthProfile!['gender'] != null)
                              _InfoItem(label: 'Gender', value: _healthProfile!['gender']),
                            if (_healthProfile!['city'] != null)
                              _InfoItem(label: 'City', value: _healthProfile!['city']),
                            if (_healthProfile!['bloodGroup'] != null)
                              _InfoItem(label: 'Blood Group', value: _healthProfile!['bloodGroup']),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Medical Information
                        _InfoCard(
                          title: 'Medical Information',
                          icon: Icons.medical_information,
                          items: [
                            if (_healthProfile!['allergies'] != null && (_healthProfile!['allergies'] as List).isNotEmpty)
                              _InfoItem(
                                label: 'Allergies',
                                value: (_healthProfile!['allergies'] as List).join(', '),
                              ),
                            if (_healthProfile!['medicalConditions'] != null && (_healthProfile!['medicalConditions'] as List).isNotEmpty)
                              _InfoItem(
                                label: 'Medical Conditions',
                                value: (_healthProfile!['medicalConditions'] as List).join(', '),
                              ),
                            if (_healthProfile!['currentMedications'] != null && (_healthProfile!['currentMedications'] as List).isNotEmpty)
                              _InfoItem(
                                label: 'Current Medications',
                                value: (_healthProfile!['currentMedications'] as List).join(', '),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Emergency Contact
                        _InfoCard(
                          title: 'Emergency Contact',
                          icon: Icons.emergency,
                          items: [
                            if (_healthProfile!['emergencyContactName'] != null)
                              _InfoItem(
                                label: 'Name',
                                value: _healthProfile!['emergencyContactName'],
                              ),
                            if (_healthProfile!['emergencyContactRelationship'] != null)
                              _InfoItem(
                                label: 'Relationship',
                                value: _healthProfile!['emergencyContactRelationship'],
                              ),
                            if (_healthProfile!['emergencyContactPhone'] != null)
                              _InfoItem(
                                label: 'Phone',
                                value: _healthProfile!['emergencyContactPhone'],
                              ),
                          ],
                        ),
                      ] else ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No health profile available for this patient',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoItem> items;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryBlue),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: item,
                )),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
