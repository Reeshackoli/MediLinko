import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/profile_wizard_provider.dart';

class DoctorTimingsStep extends ConsumerStatefulWidget {
  const DoctorTimingsStep({super.key});

  @override
  ConsumerState<DoctorTimingsStep> createState() => _DoctorTimingsStepState();
}

class _DoctorTimingsStepState extends ConsumerState<DoctorTimingsStep> {
  final Set<String> _selectedDays = {};
  final Set<String> _selectedSlots = {};

  @override
  void initState() {
    super.initState();
    final data = ref.read(profileWizardProvider);
    _selectedDays.addAll((data['availableDays'] as List<String>?) ?? []);
    _selectedSlots.addAll((data['timeSlots'] as List<String>?) ?? []);
  }

  void _saveData() {
    ref.read(profileWizardProvider.notifier).updateMultipleFields({
      'availableDays': _selectedDays.toList(),
      'timeSlots': _selectedSlots.toList(),
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
            'Availability',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'When are you available for consultations?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Text(
            'Available Days',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
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
                  _saveData();
                },
                selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryBlue,
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text(
            'Time Slots',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...AppConstants.timeSlots.map((slot) {
            final isSelected = _selectedSlots.contains(slot);
            return CheckboxListTile(
              title: Text(slot),
              value: isSelected,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedSlots.add(slot);
                  } else {
                    _selectedSlots.remove(slot);
                  }
                });
                _saveData();
              },
              activeColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      ),
    );
  }
}
