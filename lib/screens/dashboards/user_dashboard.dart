import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_profile_provider.dart';
import '../../services/fall_detection_service.dart';
import '../../services/appointment_listener_service.dart';
import '../../widgets/fall_detection_alert.dart';
import '../../widgets/todays_reminders_card.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _cardController;
  late Animation<double> _heroAnimation;
  late Animation<double> _cardAnimation;
  late List<AnimationController> _actionControllers;

  @override
  void initState() {
    super.initState();
    _initializeFallDetection();
    _initializeAppointmentListener();
    _setupAnimations();
  }

  void _initializeAppointmentListener() {
    final userAsync = ref.read(authProvider);
    userAsync.whenData((user) {
      if (user != null) {
        AppointmentListenerService.startListening(
          userRole: 'user',
          userId: user.id,
        );
      }
    });
  }

  void _setupAnimations() {
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _heroAnimation = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    );

    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    );

    // Staggered animations for action cards
    _actionControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    // Start animations
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardController.forward();
    });

    // Stagger action card animations
    for (int i = 0; i < _actionControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 500 + (i * 100)), () {
        if (mounted) _actionControllers[i].forward();
      });
    }
  }

  void _initializeFallDetection() {
    FallDetectionService.instance.startMonitoring(
      onFallDetected: () {
        debugPrint('🚨 Fall detected callback triggered');
        if (mounted) {
          FallDetectionAlert.show(context);
        }
      },
    );
  }

  @override
  void dispose() {
    AppointmentListenerService.stopListening();
    _heroController.dispose();
    _cardController.dispose();
    for (var controller in _actionControllers) {
      controller.dispose();
    }
    FallDetectionService.instance.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final healthProfileAsync = ref.watch(healthProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern App Bar with Gradient
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: FadeTransition(
                opacity: _heroAnimation,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
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
                            ).animate(_heroAnimation),
                            child: const Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-0.5, 0),
                              end: Offset.zero,
                            ).animate(_heroAnimation),
                            child: Text(
                              user?.fullName ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.8,
                                height: 1.1,
                              ),
                            ),
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
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                tooltip: 'Server Settings',
                onPressed: () => context.push('/settings/server'),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => context.push('/notifications'),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: 'Logout',
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
                // Health Profile Card
                FadeTransition(
                  opacity: _cardAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_cardAnimation),
                    child: _buildHealthCard(healthProfileAsync),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Today's Medicine Reminders
                FadeTransition(
                  opacity: _cardAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_cardAnimation),
                    child: const TodaysRemindersCard(),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Section Title
                FadeTransition(
                  opacity: _cardAnimation,
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
                
                // Action Cards Grid
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                    _buildAnimatedActionCard(
                      0,
                      Icons.medication_liquid_rounded,
                      'Medicine\nTracker',
                      AppTheme.successColor,
                      const Color(0xFFD1FAE5),
                      () => context.push('/medicine-tracker'),
                    ),
                    _buildAnimatedActionCard(
                      1,
                      Icons.medical_services_rounded,
                      'Find\nDoctors',
                      AppTheme.primaryBlue,
                      const Color(0xFFDBEAFE),
                      () => context.push('/doctors-map'),
                    ),
                    _buildAnimatedActionCard(
                      2,
                      Icons.local_pharmacy_rounded,
                      'Nearby\nPharmacies',
                      AppTheme.secondaryTeal,
                      const Color(0xFFCCFBF1),
                      () => context.push('/pharmacies-map'),
                    ),
                    _buildAnimatedActionCard(
                      3,
                      Icons.calendar_today_rounded,
                      'My\nAppointments',
                      AppTheme.warningColor,
                      const Color(0xFFFEF3C7),
                      () => context.push('/appointments'),
                    ),
                  ],
                ),
              ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(AsyncValue<Map<String, dynamic>?> healthProfileAsync) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppTheme.surfaceLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/user-dashboard/profile'),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: healthProfileAsync.when(
              data: (profile) {
                final bloodGroup = profile?['bloodGroup'] as String? ?? 'Not Set';
                final allergiesList = profile?['allergies'] as List<dynamic>?;
                final allergies = (allergiesList != null && allergiesList.isNotEmpty)
                    ? allergiesList.join(', ')
                    : 'None';
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppTheme.heroGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Health Profile',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Tap to view details',
                                style: TextStyle(
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
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildHealthStat(
                            'Blood Group',
                            bloodGroup,
                            Icons.water_drop_rounded,
                            AppTheme.errorColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildHealthStat(
                            'Allergies',
                            allergies,
                            Icons.healing_rounded,
                            AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const Center(
                child: Text('Unable to load health profile'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedActionCard(
    int index,
    IconData icon,
    String title,
    Color iconColor,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return ScaleTransition(
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
                color: iconColor.withOpacity(0.15),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        size: 30,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
