import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/medicine_tracker_service.dart';
import '../../services/token_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/api_config.dart';
import 'add_medicine_screen_new.dart';

class MedicineTrackerScreen extends StatefulWidget {
  const MedicineTrackerScreen({super.key});

  @override
  State<MedicineTrackerScreen> createState() => _MedicineTrackerScreenState();
}

class _MedicineTrackerScreenState extends State<MedicineTrackerScreen> 
    with TickerProviderStateMixin {
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
    _setupAnimations();
    _loadData();
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

  @override
  void dispose() {
    _headerAnimController.dispose();
    _calendarAnimController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await TokenService().getToken();
      if (token == null) throw Exception('No auth token');

      // Load calendar data
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

      if (calendarResponse.statusCode == 200 && medicinesResponse.statusCode == 200) {
        final calendarData = jsonDecode(calendarResponse.body);
        final medicinesData = jsonDecode(medicinesResponse.body);
        
        debugPrint('📦 Calendar data: ${calendarData['calendar']?.keys.length ?? 0} days');
        debugPrint('💊 Medicines loaded: ${medicinesData['medicines']?.length ?? 0}');
        debugPrint('💊 Medicines data: $medicinesData');
        
        setState(() {
          _medicinesData = calendarData['calendar'] ?? {};
          _allMedicines = medicinesData['medicines'] ?? [];
          _isLoading = false;
        });
      } else {
        debugPrint('❌ API Error - Calendar: ${calendarResponse.statusCode}, Medicines: ${medicinesResponse.statusCode}');
        debugPrint('❌ Calendar response: ${calendarResponse.body}');
        debugPrint('❌ Medicines response: ${medicinesResponse.body}');
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

      final compositeId = '${medicineId}_$time';
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/medicine-reminders/$compositeId/mark-taken'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'date': dateStr}),
      );

      if (response.statusCode == 200) {
        await _loadData();
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
        final medicineData = jsonDecode(response.body);
        
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

  int _getMedicineCountForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final data = _medicinesData[dateStr];
    return data?['medicines']?.length ?? 0;
  }

  int _getTakenCountForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final data = _medicinesData[dateStr];
    final medicines = data?['medicines'] as List? ?? [];
    return medicines.where((m) => m['isTaken'] == true).length;
  }

  Color _getDateColor(DateTime date) {
    final total = _getMedicineCountForDate(date);
    if (total == 0) return Colors.grey.shade200;
    
    final taken = _getTakenCountForDate(date);
    if (taken == total) return AppTheme.successColor.withOpacity(0.8);
    if (taken > 0) return AppTheme.warningColor.withOpacity(0.8);
    return AppTheme.errorColor.withOpacity(0.6);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final selectedDayData = _medicinesData[dateStr];
    final medicines = selectedDayData?['medicines'] as List? ?? [];
    
    return Scaffold(
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
                      children: [
                        Text(
                          '${day.day}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                            color: isSelected 
                                ? Colors.white
                                : isCurrentMonth 
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary.withOpacity(0.4),
                          ),
                        ),
                        if (total > 0)
                          const SizedBox(height: 2),
                        if (total > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$taken/$total',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
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
                          '${medicines.length} medicines scheduled',
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
              if (medicines.isEmpty)
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
                    ...medicines.asMap().entries.map((entry) {
                      final index = entry.key;
                      final medicine = entry.value;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 400 + (index * 100)),
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
                        child: _buildMedicineItem(medicine),
                      );
                    }).toList(),
                  ],
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
