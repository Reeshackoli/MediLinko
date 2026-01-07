import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/token_service.dart';
import '../../providers/medicine_reminder_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/api_config.dart';
import 'add_medicine_screen_new.dart';

class MedicineTrackerScreen extends ConsumerStatefulWidget {
  const MedicineTrackerScreen({super.key});

  @override
  ConsumerState<MedicineTrackerScreen> createState() => _MedicineTrackerScreenState();
}

class _MedicineTrackerScreenState extends ConsumerState<MedicineTrackerScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  Map<String, dynamic> _medicinesData = {};
  List<dynamic> _allMedicines = [];
  bool _isLoading = true;
  
  late AnimationController _headerAnimController;
  late AnimationController _calendarAnimController;
  late AnimationController _listAnimController;
  late Animation<double> _headerAnimation;
  late Animation<double> _calendarAnimation;
  late Animation<Offset> _listSlideAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload data when app comes back to foreground
      _loadData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _headerAnimController.dispose();
    _calendarAnimController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _calendarAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _listAnimController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );
    _calendarAnimation = CurvedAnimation(
      parent: _calendarAnimController,
      curve: Curves.easeOutCubic,
    );
    _listSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _listAnimController,
      curve: Curves.easeOutCubic,
    ));

    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _calendarAnimController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _listAnimController.forward();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await TokenService().getToken();
      if (token == null) throw Exception('No auth token');

      // Load calendar data for the month view
      final calendarResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/medicine-reminders/calendar?month=${_currentMonth.month}&year=${_currentMonth.year}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Load all medicines
      final medicinesResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      // Also load today's data using the same API as dashboard for consistency
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines/by-date?date=$todayStr'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (calendarResponse.statusCode == 200 && medicinesResponse.statusCode == 200) {
        final calendarData = jsonDecode(calendarResponse.body);
        final medicinesData = jsonDecode(medicinesResponse.body);
        
        // If today's data loaded successfully, merge it with calendar data for today
        if (todayResponse.statusCode == 200) {
          final todayData = jsonDecode(todayResponse.body);
          if (todayData['success'] == true && todayData['data'] != null) {
            final todayMedicines = <Map<String, dynamic>>[];
            for (var med in todayData['data']) {
              final medicineName = med['medicineName'] ?? 'Unknown';
              final dosage = med['dosage'] ?? '';
              final medicineId = med['_id'] ?? med['id'];
              final takenHistory = med['takenHistory'] as List? ?? [];
              final doses = med['doses'] as List? ?? [];
              
              for (var dose in doses) {
                final time = dose['time'] ?? '';
                final time24 = _convertTo24Hour(time);
                final isTaken = takenHistory.any((h) {
                  if (h['date'] != todayStr) return false;
                  final historyTime24 = _convertTo24Hour(h['time'] ?? '');
                  return historyTime24 == time24;
                });
                
                todayMedicines.add({
                  'medicineId': medicineId,
                  'medicineName': medicineName,
                  'dosage': dosage,
                  'time': time,
                  'isTaken': isTaken,
                });
              }
            }
            
            // Update calendar data for today with fresh data
            if (calendarData['calendar'] == null) {
              calendarData['calendar'] = {};
            }
            calendarData['calendar'][todayStr] = {'medicines': todayMedicines};
          }
        }
        
        debugPrint('📦 Calendar data: ${calendarData['calendar']?.keys.length ?? 0} days');
        debugPrint('💊 Medicines loaded: ${medicinesData['medicines']?.length ?? 0}');
        
        setState(() {
          _medicinesData = calendarData['calendar'] ?? {};
          _allMedicines = medicinesData['medicines'] ?? [];
          _isLoading = false;
        });
        
        // Also refresh the shared provider so dashboard is in sync
        ref.read(medicineReminderProvider.notifier).loadReminders();
      } else {
        debugPrint('❌ API Error - Calendar: ${calendarResponse.statusCode}, Medicines: ${medicinesResponse.statusCode}');
        throw Exception('Failed to load data');
      }
    } catch (e) {
      debugPrint('❌ Error loading medicine data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsTaken(String medicineId, String time) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return;

      // Use the unified API endpoint
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      // Convert time to 24-hour format
      final time24 = _convertTo24Hour(time);

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines/$medicineId/mark-taken'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'date': dateStr,
          'time': time24,
        }),
      );

      if (response.statusCode == 200) {
        // Immediately update local state for instant UI feedback
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        _updateLocalMedicineState(dateStr, medicineId, time, true);
        
        // Refresh the shared provider FIRST so dashboard updates immediately
        await ref.read(medicineReminderProvider.notifier).loadReminders();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Text('Medicine marked as taken'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error marking medicine as taken: $e');
    }
  }
  
  /// Update local medicine state without full reload for instant feedback
  void _updateLocalMedicineState(String dateStr, String medicineId, String time, bool isTaken) {
    try {
      final dayData = _medicinesData[dateStr];
      if (dayData != null && dayData['medicines'] != null) {
        final medicines = dayData['medicines'] as List;
        for (var i = 0; i < medicines.length; i++) {
          final med = medicines[i];
          if (med['medicineId'] == medicineId && med['time'] == time) {
            // Create a new map with proper type casting
            medicines[i] = <String, dynamic>{
              'medicineId': med['medicineId'],
              'medicineName': med['medicineName'],
              'dosage': med['dosage'],
              'time': med['time'],
              'isTaken': isTaken,
            };
            break;
          }
        }
        setState(() {
          _medicinesData[dateStr] = {'medicines': medicines};
        });
      }
    } catch (e) {
      debugPrint('Error updating local state: $e');
    }
  }
  
  String _convertTo24Hour(String time12) {
    try {
      final trimmed = time12.trim();
      if (!trimmed.contains('AM') && !trimmed.contains('PM') &&
          !trimmed.contains('am') && !trimmed.contains('pm')) {
        final parts = trimmed.split(':');
        if (parts.length == 2) {
          return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
        }
        return trimmed;
      }
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
      return time12;
    }
  }

  Future<void> _unmarkAsTaken(String medicineId, String time) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return;

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final time24 = _convertTo24Hour(time);

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines/$medicineId/unmark-taken'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'date': dateStr,
          'time': time24,
        }),
      );

      if (response.statusCode == 200) {
        // Immediately update local state for instant UI feedback
        _updateLocalMedicineState(dateStr, medicineId, time, false);
        
        // Refresh the shared provider FIRST so dashboard updates immediately
        await ref.read(medicineReminderProvider.notifier).loadReminders();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.undo, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Text('Medicine unmarked'),
                ],
              ),
              backgroundColor: AppTheme.warningColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error unmarking medicine: $e');
    }
  }

  Future<void> _deleteMedicine(String medicineId) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines/$medicineId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Refresh provider FIRST for immediate dashboard sync
        await ref.read(medicineReminderProvider.notifier).loadReminders();
        // Then reload local data
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Text('Medicine deleted successfully'),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        throw Exception('Failed to delete medicine');
      }
    } catch (e) {
      debugPrint('Error deleting medicine: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _editMedicine(String medicineId) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return;

      // Fetch medicine details
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines/$medicineId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final medicineData = responseData['data'];
          
          // Navigate to edit screen
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddMedicineScreenNew(
                  medicineId: medicineId,
                  initialData: medicineData,
                ),
              ),
            ).then((_) => _loadData()); // Reload after edit
          }
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch medicine details');
        }
      } else {
        throw Exception('Failed to fetch medicine details');
      }
    } catch (e) {
      debugPrint('Error fetching medicine details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading medicine: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<DateTime> _getCalendarDays() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday % 7;
    
    List<DateTime> days = [];
    
    // Add days from previous month
    for (int i = firstWeekday - 1; i >= 0; i--) {
      days.add(firstDay.subtract(Duration(days: i + 1)));
    }
    
    // Add current month days
    for (int i = 0; i < lastDay.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i + 1));
    }
    
    // Add days from next month to fill the grid
    final remainingDays = (7 - (days.length % 7)) % 7;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(lastDay.add(Duration(days: i)));
    }
    
    return days;
  }

  /// Check if a date falls within any medicine's scheduled date range
  bool _hasMedicinesScheduledForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    for (var medicine in _allMedicines) {
      final startDateStr = medicine['startDate'];
      final endDateStr = medicine['endDate'];
      
      DateTime? startDate;
      DateTime? endDate;
      
      if (startDateStr != null) {
        try {
          startDate = DateTime.parse(startDateStr);
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
        } catch (e) {
          startDate = null;
        }
      }
      
      if (endDateStr != null) {
        try {
          endDate = DateTime.parse(endDateStr);
          endDate = DateTime(endDate.year, endDate.month, endDate.day);
        } catch (e) {
          endDate = null;
        }
      }
      
      // If no date range is set, medicine is always active
      if (startDate == null && endDate == null) {
        return true;
      }
      
      // Check if date falls within range
      bool afterStart = startDate == null || !dateOnly.isBefore(startDate);
      bool beforeEnd = endDate == null || !dateOnly.isAfter(endDate);
      
      if (afterStart && beforeEnd) {
        return true;
      }
    }
    
    return false;
  }

  /// Get medicines scheduled for a specific date (respecting date ranges)
  List<dynamic> _getMedicinesForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Check if we have calendar data for this date
    final calendarData = _medicinesData[dateStr];
    if (calendarData != null && calendarData['medicines'] != null) {
      final allMeds = calendarData['medicines'] as List;
      
      // Filter medicines based on their date range
      return allMeds.where((med) {
        final medicineId = med['medicineId'];
        
        // Find the full medicine data to check date range
        final fullMedicine = _allMedicines.firstWhere(
          (m) => m['_id'] == medicineId || m['id'] == medicineId,
          orElse: () => null,
        );
        
        if (fullMedicine == null) return true; // If not found, show it
        
        final startDateStr = fullMedicine['startDate'];
        final endDateStr = fullMedicine['endDate'];
        
        DateTime? startDate;
        DateTime? endDate;
        
        if (startDateStr != null) {
          try {
            startDate = DateTime.parse(startDateStr);
            startDate = DateTime(startDate.year, startDate.month, startDate.day);
          } catch (e) {
            startDate = null;
          }
        }
        
        if (endDateStr != null) {
          try {
            endDate = DateTime.parse(endDateStr);
            endDate = DateTime(endDate.year, endDate.month, endDate.day);
          } catch (e) {
            endDate = null;
          }
        }
        
        // If no date range, medicine is always active
        if (startDate == null && endDate == null) return true;
        
        bool afterStart = startDate == null || !dateOnly.isBefore(startDate);
        bool beforeEnd = endDate == null || !dateOnly.isAfter(endDate);
        
        return afterStart && beforeEnd;
      }).toList();
    }
    
    return [];
  }

  int _getMedicineCountForDate(DateTime date) {
    return _getMedicinesForDate(date).length;
  }

  int _getTakenCountForDate(DateTime date) {
    final medicines = _getMedicinesForDate(date);
    return medicines.where((m) => m['isTaken'] == true).length;
  }

  Color _getDateColor(DateTime date) {
    // First check if any medicines are scheduled for this date
    if (!_hasMedicinesScheduledForDate(date)) {
      return Colors.transparent; // No medicines scheduled - no indicator
    }
    
    final total = _getMedicineCountForDate(date);
    if (total == 0) return Colors.transparent; // No medicines - no indicator
    
    final taken = _getTakenCountForDate(date);
    if (taken == total) return AppTheme.successColor.withOpacity(0.8); // All taken - green
    if (taken > 0) return AppTheme.warningColor.withOpacity(0.8); // Some taken - yellow/orange
    
    // Only show red for dates that are today or in the past (missed medicines)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly.isBefore(today) || dateOnly.isAtSameMomentAs(today)) {
      return AppTheme.errorColor.withOpacity(0.6); // Missed - red
    }
    
    return AppTheme.primaryBlue.withOpacity(0.4); // Future - blue (pending)
  }

  @override
  Widget build(BuildContext context) {
    // Use filtered medicines for the selected date (respects date ranges)
    final medicines = _getMedicinesForDate(_selectedDate);
    
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        // Refresh dashboard provider when leaving this screen
        ref.read(medicineReminderProvider.notifier).loadReminders();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue.withOpacity(0.05),
                AppTheme.secondaryTeal.withOpacity(0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Premium Header
                _buildPremiumHeader(),
                
                // Calendar Section
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              // Month Selector
                              _buildMonthSelector(),
                              
                              // Calendar Grid
                              _buildCalendarGrid(),
                              
                              const SizedBox(height: 20),
                              
                              // Today's Medicines List
                              _buildMedicinesList(medicines),
                              
                              const SizedBox(height: 100), // Space for FAB
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildPremiumFAB(),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return FadeTransition(
      opacity: _headerAnimation,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medication, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_allMedicines.length} Active',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Medicine Tracker',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your daily medication',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return FadeTransition(
      opacity: _calendarAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 28),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                });
                _loadData();
              },
            ),
            Column(
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('EEEE').format(_selectedDate),
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 28),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                });
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final days = _getCalendarDays();
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime(today.year, today.month, today.day));
    
    return FadeTransition(
      opacity: _calendarAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Weekday headers
            Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            // Calendar days
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final dayStr = DateFormat('yyyy-MM-dd').format(day);
                final isToday = dayStr == todayStr;
                final isSelected = DateFormat('yyyy-MM-dd').format(_selectedDate) == dayStr;
                final isCurrentMonth = day.month == _currentMonth.month;
                final total = _getMedicineCountForDate(day);
                final taken = _getTakenCountForDate(day);
                
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = day);
                    _listAnimController.reset();
                    _listAnimController.forward();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: isSelected 
                          ? AppTheme.primaryGradient
                          : null,
                      color: isSelected 
                          ? null
                          : total > 0 ? _getDateColor(day) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(color: AppTheme.primaryBlue, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '${day.day}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                              color: isSelected 
                                  ? Colors.white
                                  : isCurrentMonth 
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary.withOpacity(0.4),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (total > 0)
                          const SizedBox(height: 1),
                        if (total > 0)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              constraints: const BoxConstraints(maxWidth: 45),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$taken/$total',
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicinesList(List<dynamic> medicines) {
    // Group medicines by name
    final Map<String, List<dynamic>> groupedMedicines = {};
    for (var medicine in medicines) {
      final name = medicine['medicineName'] ?? 'Unknown';
      if (!groupedMedicines.containsKey(name)) {
        groupedMedicines[name] = [];
      }
      groupedMedicines[name]!.add(medicine);
    }
    
    // Sort doses within each medicine by time
    groupedMedicines.forEach((key, value) {
      value.sort((a, b) {
        final aTime = a['time'] ?? '';
        final bTime = b['time'] ?? '';
        return aTime.compareTo(bTime);
      });
    });
    
    final medicineCount = groupedMedicines.length;
    final totalDoses = medicines.length;
    
    return SlideTransition(
      position: _listSlideAnimation,
      child: FadeTransition(
        opacity: _listAnimController,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d').format(_selectedDate),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '$medicineCount medicine${medicineCount != 1 ? 's' : ''} ($totalDoses dose${totalDoses != 1 ? 's' : ''})',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (groupedMedicines.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No medicines scheduled',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    const SizedBox(height: 20),
                    ...groupedMedicines.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final medicineName = entry.value.key;
                      final doses = entry.value.value;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: (400 + (index * 100)).toInt()),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: _buildGroupedMedicineItem(medicineName, doses),
                      );
                    }),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedMedicineItem(String medicineName, List<dynamic> doses) {
    final firstDose = doses.first;
    final dosage = firstDose['dosage'] ?? '';
    final medicineId = firstDose['medicineId'];
    final takenCount = doses.where((d) => d['isTaken'] == true).length;
    final totalCount = doses.length;
    final allTaken = takenCount == totalCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: allTaken ? AppTheme.successColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allTaken ? AppTheme.successColor.withOpacity(0.3) : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Medicine Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              onTap: () => _editMedicine(medicineId),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: allTaken 
                            ? LinearGradient(colors: [AppTheme.successColor, AppTheme.successColor.withOpacity(0.8)])
                            : AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (allTaken ? AppTheme.successColor : AppTheme.primaryBlue).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.medication, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicineName,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              decoration: allTaken ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.medication_liquid, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  dosage,
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: allTaken ? AppTheme.successColor.withOpacity(0.15) : AppTheme.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$takenCount/$totalCount',
                                    style: GoogleFonts.lato(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: allTaken ? AppTheme.successColor : AppTheme.primaryBlue,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: AppTheme.primaryBlue,
                      onPressed: () => _editMedicine(medicineId),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.shade200,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // Doses List
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: doses.asMap().entries.map((entry) {
                final index = entry.key;
                final dose = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < doses.length - 1 ? 8 : 0),
                  child: _buildDoseCheckbox(dose),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if the selected date is in the future (cannot be edited)
  bool _isSelectedDateInFuture() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return selected.isAfter(today);
  }

  Widget _buildDoseCheckbox(dynamic dose) {
    final time = dose['time'] ?? '';
    final isTaken = dose['isTaken'] ?? false;
    final medicineId = dose['medicineId'];
    final isFutureDate = _isSelectedDateInFuture();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isFutureDate ? null : () {
          // Toggle: if taken, unmark; if not taken, mark
          if (isTaken) {
            _unmarkAsTaken(medicineId, time);
          } else {
            _markAsTaken(medicineId, time);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isFutureDate 
                ? Colors.grey.shade100 
                : (isTaken ? AppTheme.successColor.withOpacity(0.08) : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFutureDate 
                  ? Colors.grey.shade300 
                  : (isTaken ? AppTheme.successColor.withOpacity(0.3) : Colors.grey.shade200),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFutureDate 
                      ? Colors.grey.shade300 
                      : (isTaken ? AppTheme.successColor : Colors.transparent),
                  border: Border.all(
                    color: isFutureDate 
                        ? Colors.grey.shade400 
                        : (isTaken ? AppTheme.successColor : Colors.grey.shade400),
                    width: 2,
                  ),
                ),
                child: isTaken && !isFutureDate
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : (isFutureDate ? Icon(Icons.lock, color: Colors.grey.shade500, size: 12) : null),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.access_time, 
                size: 16, 
                color: isFutureDate 
                    ? Colors.grey.shade500 
                    : (isTaken ? AppTheme.successColor : AppTheme.textSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isFutureDate 
                      ? Colors.grey.shade500 
                      : (isTaken ? AppTheme.textSecondary : AppTheme.textPrimary),
                  decoration: isTaken ? TextDecoration.lineThrough : null,
                ),
              ),
              const Spacer(),
              if (isFutureDate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Scheduled',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isTaken)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: AppTheme.successColor),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to undo',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, size: 12, color: AppTheme.primaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to mark',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineItem(dynamic medicine) {
    final name = medicine['medicineName'] ?? 'Unknown';
    final dosage = medicine['dosage'] ?? '';
    final time = medicine['time'] ?? '';
    final isTaken = medicine['isTaken'] ?? false;
    final medicineId = medicine['medicineId'];

    return Dismissible(
      key: Key(medicineId ?? name + time),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Medicine?'),
            content: Text('Are you sure you want to delete "$name"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteMedicine(medicineId);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isTaken 
              ? LinearGradient(
                  colors: [AppTheme.successColor.withOpacity(0.1), AppTheme.successColor.withOpacity(0.05)],
                )
              : LinearGradient(
                  colors: [Colors.grey.shade50, Colors.white],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTaken ? AppTheme.successColor.withOpacity(0.3) : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isTaken ? null : () => _markAsTaken(medicineId, time),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTaken ? AppTheme.successColor : Colors.transparent,
                      border: Border.all(
                        color: isTaken ? AppTheme.successColor : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isTaken
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          decoration: isTaken ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (dosage.isNotEmpty)
                        Text(
                          dosage,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isTaken 
                        ? AppTheme.successColor.withOpacity(0.2)
                        : AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: isTaken ? AppTheme.successColor : AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isTaken ? AppTheme.successColor : AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: AppTheme.primaryBlue, size: 20),
                  tooltip: 'Edit Medicine',
                  onPressed: () => _editMedicine(medicineId),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildPremiumFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddMedicineScreenNew(),
              ),
            );
            if (result == true) {
              _loadData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Add Medicine',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
