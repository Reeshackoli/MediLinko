import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
// geolocation removed: pharmacist should enter coords manually in pharmacy step
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/profile_wizard_provider.dart';

class PharmacistVerificationStep extends ConsumerStatefulWidget {
  const PharmacistVerificationStep({super.key});

  @override
  ConsumerState<PharmacistVerificationStep> createState() =>
      _PharmacistVerificationStepState();
}

class _PharmacistVerificationStepState
    extends ConsumerState<PharmacistVerificationStep> {
  final _licenseController = TextEditingController();
  final _radiusController = TextEditingController();
  String? _documentPath;
  final Set<String> _selectedServices = {};
  // coordinates handled in the pharmacy step; do not capture current location here

  @override
  void initState() {
    super.initState();
    final data = ref.read(profileWizardProvider);
    _licenseController.text = data['pharmacyLicenseNumber'] ?? '';
    _radiusController.text = data['deliveryRadius'] ?? '';
    _documentPath = data['documentUrl'];
    _selectedServices.addAll((data['servicesOffered'] as List<String>?) ?? []);
    // pharmacy latitude/longitude come from previous wizard step; no auto-capture
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _saveData() {
    ref.read(profileWizardProvider.notifier).updateMultipleFields({
      'pharmacyLicenseNumber': _licenseController.text,
      'documentUrl': _documentPath,
      'servicesOffered': _selectedServices.toList(),
      'deliveryRadius': _radiusController.text,
      // coordinates are saved by pharmacy details step
    });
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _documentPath = result.files.single.path ?? result.files.single.name;
        });
        _saveData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
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
            'Verification & Services',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your pharmacy registration',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _licenseController,
            decoration: const InputDecoration(
              labelText: 'Pharmacy License Number',
              prefixIcon: Icon(Icons.badge),
            ),
            onChanged: (value) => _saveData(),
          ),
          const SizedBox(height: 24),
          Text(
            'Upload License Document',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          // Location is provided in the Pharmacy Details step; no auto-capture here.
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDocument,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.cardBackground,
              ),
              child: Column(
                children: [
                  Icon(
                    _documentPath != null ? Icons.check_circle : Icons.upload_file,
                    size: 48,
                    color: _documentPath != null
                        ? AppTheme.successColor
                        : AppTheme.primaryBlue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _documentPath != null
                        ? 'Document uploaded'
                        : 'Tap to upload document',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _documentPath != null
                              ? AppTheme.successColor
                              : AppTheme.primaryBlue,
                        ),
                  ),
                  if (_documentPath != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _documentPath!.split('/').last,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Services Offered',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.pharmacyServices.map((service) {
              final isSelected = _selectedServices.contains(service);
              return FilterChip(
                label: Text(service),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedServices.add(service);
                    } else {
                      _selectedServices.remove(service);
                    }
                  });
                  _saveData();
                },
                selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryBlue,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _radiusController,
            decoration: const InputDecoration(
              labelText: 'Delivery Radius (km)',
              prefixIcon: Icon(Icons.delivery_dining),
              hintText: 'e.g., 5',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _saveData(),
          ),
        ],
      ),
    );
  }
}
