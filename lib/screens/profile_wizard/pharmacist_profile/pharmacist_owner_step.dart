import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/profile_wizard_provider.dart';

class PharmacistOwnerStep extends ConsumerStatefulWidget {
  const PharmacistOwnerStep({super.key});

  @override
  ConsumerState<PharmacistOwnerStep> createState() => _PharmacistOwnerStepState();
}

class _PharmacistOwnerStepState extends ConsumerState<PharmacistOwnerStep> {
  final _altPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final data = ref.read(profileWizardProvider);
    _altPhoneController.text = data['altPhone'] ?? '';
  }

  @override
  void dispose() {
    _altPhoneController.dispose();
    super.dispose();
  }

  void _saveData() {
    ref.read(profileWizardProvider.notifier).updateField(
      'altPhone',
      _altPhoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Owner Information',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Additional contact details',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _altPhoneController,
            decoration: const InputDecoration(
              labelText: 'Alternate Phone Number',
              prefixIcon: Icon(Icons.phone_android),
              hintText: 'Optional',
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
