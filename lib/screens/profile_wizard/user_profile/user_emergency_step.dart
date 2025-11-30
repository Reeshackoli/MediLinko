import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/profile_wizard_provider.dart';

class UserEmergencyStep extends ConsumerStatefulWidget {
  const UserEmergencyStep({super.key});

  @override
  ConsumerState<UserEmergencyStep> createState() => _UserEmergencyStepState();
}

class _UserEmergencyStepState extends ConsumerState<UserEmergencyStep> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedRelationship;

  @override
  void initState() {
    super.initState();
    final data = ref.read(profileWizardProvider);
    _nameController.text = data['emergencyContactName'] ?? '';
    _phoneController.text = data['emergencyContactPhone'] ?? '';
    _selectedRelationship = data['emergencyContactRelationship'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveData() {
    ref.read(profileWizardProvider.notifier).updateMultipleFields({
      'emergencyContactName': _nameController.text,
      'emergencyContactPhone': _phoneController.text,
      'emergencyContactRelationship': _selectedRelationship,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Contact',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Someone we can reach in case of emergency',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Contact Name',
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (value) => _saveData(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRelationship,
            decoration: const InputDecoration(
              labelText: 'Relationship',
              prefixIcon: Icon(Icons.people),
            ),
            items: AppConstants.relationships
                .map((rel) => DropdownMenuItem(
                      value: rel,
                      child: Text(rel),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedRelationship = value);
              _saveData();
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Contact Phone',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            onChanged: (value) => _saveData(),
          ),
        ],
      ),
    );
  }
}
