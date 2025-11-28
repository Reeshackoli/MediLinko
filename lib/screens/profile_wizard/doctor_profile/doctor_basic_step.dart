import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/profile_wizard_provider.dart';

class DoctorBasicStep extends ConsumerStatefulWidget {
  const DoctorBasicStep({super.key});

  @override
  ConsumerState<DoctorBasicStep> createState() => _DoctorBasicStepState();
}

class _DoctorBasicStepState extends ConsumerState<DoctorBasicStep> {
  final _experienceController = TextEditingController();
  String? _selectedGender;
  String? _selectedSpecialization;

  @override
  void initState() {
    super.initState();
    final data = ref.read(profileWizardProvider);
    _experienceController.text = data['experience'] ?? '';
    _selectedGender = data['gender'];
    _selectedSpecialization = data['specialization'];
  }

  @override
  void dispose() {
    _experienceController.dispose();
    super.dispose();
  }

  void _saveData() {
    ref.read(profileWizardProvider.notifier).updateMultipleFields({
      'gender': _selectedGender,
      'experience': _experienceController.text,
      'specialization': _selectedSpecialization,
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
            'Basic Information',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your professional background',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: AppConstants.genders
                .map((gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedGender = value);
              _saveData();
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _experienceController,
            decoration: const InputDecoration(
              labelText: 'Years of Experience',
              prefixIcon: Icon(Icons.work),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _saveData(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedSpecialization,
            decoration: const InputDecoration(
              labelText: 'Specialization',
              prefixIcon: Icon(Icons.medical_services),
            ),
            items: AppConstants.specializations
                .map((spec) => DropdownMenuItem(
                      value: spec,
                      child: Text(spec),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedSpecialization = value);
              _saveData();
            },
          ),
        ],
      ),
    );
  }
}
