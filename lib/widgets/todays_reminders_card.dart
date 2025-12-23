import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants/api_config.dart';
import '../core/theme/app_theme.dart';
import '../services/token_service.dart';

class TodaysRemindersCard extends StatefulWidget {
  const TodaysRemindersCard({super.key});

  @override
  State<TodaysRemindersCard> createState() => _TodaysRemindersCardState();
}

class _TodaysRemindersCardState extends State<TodaysRemindersCard> {
  List<TodayReminder> _todaysReminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodaysReminders();
  }

  Future<void> _loadTodaysReminders() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await TokenService().getToken();
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/medicine-reminders/today?date=$today'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List remindersJson = data['reminders'] ?? [];
        
        setState(() {
          _todaysReminders = remindersJson
              .map((r) => TodayReminder.fromJson(r))
              .toList();
          _todaysReminders.sort((a, b) => a.time.compareTo(b.time));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading today\'s reminders: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsTaken(TodayReminder reminder) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return;

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/medicine-reminders/${reminder.id}/mark-taken'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'date': DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _todaysReminders.indexWhere((r) => r.id == reminder.id);
          if (index != -1) {
            _todaysReminders[index] = _todaysReminders[index].copyWith(isTaken: true);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('✓ ${reminder.medicineName} marked as taken'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error marking reminder as taken: $e');
    }
  }

  Future<void> _unmarkAsTaken(TodayReminder reminder) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return;

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/medicine-reminders/${reminder.id}/unmark-taken'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'date': DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _todaysReminders.indexWhere((r) => r.id == reminder.id);
          if (index != -1) {
            _todaysReminders[index] = _todaysReminders[index].copyWith(isTaken: false);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.undo, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('↩️ ${reminder.medicineName} unmarked'),
                ],
              ),
              backgroundColor: AppTheme.warningColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error unmarking reminder: $e');
    }
  }

  void _toggleReminder(TodayReminder reminder) {
    if (reminder.isTaken) {
      _unmarkAsTaken(reminder);
    } else {
      _markAsTaken(reminder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _todaysReminders.where((r) => r.isTaken).length;
    final totalCount = _todaysReminders.length;

    return Card(
      margin: const EdgeInsets.all(16),
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
                        'Today\'s Reminders',
                        style: AppTheme.titleLarge.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalCount == 0
                            ? 'No reminders for today'
                            : '$completedCount of $totalCount completed',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  onPressed: () => context.push('/medicine-tracker'),
                  tooltip: 'Add Reminder',
                ),
              ],
            ),
          ),

          // Content
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _todaysReminders.isEmpty
                  ? Padding(
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
                              'No reminders for today',
                              style: AppTheme.bodyLarge.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add your first reminder'),
                              onPressed: () => context.push('/medicine-tracker'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
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
                                    Text(
                                      'Progress',
                                      style: AppTheme.labelMedium,
                                    ),
                                    Text(
                                      '${((completedCount / totalCount) * 100).toInt()}%',
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
                                    value: completedCount / totalCount,
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

                        // Reminder List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _todaysReminders.length > 3 ? 3 : _todaysReminders.length,
                          itemBuilder: (context, index) {
                            final reminder = _todaysReminders[index];
                            return _ReminderTile(
                              reminder: reminder,
                              onTap: () => _toggleReminder(reminder),
                            );
                          },
                        ),

                        // View All Button
                        if (_todaysReminders.length > 3)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: TextButton(
                              onPressed: () => context.push('/medicine-tracker'),
                              child: Text(
                                'View all ${_todaysReminders.length} reminders',
                                style: AppTheme.labelLarge.copyWith(
                                  color: AppTheme.primaryBlue,
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

class _ReminderTile extends StatelessWidget {
  final TodayReminder reminder;
  final VoidCallback onTap;

  const _ReminderTile({
    required this.reminder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: reminder.isTaken ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reminder.isTaken 
              ? Colors.grey.shade300 
              : AppTheme.primaryBlue.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: reminder.isTaken 
                  ? AppTheme.successColor 
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: reminder.isTaken 
                    ? AppTheme.successColor 
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Icon(
              reminder.isTaken ? Icons.check_rounded : Icons.medication_outlined,
              color: reminder.isTaken ? Colors.white : AppTheme.primaryBlue,
            ),
          ),
        ),
        title: Text(
          reminder.medicineName,
          style: AppTheme.titleMedium.copyWith(
            decoration: reminder.isTaken ? TextDecoration.lineThrough : null,
            color: reminder.isTaken ? Colors.grey : AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          '${reminder.dosage} • ${reminder.time}',
          style: AppTheme.bodySmall.copyWith(
            color: reminder.isTaken ? Colors.grey : AppTheme.textSecondary,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            reminder.isTaken ? Icons.check_circle : Icons.circle_outlined,
            color: reminder.isTaken ? AppTheme.successColor : Colors.grey.shade400,
          ),
          onPressed: onTap,
          tooltip: reminder.isTaken ? 'Tap to unmark' : 'Tap to mark as taken',
        ),
      ),
    );
  }
}

class TodayReminder {
  final String id;
  final String medicineName;
  final String dosage;
  final String time;
  final bool isTaken;

  TodayReminder({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.time,
    required this.isTaken,
  });

  factory TodayReminder.fromJson(Map<String, dynamic> json) {
    return TodayReminder(
      id: json['_id'] ?? json['id'] ?? '',
      medicineName: json['medicineName'] ?? json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      time: json['time'] ?? '',
      isTaken: json['isTaken'] ?? false,
    );
  }

  TodayReminder copyWith({
    String? id,
    String? medicineName,
    String? dosage,
    String? time,
    bool? isTaken,
  }) {
    return TodayReminder(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      isTaken: isTaken ?? this.isTaken,
    );
  }
}
