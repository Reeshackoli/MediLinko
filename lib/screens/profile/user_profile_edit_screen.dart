import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/health_profile_provider.dart';
import '../../services/profile_service.dart';
import '../../core/theme/app_theme.dart';

class UserProfileEditScreen extends ConsumerStatefulWidget {
  const UserProfileEditScreen({super.key});

  @override
  ConsumerState<UserProfileEditScreen> createState() =>
      _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends ConsumerState<UserProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;
  late TextEditingController _cityController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyRelationshipController;
  late TextEditingController _emergencyPhoneController;

  String? _selectedGender;
  String? _selectedBloodGroup;
  List<String> _allergies = [];
  List<String> _medicalConditions = [];
  List<String> _currentMedications = [];

  final TextEditingController _allergyController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _medicationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _ageController = TextEditingController();
    _cityController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyRelationshipController = TextEditingController();
    _emergencyPhoneController = TextEditingController();

    // Load existing data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  void _loadProfileData() {
    final profile = ref.read(healthProfileProvider).value;
    if (profile != null) {
      setState(() {
        _firstNameController.text = profile['firstName'] as String? ?? '';
        _lastNameController.text = profile['lastName'] as String? ?? '';
        _ageController.text = (profile['age'] as int? ?? 0).toString();
        _selectedGender = profile['gender'] as String?;
        _cityController.text = profile['city'] as String? ?? '';
        _selectedBloodGroup = profile['bloodGroup'] as String?;
        _allergies = (profile['allergies'] as List?)?.cast<String>() ?? [];
        _medicalConditions = (profile['medicalConditions'] as List?)?.cast<String>() ?? [];
        _currentMedications = (profile['currentMedications'] as List?)?.cast<String>() ?? [];
        
        // Handle both old nested and new flat emergency contact structure
        if (profile.containsKey('emergencyContact') && profile['emergencyContact'] is Map) {
          // Old nested structure
          final ec = profile['emergencyContact'] as Map<String, dynamic>;
          _emergencyNameController.text = ec['name'] as String? ?? '';
          _emergencyPhoneController.text = ec['phone'] as String? ?? '';
          _emergencyRelationshipController.text = '';
        } else {
          // New flat structure
          _emergencyNameController.text = profile['emergencyContactName'] as String? ?? '';
          _emergencyRelationshipController.text =
              profile['emergencyContactRelationship'] as String? ?? '';
          _emergencyPhoneController.text = profile['emergencyContactPhone'] as String? ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyPhoneController.dispose();
    _allergyController.dispose();
    _conditionController.dispose();
    _medicationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profileData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _selectedGender,
        'city': _cityController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'allergies': _allergies,
        'medicalConditions': _medicalConditions,
        'currentMedications': _currentMedications,
        'emergencyContactName': _emergencyNameController.text.trim(),
        'emergencyContactRelationship':
            _emergencyRelationshipController.text.trim(),
        'emergencyContactPhone': _emergencyPhoneController.text.trim(),
      };

      final response = await ProfileService.updateProfile(profileData);
      
      if (response['success'] == true) {
        // Refresh profile data
        ref.invalidate(healthProfileProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          context.pop();
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Personal Information
            _buildSectionTitle('Personal Information'),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: ['Male', 'Female', 'Other']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedGender = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 32),

            // Health Information
            _buildSectionTitle('Health Information'),
            DropdownButtonFormField<String>(
              value: _selectedBloodGroup,
              decoration: const InputDecoration(labelText: 'Blood Group'),
              items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                  .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedBloodGroup = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Allergies
            _buildListEditor(
              title: 'Allergies',
              items: _allergies,
              controller: _allergyController,
              onAdd: () {
                if (_allergyController.text.isNotEmpty) {
                  setState(() => _allergies.add(_allergyController.text.trim()));
                  _allergyController.clear();
                }
              },
              onRemove: (index) => setState(() => _allergies.removeAt(index)),
            ),
            const SizedBox(height: 16),

            // Medical Conditions
            _buildListEditor(
              title: 'Medical Conditions',
              items: _medicalConditions,
              controller: _conditionController,
              onAdd: () {
                if (_conditionController.text.isNotEmpty) {
                  setState(() =>
                      _medicalConditions.add(_conditionController.text.trim()));
                  _conditionController.clear();
                }
              },
              onRemove: (index) =>
                  setState(() => _medicalConditions.removeAt(index)),
            ),
            const SizedBox(height: 16),

            // Current Medications
            _buildListEditor(
              title: 'Current Medications',
              items: _currentMedications,
              controller: _medicationController,
              onAdd: () {
                if (_medicationController.text.isNotEmpty) {
                  setState(() =>
                      _currentMedications.add(_medicationController.text.trim()));
                  _medicationController.clear();
                }
              },
              onRemove: (index) =>
                  setState(() => _currentMedications.removeAt(index)),
            ),
            const SizedBox(height: 32),

            // Emergency Contact
            _buildSectionTitle('Emergency Contact'),
            TextFormField(
              controller: _emergencyNameController,
              decoration: const InputDecoration(labelText: 'Contact Name'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyRelationshipController,
              decoration: const InputDecoration(labelText: 'Relationship'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyPhoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildListEditor({
    required String title,
    required List<String> items,
    required TextEditingController controller,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: title,
                  hintText: 'Add $title',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryBlue),
              onPressed: onAdd,
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: items.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value),
                onDeleted: () => onRemove(entry.key),
                deleteIcon: const Icon(Icons.close, size: 18),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
