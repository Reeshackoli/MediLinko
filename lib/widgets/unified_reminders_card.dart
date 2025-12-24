import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/medicine_reminder_provider.dart';

/// Unified Today's Reminders Card that syncs with Medicine Tracker
/// Groups medicines by name to avoid confusion
class UnifiedRemindersCard extends ConsumerStatefulWidget {
  const UnifiedRemindersCard({super.key});

  @override
  ConsumerState<UnifiedRemindersCard> createState() => _UnifiedRemindersCardState();
}

class _UnifiedRemindersCardState extends ConsumerState<UnifiedRemindersCard> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app resumes
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  void _loadData() {
    Future.microtask(() {
      ref.read(medicineReminderProvider.notifier).loadReminders();
    });
  }

  void _onToggleReminder(MedicineReminder reminder) async {
    final wasAlreadyTaken = reminder.isTaken;
    final success = await ref.read(medicineReminderProvider.notifier).toggleTaken(reminder);
    
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                wasAlreadyTaken ? Icons.undo : Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  wasAlreadyTaken
                      ? '↩️ ${reminder.medicineName} (${reminder.time}) unmarked'
                      : '✓ ${reminder.medicineName} (${reminder.time}) taken!',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: wasAlreadyTaken ? Colors.orange.shade700 : Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Group reminders by medicine name
  Map<String, List<MedicineReminder>> _groupByMedicine(List<MedicineReminder> reminders) {
    final Map<String, List<MedicineReminder>> grouped = {};
    for (var reminder in reminders) {
      if (!grouped.containsKey(reminder.medicineName)) {
        grouped[reminder.medicineName] = [];
      }
      grouped[reminder.medicineName]!.add(reminder);
    }
    
    // Sort doses by time within each group
    grouped.forEach((key, value) {
      value.sort((a, b) => _parseTimeMinutes(a.time).compareTo(_parseTimeMinutes(b.time)));
    });
    
    return grouped;
  }

  int _parseTimeMinutes(String time) {
    try {
      final time24 = _convertTo24Hour(time);
      final parts = time24.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  String _convertTo24Hour(String time12) {
    try {
      final trimmed = time12.trim();
      if (!trimmed.contains('AM') && !trimmed.contains('PM') &&
          !trimmed.contains('am') && !trimmed.contains('pm')) {
        return trimmed;
      }
      final parts = trimmed.split(' ');
      if (parts.length != 2) return trimmed;
      final timePart = parts[0].split(':');
      final period = parts[1].toUpperCase();
      int hour = int.parse(timePart[0]);
      final minute = timePart[1];
      if (period == 'PM' && hour != 12) hour += 12;
      else if (period == 'AM' && hour == 12) hour = 0;
      return '${hour.toString().padLeft(2, '0')}:$minute';
    } catch (e) {
      return time12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicineReminderProvider);
    final reminders = state.reminders;
    final completedCount = state.completedCount;
    final totalCount = state.totalCount;
    final groupedMedicines = _groupByMedicine(reminders);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.coolGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Medicines',
                        style: AppTheme.titleLarge.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalCount == 0
                            ? 'No medicines scheduled'
                            : '$completedCount of $totalCount doses completed',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadData,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Content
          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: _loadData,
                    ),
                  ],
                ),
              ),
            )
          else if (reminders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No medicines for today',
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add medicine'),
                      onPressed: () async {
                        await context.push('/medicine-tracker');
                        _loadData();
                      },
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // Progress Bar
                if (totalCount > 0)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Progress', style: AppTheme.labelMedium),
                            Text(
                              '${(state.progressPercent * 100).toInt()}%',
                              style: AppTheme.labelMedium.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: state.progressPercent,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.successColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Grouped Medicine List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedMedicines.length,
                  itemBuilder: (context, index) {
                    final medicineName = groupedMedicines.keys.elementAt(index);
                    final doses = groupedMedicines[medicineName]!;
                    return _GroupedMedicineTile(
                      medicineName: medicineName,
                      dosage: doses.first.dosage,
                      doses: doses,
                      onToggle: _onToggleReminder,
                    );
                  },
                ),

                // View Tracker Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open Medicine Tracker'),
                      onPressed: () async {
                        await context.push('/medicine-tracker');
                        _loadData();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

/// Grouped medicine tile showing medicine name with multiple time slots
class _GroupedMedicineTile extends StatelessWidget {
  final String medicineName;
  final String dosage;
  final List<MedicineReminder> doses;
  final Function(MedicineReminder) onToggle;

  const _GroupedMedicineTile({
    required this.medicineName,
    required this.dosage,
    required this.doses,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final takenCount = doses.where((d) => d.isTaken).length;
    final allTaken = takenCount == doses.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: allTaken ? AppTheme.successColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allTaken
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.primaryBlue.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medicine Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: allTaken
                        ? LinearGradient(colors: [AppTheme.successColor, AppTheme.successColor.withOpacity(0.8)])
                        : AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicineName,
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: allTaken ? TextDecoration.lineThrough : null,
                          color: allTaken ? Colors.grey : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            dosage,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: allTaken
                                  ? AppTheme.successColor.withOpacity(0.15)
                                  : AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$takenCount/${doses.length} taken',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: allTaken ? AppTheme.successColor : AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (allTaken)
                  const Icon(Icons.check_circle, color: AppTheme.successColor, size: 24),
              ],
            ),
          ),

          // Time Slots (Dose Chips)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: doses.map((dose) {
                return _DoseChip(
                  dose: dose,
                  onTap: () => onToggle(dose),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual dose time chip that can be tapped to toggle
class _DoseChip extends StatelessWidget {
  final MedicineReminder dose;
  final VoidCallback onTap;

  const _DoseChip({
    required this.dose,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: dose.isTaken
                ? AppTheme.successColor.withOpacity(0.15)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: dose.isTaken
                  ? AppTheme.successColor.withOpacity(0.4)
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                dose.isTaken ? Icons.check_circle : Icons.schedule,
                size: 16,
                color: dose.isTaken ? AppTheme.successColor : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                dose.time,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: dose.isTaken ? AppTheme.successColor : AppTheme.textPrimary,
                  decoration: dose.isTaken ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
