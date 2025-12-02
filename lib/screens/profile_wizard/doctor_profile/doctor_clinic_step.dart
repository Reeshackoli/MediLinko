import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/profile_wizard_provider.dart';

class DoctorClinicStep extends ConsumerStatefulWidget {
  const DoctorClinicStep({super.key});

  @override
  ConsumerState<DoctorClinicStep> createState() => _DoctorClinicStepState();
}

class _DoctorClinicStepState extends ConsumerState<DoctorClinicStep> {
  final _clinicNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _feeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final data = ref.read(profileWizardProvider);
    _clinicNameController.text = data['clinicName'] ?? '';
    _addressController.text = data['fullAddress'] ?? '';
    _cityController.text = data['city'] ?? '';
    _pincodeController.text = data['pincode'] ?? '';
    _feeController.text = data['consultationFee'] ?? '';
    _latitudeController.text = data['clinicLatitude']?.toString() ?? '';
    _longitudeController.text = data['clinicLongitude']?.toString() ?? '';
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _feeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _saveData() {
    ref.read(profileWizardProvider.notifier).updateMultipleFields({
      'clinicName': _clinicNameController.text,
      'fullAddress': _addressController.text,
      'city': _cityController.text,
      'pincode': _pincodeController.text,
      'consultationFee': _feeController.text,
      'clinicLatitude': _latitudeController.text.isNotEmpty
          ? double.tryParse(_latitudeController.text)
          : null,
      'clinicLongitude': _longitudeController.text.isNotEmpty
          ? double.tryParse(_longitudeController.text)
          : null,
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
            'Clinic Details',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Where do you practice?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _clinicNameController,
            decoration: const InputDecoration(
              labelText: 'Clinic/Hospital Name',
              prefixIcon: Icon(Icons.local_hospital),
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
          TextFormField(
            controller: _feeController,
            decoration: const InputDecoration(
              labelText: 'Consultation Fee (₹)',
              prefixIcon: Icon(Icons.currency_rupee),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _saveData(),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Clinic Location (Optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help patients find your clinic on the map',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    prefixIcon: Icon(Icons.my_location),
                    hintText: 'e.g., 12.9716',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  onChanged: (value) => _saveData(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    prefixIcon: Icon(Icons.location_on),
                    hintText: 'e.g., 77.5946',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  onChanged: (value) => _saveData(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4C9AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: const Color(0xFF4C9AFF),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can find coordinates using Google Maps or any map service',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
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
