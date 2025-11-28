import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/profile_wizard_provider.dart';

class UserHealthStep extends ConsumerStatefulWidget {
  const UserHealthStep({super.key});

  @override
  ConsumerState<UserHealthStep> createState() => _UserHealthStepState();
}

class _UserHealthStepState extends ConsumerState<UserHealthStep> {
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _medicinesController = TextEditingController();
  String? _selectedBloodGroup;

  @override
  void initState() {
    super.initState();
    final data = ref.read(profileWizardProvider);
    _selectedBloodGroup = data['bloodGroup'];
    _allergiesController.text = (data['allergies'] as List<String>?)?.join(', ') ?? '';
    _conditionsController.text = (data['medicalConditions'] as List<String>?)?.join(', ') ?? '';
    _medicinesController.text = (data['currentMedicines'] as List<String>?)?.join(', ') ?? '';
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicinesController.dispose();
    super.dispose();
  }

  void _saveData() {
    ref.read(profileWizardProvider.notifier).updateMultipleFields({
      'bloodGroup': _selectedBloodGroup,
      'allergies': _allergiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'medicalConditions': _conditionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'currentMedicines': _medicinesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
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
            'Health Information',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your medical details for better care',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            value: _selectedBloodGroup,
            decoration: const InputDecoration(
              labelText: 'Blood Group',
              prefixIcon: Icon(Icons.bloodtype),
            ),
            items: AppConstants.bloodGroups
                .map((group) => DropdownMenuItem(
                      value: group,
                      child: Text(group),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedBloodGroup = value);
              _saveData();
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _allergiesController,
            decoration: const InputDecoration(
              labelText: 'Allergies (comma separated)',
              prefixIcon: Icon(Icons.warning_amber),
              hintText: 'e.g., Penicillin, Peanuts',
            ),
            maxLines: 2,
            onChanged: (value) => _saveData(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _conditionsController,
            decoration: const InputDecoration(
              labelText: 'Medical Conditions (comma separated)',
              prefixIcon: Icon(Icons.medical_information),
              hintText: 'e.g., Diabetes, Hypertension',
            ),
            maxLines: 2,
            onChanged: (value) => _saveData(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _medicinesController,
            decoration: const InputDecoration(
              labelText: 'Current Medicines (comma separated)',
              prefixIcon: Icon(Icons.medication),
              hintText: 'e.g., Aspirin, Metformin',
            ),
            maxLines: 2,
            onChanged: (value) => _saveData(),
          ),
        ],
      ),
    );
  }
}
