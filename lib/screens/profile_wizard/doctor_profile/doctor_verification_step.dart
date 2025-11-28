import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/profile_wizard_provider.dart';

class DoctorVerificationStep extends ConsumerStatefulWidget {
  const DoctorVerificationStep({super.key});

  @override
  ConsumerState<DoctorVerificationStep> createState() => _DoctorVerificationStepState();
}

class _DoctorVerificationStepState extends ConsumerState<DoctorVerificationStep> {
  final _licenseController = TextEditingController();
  String? _documentPath;

  @override
  void initState() {
    super.initState();
    final data = ref.read(profileWizardProvider);
    _licenseController.text = data['licenseNumber'] ?? '';
    _documentPath = data['documentUrl'];
  }

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  void _saveData() {
    ref.read(profileWizardProvider.notifier).updateMultipleFields({
      'licenseNumber': _licenseController.text,
      'documentUrl': _documentPath,
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
            'Verification',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Verify your medical license',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _licenseController,
            decoration: const InputDecoration(
              labelText: 'Medical License Number',
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
          InkWell(
            onTap: _pickDocument,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
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
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'PDF, JPG, or PNG (max 5MB)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
