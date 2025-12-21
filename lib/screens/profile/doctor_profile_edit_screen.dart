import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/doctor_profile_provider.dart';
import '../../services/profile_service.dart';

class DoctorProfileEditScreen extends ConsumerStatefulWidget {
  const DoctorProfileEditScreen({super.key});

  @override
  ConsumerState<DoctorProfileEditScreen> createState() => _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends ConsumerState<DoctorProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Basic Info
  String? _selectedGender;
  final _experienceController = TextEditingController();
  final _specializationController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  // Clinic Info
  final _clinicNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _feeController = TextEditingController();

  // Availability
  final List<String> _selectedDays = [];
  final List<String> _selectedTimeSlots = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final profileAsync = ref.read(doctorProfileProvider);
    profileAsync.whenData((profile) {
      if (profile != null) {
        setState(() {
          _selectedGender = profile['gender'] as String?;
          _experienceController.text = profile['experience']?.toString() ?? '';
          _specializationController.text = profile['specialization'] as String? ?? '';
          _licenseNumberController.text = profile['licenseNumber'] as String? ?? '';
          _clinicNameController.text = profile['clinicName'] as String? ?? '';
          _feeController.text = profile['consultationFee']?.toString() ?? '';

          final clinicAddress = profile['clinicAddress'] as Map?;
          if (clinicAddress != null) {
            _addressController.text = clinicAddress['fullAddress'] as String? ?? '';
            _cityController.text = clinicAddress['city'] as String? ?? '';
            _pincodeController.text = clinicAddress['pincode'] as String? ?? '';
          }

          final availableDays = profile['availableDays'] as List?;
          if (availableDays != null) {
            _selectedDays.addAll(availableDays.cast<String>());
          }

          final timeSlots = profile['timeSlots'] as List?;
          if (timeSlots != null) {
            _selectedTimeSlots.addAll(timeSlots.cast<String>());
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _experienceController.dispose();
    _specializationController.dispose();
    _licenseNumberController.dispose();
    _clinicNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profileData = {
        'gender': _selectedGender,
        'experience': int.tryParse(_experienceController.text),
        'specialization': _specializationController.text,
        'licenseNumber': _licenseNumberController.text,
        'clinicName': _clinicNameController.text,
        'clinicAddress': {
          'fullAddress': _addressController.text,
          'city': _cityController.text,
          'pincode': _pincodeController.text,
        },
        'consultationFee': int.tryParse(_feeController.text),
        'availableDays': _selectedDays,
        'timeSlots': _selectedTimeSlots,
      };

      final response = await ProfileService.updateProfile(profileData);

      if (mounted) {
        if (response['success']) {
          ref.invalidate(doctorProfileProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else {
          throw Exception(response['message'] ?? 'Failed to update profile');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.person),
                ),
                items: AppConstants.genders
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Years of Experience',
                  prefixIcon: Icon(Icons.work),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specializationController,
                decoration: const InputDecoration(
                  labelText: 'Specialization',
                  prefixIcon: Icon(Icons.medical_services),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseNumberController,
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 32),

              // Clinic Information
              Text(
                'Clinic Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _clinicNameController,
                decoration: const InputDecoration(
                  labelText: 'Clinic Name',
                  prefixIcon: Icon(Icons.local_hospital),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Full Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pincodeController,
                decoration: const InputDecoration(
                  labelText: 'Pincode',
                  prefixIcon: Icon(Icons.pin_drop),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _feeController,
                decoration: const InputDecoration(
                  labelText: 'Consultation Fee (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              // Availability
              Text(
                'Availability',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Available Days',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.daysOfWeek.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryBlue.withOpacity(0.3),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Time Slots',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.timeSlots.map((slot) {
                  final isSelected = _selectedTimeSlots.contains(slot);
                  return FilterChip(
                    label: Text(slot),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTimeSlots.add(slot);
                        } else {
                          _selectedTimeSlots.remove(slot);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryBlue.withOpacity(0.3),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
