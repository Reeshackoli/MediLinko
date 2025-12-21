import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/pharmacist_profile_provider.dart';
import '../../services/profile_service.dart';

class PharmacistProfileEditScreen extends ConsumerStatefulWidget {
  const PharmacistProfileEditScreen({super.key});

  @override
  ConsumerState<PharmacistProfileEditScreen> createState() =>
      _PharmacistProfileEditScreenState();
}

class _PharmacistProfileEditScreenState
    extends ConsumerState<PharmacistProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Basic Info
  final _licenseNumberController = TextEditingController();
  String? _verificationStatus;

  // Store Info
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _deliveryRadiusController = TextEditingController();

  // Operating Hours
  final _openTimeController = TextEditingController();
  final _closeTimeController = TextEditingController();
  final List<String> _selectedOperatingDays = [];

  // Services
  final List<String> _selectedServices = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final profileAsync = ref.read(pharmacistProfileProvider);
    profileAsync.whenData((profile) {
      if (profile != null) {
        setState(() {
          _licenseNumberController.text =
              profile['licenseNumber'] as String? ?? '';
          _verificationStatus = profile['verificationStatus'] as String?;

          _storeNameController.text = profile['storeName'] as String? ?? '';
          _deliveryRadiusController.text =
              profile['deliveryRadius']?.toString() ?? '';

          final storeAddress = profile['storeAddress'] as Map?;
          if (storeAddress != null) {
            // For editing, we'll use separate fields
            _storeAddressController.text = storeAddress['street'] as String? ?? '';
            _cityController.text = storeAddress['city'] as String? ?? '';
            _stateController.text = storeAddress['state'] as String? ?? '';
            _pincodeController.text = storeAddress['pincode'] as String? ?? '';
          }

          final operatingHours = profile['operatingHours'] as Map?;
          if (operatingHours != null) {
            _openTimeController.text = operatingHours['open'] as String? ?? '';
            _closeTimeController.text =
                operatingHours['close'] as String? ?? '';

            final days = operatingHours['days'] as List?;
            if (days != null) {
              _selectedOperatingDays.addAll(days.cast<String>());
            }
          }

          final services = profile['servicesOffered'] as List?;
          if (services != null) {
            _selectedServices.addAll(services.cast<String>());
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _deliveryRadiusController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profileData = {
        'licenseNumber': _licenseNumberController.text,
        'verificationStatus': _verificationStatus,
        'storeName': _storeNameController.text,
        'storeAddress': {
          'street': _storeAddressController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'pincode': _pincodeController.text,
        },
        'deliveryRadius': int.tryParse(_deliveryRadiusController.text),
        'operatingHours': {
          'open': _openTimeController.text,
          'close': _closeTimeController.text,
          'days': _selectedOperatingDays,
        },
        'servicesOffered': _selectedServices,
      };

      final response = await ProfileService.updateProfile(profileData);

      if (mounted) {
        if (response['success']) {
          // Invalidate the provider to refresh data
          ref.invalidate(pharmacistProfileProvider);
          
          // Wait a moment for the provider to refresh
          await Future.delayed(const Duration(milliseconds: 300));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          }
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
              // License Information
              Text(
                'License Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseNumberController,
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter license number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _verificationStatus,
                decoration: const InputDecoration(
                  labelText: 'Verification Status',
                  prefixIcon: Icon(Icons.verified),
                ),
                items: ['pending', 'verified', 'rejected']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(
                            status[0].toUpperCase() + status.substring(1),
                          ),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _verificationStatus = value),
              ),
              const SizedBox(height: 32),

              // Store Information
              Text(
                'Store Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(
                  labelText: 'Store Name',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter store name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _storeAddressController,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter street address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  prefixIcon: Icon(Icons.map),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter state';
                  }
                  return null;
                },
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pincode';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deliveryRadiusController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Radius (km)',
                  prefixIcon: Icon(Icons.delivery_dining),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              // Operating Hours
              Text(
                'Operating Hours',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _openTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Opening Time',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () => _selectTime(context, _openTimeController),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _closeTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Closing Time',
                        prefixIcon: Icon(Icons.access_time_filled),
                      ),
                      readOnly: true,
                      onTap: () => _selectTime(context, _closeTimeController),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Operating Days',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.daysOfWeek.map((day) {
                  final isSelected = _selectedOperatingDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedOperatingDays.add(day);
                        } else {
                          _selectedOperatingDays.remove(day);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryBlue.withOpacity(0.3),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Services Offered
              Text(
                'Services Offered',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
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