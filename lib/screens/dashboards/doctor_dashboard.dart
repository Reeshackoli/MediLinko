import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_profile_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../services/appointment_listener_service.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _statsController;
  late List<AnimationController> _actionControllers;

  @override
  void initState() {
    super.initState();
    _initializeAppointmentListener();
    _setupAnimations();
  }

  void _initializeAppointmentListener() {
    final userAsync = ref.read(authProvider);
    userAsync.whenData((user) {
      if (user != null) {
        AppointmentListenerService.startListening(
          userRole: 'doctor',
          userId: user.id,
        );
      }
    });
  }

  void _setupAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _actionControllers = List.generate(
      4,  // Updated to 4 for the prescriptions card
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _statsController.forward();
    });

    for (int i = 0; i < _actionControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 400 + (i * 100)), () {
        if (mounted) _actionControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    AppointmentListenerService.stopListening();
    _headerController.dispose();
    _statsController.dispose();
    for (var controller in _actionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final doctorProfileAsync = ref.watch(doctorProfileProvider);
    final statsAsync = ref.watch(doctorStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern Gradient App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: FadeTransition(
                opacity: _headerController,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-0.5, 0),
                              end: Offset.zero,
                            ).animate(_headerController),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.medical_services_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Good Morning,',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Dr. ${user?.fullName ?? 'Doctor'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          doctorProfileAsync.when(
                            data: (profile) => Row(
                              children: [
                                _buildBadge(
                                  Icons.star_rounded,
                                  profile?['specialization'] ?? 'Specialist',
                                ),
                                const SizedBox(width: 12),
                                _buildBadge(
                                  Icons.access_time_rounded,
                                  '${profile?['experience'] ?? '0'} yrs',
                                ),
                              ],
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => context.push('/notifications'),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/');
                },
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Cards
                FadeTransition(
                  opacity: _statsController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_statsController),
                    child: _buildStatsSection(statsAsync),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Today's Appointments Section
                FadeTransition(
                  opacity: _statsController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_statsController),
                    child: _buildTodayAppointmentsSection(),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Section Title
                FadeTransition(
                  opacity: _statsController,
                  child: const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Action Cards
                ...[
                  _buildAnimatedActionCard(
                    0,
                    Icons.calendar_month_rounded,
                    'View Appointments',
                    'Manage your schedule',
                    AppTheme.primaryBlue,
                    const Color(0xFFDBEAFE),
                    () => context.push('/doctor/appointments'),
                  ),
                  _buildAnimatedActionCard(
                    1,
                    Icons.people_rounded,
                    'Patient Management',
                    'View patient records',
                    AppTheme.secondaryTeal,
                    const Color(0xFFCCFBF1),
                    () => context.push('/doctor/patients'),
                  ),
                  _buildAnimatedActionCard(
                    2,
                    Icons.description_rounded,
                    'Prescriptions',
                    'Manage patient prescriptions',
                    const Color(0xFF10B981),
                    const Color(0xFFD1FAE5),
                    () => context.push('/doctor/prescriptions'),
                  ),
                  _buildAnimatedActionCard(
                    3,
                    Icons.person_rounded,
                    'My Profile',
                    'Update your information',
                    AppTheme.accentPurple,
                    const Color(0xFFE9D5FF),
                    () => context.push('/doctor-dashboard/profile'),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) => Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Today',
              stats['today']?.toString() ?? '0',
              'Appointments',
              Icons.event_available_rounded,
              AppTheme.primaryBlue,
              const Color(0xFFDBEAFE),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Total',
              stats['totalPatients']?.toString() ?? '0',
              'Patients',
              Icons.people_rounded,
              AppTheme.secondaryTeal,
              const Color(0xFFCCFBF1),
            ),
          ),
        ],
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Today',
              '0',
              'Appointments',
              Icons.event_available_rounded,
              AppTheme.primaryBlue,
              const Color(0xFFDBEAFE),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Total',
              '0',
              'Patients',
              Icons.people_rounded,
              AppTheme.secondaryTeal,
              const Color(0xFFCCFBF1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: iconColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedActionCard(
    int index,
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _actionControllers[index],
          curve: Curves.easeOutBack,
        ),
        child: FadeTransition(
          opacity: _actionControllers[index],
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: iconColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayAppointmentsSection() {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider);
    
    return appointmentsAsync.when(
      data: (appointments) {
        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        
        print('📅 Today\'s date string: $todayStr');
        print('📋 Total appointments: ${appointments.length}');
        
        final todayAppointments = appointments.where((a) {
          print('  Appointment date: ${a.date}, status: ${a.status}');
          return a.date == todayStr && 
                 a.status != 'rejected' && 
                 a.status != 'cancelled';
        }).toList();
        
        print('✅ Today\'s appointments found: ${todayAppointments.length}');
        
        if (todayAppointments.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4C9AFF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.today_rounded, color: Color(0xFF4C9AFF), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Today\'s Appointments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4C9AFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${todayAppointments.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: todayAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = todayAppointments[index];
                  return Container(
                    width: 280,
                    margin: EdgeInsets.only(
                      right: index < todayAppointments.length - 1 ? 12 : 0,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF4C9AFF).withOpacity(0.1),
                          const Color(0xFF5FD4C4).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4C9AFF).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: Color(0xFF4C9AFF),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appointment.patient?.fullName ?? 'Patient',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        appointment.formattedTime,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: appointment.status == 'approved'
                                ? const Color(0xFFD1FAE5)
                                : appointment.status == 'completed'
                                    ? const Color(0xFFDBEAFE)
                                    : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                appointment.status == 'approved'
                                    ? Icons.check_circle
                                    : appointment.status == 'completed'
                                        ? Icons.task_alt
                                        : Icons.pending,
                                size: 14,
                                color: appointment.status == 'approved'
                                    ? const Color(0xFF047857)
                                    : appointment.status == 'completed'
                                        ? const Color(0xFF1E40AF)
                                        : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                appointment.status[0].toUpperCase() + appointment.status.substring(1),
                                style: TextStyle(
                                  color: appointment.status == 'approved'
                                      ? const Color(0xFF047857)
                                      : appointment.status == 'completed'
                                          ? const Color(0xFF1E40AF)
                                          : const Color(0xFFD97706),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (appointment.symptoms.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            appointment.symptoms,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
