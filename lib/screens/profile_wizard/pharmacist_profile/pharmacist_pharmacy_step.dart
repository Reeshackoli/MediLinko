import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/profile_wizard_provider.dart';

class PharmacistPharmacyStep extends ConsumerStatefulWidget {
  const PharmacistPharmacyStep({super.key});

  @override
  ConsumerState<PharmacistPharmacyStep> createState() => _PharmacistPharmacyStepState();
}

class _PharmacistPharmacyStepState extends ConsumerState<PharmacistPharmacyStep> {
  final _pharmacyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  @override
  void initState() {
    super.initState();
    final data = ref.read(profileWizardProvider);
    _pharmacyNameController.text = data['pharmacyName'] ?? '';
    _addressController.text = data['fullAddress'] ?? '';
    _cityController.text = data['city'] ?? '';
    _pincodeController.text = data['pincode'] ?? '';
    
    if (data['openingTime'] != null) {
      final parts = (data['openingTime'] as String).split(':');
      if (parts.length == 2) {
        _openingTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
    
    if (data['closingTime'] != null) {
      final parts = (data['closingTime'] as String).split(':');
      if (parts.length == 2) {
        _closingTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  @override
  void dispose() {
    _pharmacyNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _saveData() {
    ref.read(profileWizardProvider.notifier).updateMultipleFields({
      'pharmacyName': _pharmacyNameController.text,
      'fullAddress': _addressController.text,
      'city': _cityController.text,
      'pincode': _pincodeController.text,
      'openingTime': _openingTime != null
          ? '${_openingTime!.hour.toString().padLeft(2, '0')}:${_openingTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'closingTime': _closingTime != null
          ? '${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')}'
          : null,
    });
  }

  Future<void> _selectTime(BuildContext context, bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpening
          ? (_openingTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_closingTime ?? const TimeOfDay(hour: 21, minute: 0)),
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
      _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pharmacy Details',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Information about your pharmacy',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _pharmacyNameController,
            decoration: const InputDecoration(
              labelText: 'Pharmacy Name',
              prefixIcon: Icon(Icons.local_pharmacy),
            ),
            onChanged: (value) => _saveData(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Full Address',
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 3,
            onChanged: (value) => _saveData(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  onChanged: (value) => _saveData(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _pincodeController,
                  decoration: const InputDecoration(
                    labelText: 'Pincode',
                    prefixIcon: Icon(Icons.pin_drop),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  onChanged: (value) => _saveData(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context, true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Opening Time',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(
                      _openingTime != null
                          ? _openingTime!.format(context)
                          : 'Select time',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Closing Time',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(
                      _closingTime != null
                          ? _closingTime!.format(context)
                          : 'Select time',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
