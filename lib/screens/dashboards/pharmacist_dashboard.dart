import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pharmacist_profile_provider.dart';

class PharmacistDashboardScreen extends ConsumerStatefulWidget {
  const PharmacistDashboardScreen({super.key});

  @override
  ConsumerState<PharmacistDashboardScreen> createState() => _PharmacistDashboardScreenState();
}

class _PharmacistDashboardScreenState extends ConsumerState<PharmacistDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _profileController;
  late List<AnimationController> _actionControllers;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _profileController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _actionControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _profileController.forward();
    });

    for (int i = 0; i < _actionControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 400 + (i * 100)), () {
        if (mounted) _actionControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _profileController.dispose();
    for (var controller in _actionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final pharmacistProfileAsync = ref.watch(pharmacistProfileProvider);

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
                    gradient: AppTheme.coolGradient,
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
                                    Icons.local_pharmacy_rounded,
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
                                        'Welcome to',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      pharmacistProfileAsync.when(
                                        data: (profile) {
                                          String? storeName;
                                          if (profile is Map<String, dynamic>) {
                                            storeName = profile['storeName'] as String?;
                                          }
                                          return Text(
                                            storeName ?? 'Your Pharmacy',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        },
                                        loading: () => const Text(
                                          'Your Pharmacy',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        error: (_, __) => const Text(
                                          'Your Pharmacy',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildBadge(
                                Icons.person_rounded,
                                user?.fullName ?? 'Pharmacist',
                              ),
                            ],
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
                onPressed: () {},
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
                // Profile Info Card
                FadeTransition(
                  opacity: _profileController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_profileController),
                    child: _buildProfileCard(pharmacistProfileAsync),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Section Title
                FadeTransition(
                  opacity: _profileController,
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
                    Icons.medication_rounded,
                    'Medicine Stock',
                    'Manage your inventory',
                    AppTheme.primaryBlue,
                    const Color(0xFFDBEAFE),
                    () => context.push('/pharmacist/medicines'),
                  ),
                  _buildAnimatedActionCard(
                    1,
                    Icons.location_on_rounded,
                    'Pharmacy Location',
                    'View on map',
                    AppTheme.secondaryTeal,
                    const Color(0xFFCCFBF1),
                    () => context.push('/pharmacies-map'),
                  ),
                  _buildAnimatedActionCard(
                    2,
                    Icons.person_rounded,
                    'My Profile',
                    'Update store information',
                    AppTheme.accentPurple,
                    const Color(0xFFE9D5FF),
                    () => context.push('/pharmacist-dashboard/profile'),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(AsyncValue<dynamic> profileAsync) {
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
            color: AppTheme.secondaryTeal.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/pharmacist-dashboard/profile'),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: profileAsync.when(
              data: (profile) {
                String? address;
                String? phone;
                String? services;
                
                if (profile is Map<String, dynamic>) {
                  address = profile['address'] as String?;
                  phone = profile['phone'] as String?;
                  services = profile['services'] as String?;
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppTheme.coolGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.store_rounded,
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
                                'Store Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Tap to edit details',
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
                    _buildInfoRow(
                      Icons.location_on_rounded,
                      'Address',
                      address ?? 'Not set',
                      AppTheme.primaryBlue,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.phone_rounded,
                      'Contact',
                      phone ?? 'Not set',
                      AppTheme.secondaryTeal,
                    ),
                    if (services != null && services.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.medical_services_rounded,
                        'Services',
                        services,
                        AppTheme.accentPurple,
                      ),
                    ],
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
                child: Text('Unable to load profile'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
}
