import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/profile_wizard_provider.dart';

class UserPersonalStep extends ConsumerStatefulWidget {
  const UserPersonalStep({super.key});

  @override
  ConsumerState<UserPersonalStep> createState() => _UserPersonalStepState();
}

class _UserPersonalStepState extends ConsumerState<UserPersonalStep> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    final data = ref.read(profileWizardProvider);
    _firstNameController.text = data['firstName'] ?? '';
    _lastNameController.text = data['lastName'] ?? '';
    _ageController.text = data['age']?.toString() ?? '';
    _cityController.text = data['city'] ?? '';
    _selectedGender = data['gender'];
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _saveData() {
    final ageValue = int.tryParse(_ageController.text);
    ref.read(profileWizardProvider.notifier).updateMultipleFields({
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'age': ageValue,
      'city': _cityController.text,
      'gender': _selectedGender,
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
            'Personal Information',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Help us know you better',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name',
              prefixIcon: Icon(Icons.person),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => _saveData(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => _saveData(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ageController,
            decoration: const InputDecoration(
              labelText: 'Age',
              prefixIcon: Icon(Icons.cake),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _saveData(),
          ),
          const SizedBox(height: 16),
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
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_city),
            ),
            onChanged: (value) => _saveData(),
          ),
        ],
      ),
    );
  }
}
