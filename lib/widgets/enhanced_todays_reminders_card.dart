import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants/api_config.dart';
import '../core/theme/app_theme.dart';
import '../services/token_service.dart';

class EnhancedTodaysRemindersCard extends StatefulWidget {
  const EnhancedTodaysRemindersCard({super.key});

  @override
  State<EnhancedTodaysRemindersCard> createState() => _EnhancedTodaysRemindersCardState();
}

class _EnhancedTodaysRemindersCardState extends State<EnhancedTodaysRemindersCard> with AutomaticKeepAliveClientMixin {
  List<MedicineReminder> _reminders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => false; // Don't keep state alive

  @override
  void initState() {
    super.initState();
    _loadTodaysReminders();
  }

  // Public method to refresh data
  void refresh() {
    _loadTodaysReminders();
  }

  Future<void> _loadTodaysReminders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final token = await TokenService().getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login to view reminders';
        });
        return;
      }

      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines/by-date?date=$dateKey'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List medicinesJson = data['data'] ?? [];
          final List<MedicineReminder> allReminders = [];
          
          for (var medJson in medicinesJson) {
            final medicineName = medJson['medicineName'] ?? 'Unknown Medicine';
            final dosage = medJson['dosage'] ?? '';
            final notes = medJson['notes'];
            final medicineId = medJson['_id'] ?? medJson['id'];
            final List takenHistory = medJson['takenHistory'] ?? [];
            
            final List doses = medJson['doses'] ?? [];
            for (var dose in doses) {
              final time = dose['time'] ?? '';
              final instruction = dose['instruction'];
              final doseId = dose['_id'] ?? dose['id'];
              
              // Convert dose time to 24-hour format for comparison
              final time24 = _convertTo24Hour(time);
              
              // Check if already taken today at this time
              final isTaken = takenHistory.any((h) {
                if (h['date'] != dateKey) return false;
                
                // Normalize the time from history (could be either format)
                final historyTime = h['time'] ?? '';
                final historyTime24 = _convertTo24Hour(historyTime);
                
                return historyTime24 == time24;
              });
              
              allReminders.add(MedicineReminder(
                medicineId: medicineId,
                doseId: doseId,
                medicineName: medicineName,
                dosage: dosage,
                time: time,
                instruction: instruction,
                notes: notes,
                isTaken: isTaken,
              ));
            }
          }
          
          // Group by medicine name
          final Map<String, List<MedicineReminder>> groupedReminders = {};
          for (var reminder in allReminders) {
            if (!groupedReminders.containsKey(reminder.medicineName)) {
              groupedReminders[reminder.medicineName] = [];
            }
            groupedReminders[reminder.medicineName]!.add(reminder);
          }
          
          // Sort doses within each medicine by time
          groupedReminders.forEach((key, value) {
            value.sort((a, b) {
              final aTime = _parseTime(a.time);
              final bTime = _parseTime(b.time);
              return aTime.compareTo(bTime);
            });
          });
          
          setState(() {
            _reminders = allReminders;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Failed to load reminders';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch reminders';
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading reminders: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  String _convertTo24Hour(String time12) {
    try {
      final trimmed = time12.trim();
      
      // Check if it's already in 24-hour format (no AM/PM)
      if (!trimmed.contains('AM') && !trimmed.contains('PM') && 
          !trimmed.contains('am') && !trimmed.contains('pm')) {
        // Already in 24-hour format, just ensure proper formatting
        final parts = trimmed.split(':');
        if (parts.length == 2) {
          return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
        }
        return trimmed;
      }
      
      // Convert from 12-hour to 24-hour format
      final parts = trimmed.split(' ');
      if (parts.length != 2) return trimmed;
      
      final timePart = parts[0].split(':');
      final period = parts[1].toUpperCase();
      
      int hour = int.parse(timePart[0]);
      final minute = timePart[1];
      
      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }
      
      return '${hour.toString().padLeft(2, '0')}:$minute';
    } catch (e) {
      debugPrint('Error converting time "$time12": $e');
      return time12;
    }
  }

  int _parseTime(String time) {
    try {
      final time24 = _convertTo24Hour(time);
      final parts = time24.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  Future<void> _markAsTaken(MedicineReminder reminder) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return;

      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final time24 = _convertTo24Hour(reminder.time);

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines/${reminder.medicineId}/mark-taken'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'date': dateKey,
          'time': time24,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _reminders.indexWhere((r) => 
            r.medicineId == reminder.medicineId && r.time == reminder.time
          );
          if (index != -1) {
            _reminders[index] = _reminders[index].copyWith(isTaken: true);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '✓ ${reminder.medicineName} marked as taken!',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error marking as taken: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as taken: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unmarkAsTaken(MedicineReminder reminder) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return;

      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final time24 = _convertTo24Hour(reminder.time);

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines/${reminder.medicineId}/unmark-taken'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'date': dateKey,
          'time': time24,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _reminders.indexWhere((r) => 
            r.medicineId == reminder.medicineId && r.time == reminder.time
          );
          if (index != -1) {
            _reminders[index] = _reminders[index].copyWith(isTaken: false);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unmarked ${reminder.medicineName}'),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error unmarking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Medicine Reminders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getHeaderSubtitle(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadTodaysReminders,
                ),
              ],
            ),
          ),

          // Content
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadTodaysReminders,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _reminders.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline, 
                                color: Colors.green.shade300, size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'No medicines scheduled for today',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enjoy your day! 😊',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            // Group reminders by medicine name
                            final Map<String, List<MedicineReminder>> groupedReminders = {};
                            for (var reminder in _reminders) {
                              if (!groupedReminders.containsKey(reminder.medicineName)) {
                                groupedReminders[reminder.medicineName] = [];
                              }
                              groupedReminders[reminder.medicineName]!.add(reminder);
                            }
                            
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              itemCount: groupedReminders.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final medicineName = groupedReminders.keys.elementAt(index);
                                final doses = groupedReminders[medicineName]!;
                                return _buildGroupedMedicineCard(medicineName, doses);
                              },
                            );
                          },
                        ),
        ],
      ),
    );
  }

  Widget _buildGroupedMedicineCard(String medicineName, List<MedicineReminder> doses) {
    final takenCount = doses.where((d) => d.isTaken).length;
    final totalCount = doses.length;
    final allTaken = takenCount == totalCount;
    final hasUpcoming = doses.any((d) {
      if (d.isTaken) return false;
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;
      final doseMinutes = _parseTime(d.time);
      return !d.isTaken && (doseMinutes - currentMinutes) < 60 && (doseMinutes - currentMinutes) > 0;
    });
    
    // Get shared info from first dose
    final firstDose = doses.first;

    return Container(
      decoration: BoxDecoration(
        color: allTaken 
            ? Colors.green.shade50 
            : hasUpcoming 
                ? Colors.orange.shade50 
                : Colors.white,
        border: Border.all(
          color: allTaken 
              ? Colors.green.shade200 
              : hasUpcoming 
                  ? Colors.orange.shade200 
                  : Colors.grey.shade200,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: allTaken 
                        ? Colors.green.shade100 
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: allTaken 
                        ? Colors.green.shade700 
                        : Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicineName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: allTaken ? TextDecoration.lineThrough : null,
                          color: allTaken ? Colors.grey.shade600 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.medication_liquid, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            firstDose.dosage,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: allTaken 
                                  ? Colors.green.shade100 
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$takenCount of $totalCount taken',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: allTaken 
                                    ? Colors.green.shade700 
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (allTaken)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
                  ),
              ],
            ),
            
            if (firstDose.notes != null && firstDose.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        firstDose.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            // Individual Doses
            ...doses.asMap().entries.map((entry) {
              final index = entry.key;
              final dose = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < doses.length - 1 ? 8 : 0),
                child: _buildDoseItem(dose),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseItem(MedicineReminder dose) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final doseMinutes = _parseTime(dose.time);
    final isUpcoming = !dose.isTaken && (doseMinutes - currentMinutes) < 60 && (doseMinutes - currentMinutes) > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: dose.isTaken 
            ? () => _unmarkAsTaken(dose)
            : () => _markAsTaken(dose),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dose.isTaken 
                ? Colors.green.shade50 
                : isUpcoming 
                    ? Colors.orange.shade50 
                    : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: dose.isTaken 
                  ? Colors.green.shade200 
                  : isUpcoming 
                      ? Colors.orange.shade200 
                      : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: dose.isTaken 
                    ? () => _unmarkAsTaken(dose)
                    : () => _markAsTaken(dose),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: dose.isTaken 
                        ? Colors.green.shade600 
                        : Colors.white,
                    border: Border.all(
                      color: dose.isTaken 
                          ? Colors.green.shade600 
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: dose.isTaken
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              
              // Time
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                dose.time,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: dose.isTaken ? Colors.grey.shade600 : Colors.black87,
                  decoration: dose.isTaken ? TextDecoration.lineThrough : null,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Instruction
              if (dose.instruction != null && dose.instruction!.isNotEmpty) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 12, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dose.instruction!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                const Spacer(),
              
              const SizedBox(width: 8),
              
              // Status indicator
              if (isUpcoming && !dose.isTaken)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 10, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Soon',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              else if (dose.isTaken)
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getHeaderSubtitle() {
    if (_isLoading) return 'Loading...';
    if (_reminders.isEmpty) return 'No reminders today';
    
    final taken = _reminders.where((r) => r.isTaken).length;
    final total = _reminders.length;
    
    if (taken == total) return 'All done! ✓';
    return '$taken of $total taken';
  }

  Widget _buildReminderCard(MedicineReminder reminder) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final reminderMinutes = _parseTime(reminder.time);
    final isPast = currentMinutes > reminderMinutes;
    final isUpcoming = !isPast && (reminderMinutes - currentMinutes) < 60;

    return Container(
      decoration: BoxDecoration(
        color: reminder.isTaken 
            ? Colors.green.shade50 
            : isUpcoming 
                ? Colors.orange.shade50 
                : Colors.white,
        border: Border.all(
          color: reminder.isTaken 
              ? Colors.green.shade200 
              : isUpcoming 
                  ? Colors.orange.shade200 
                  : Colors.grey.shade200,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: reminder.isTaken 
              ? () => _unmarkAsTaken(reminder)
              : () => _markAsTaken(reminder),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: reminder.isTaken 
                      ? () => _unmarkAsTaken(reminder)
                      : () => _markAsTaken(reminder),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: reminder.isTaken 
                          ? Colors.green.shade600 
                          : Colors.white,
                      border: Border.all(
                        color: reminder.isTaken 
                            ? Colors.green.shade600 
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: reminder.isTaken
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Medicine Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reminder.medicineName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: reminder.isTaken 
                                    ? TextDecoration.lineThrough 
                                    : null,
                                color: reminder.isTaken 
                                    ? Colors.grey.shade600 
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (isUpcoming && !reminder.isTaken)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule, size: 12, color: Colors.orange.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Soon',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            reminder.time,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.medication_liquid, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            reminder.dosage,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      if (reminder.instruction != null && reminder.instruction!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, size: 12, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text(
                                reminder.instruction!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (reminder.notes != null && reminder.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          reminder.notes!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Status Icon
                if (reminder.isTaken)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MedicineReminder {
  final String medicineId;
  final String? doseId;
  final String medicineName;
  final String dosage;
  final String time;
  final String? instruction;
  final String? notes;
  final bool isTaken;

  MedicineReminder({
    required this.medicineId,
    this.doseId,
    required this.medicineName,
    required this.dosage,
    required this.time,
    this.instruction,
    this.notes,
    this.isTaken = false,
  });

  MedicineReminder copyWith({
    String? medicineId,
    String? doseId,
    String? medicineName,
    String? dosage,
    String? time,
    String? instruction,
    String? notes,
    bool? isTaken,
  }) {
    return MedicineReminder(
      medicineId: medicineId ?? this.medicineId,
      doseId: doseId ?? this.doseId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      instruction: instruction ?? this.instruction,
      notes: notes ?? this.notes,
      isTaken: isTaken ?? this.isTaken,
    );
  }
}
