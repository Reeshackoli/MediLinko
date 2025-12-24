import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../main.dart';
import '../core/theme/app_theme.dart';

class FallDetectionAlert {
  static Timer? _countdownTimer;
  static bool _isShowing = false;
  static BuildContext? _dialogContext;

  static void show(BuildContext context) async {
    if (_isShowing || !context.mounted) return;
    
    _isShowing = true;

    // Fetch user health profile
    Map<String, dynamic>? healthProfile;
    try {
      final response = await ProfileService.getProfile();
      if (response['success'] == true && response['data'] != null) {
        healthProfile = response['data']['profile'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Error fetching health profile: $e');
    }

    if (!context.mounted) {
      _isShowing = false;
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _dialogContext = dialogContext;
        return PopScope(
          canPop: false,
          child: _FallDetectionDialog(
            healthProfile: healthProfile,
            onCancel: () {
              _cancelEmergency();
            },
            onTimeout: () {
              _triggerEmergency();
            },
          ),
        );
      },
    );
  }

  static void _cancelEmergency() {
    _countdownTimer?.cancel();
    _isShowing = false;
    
    if (_dialogContext != null && _dialogContext!.mounted) {
      // Get root context before popping dialog
      final rootContext = navigatorKey.currentContext;
      
      // Pop the dialog
      Navigator.of(_dialogContext!).pop();
      
      // Show snackbar using root context
      if (rootContext != null && rootContext.mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          const SnackBar(
            content: Text('Emergency alert cancelled - You are safe'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    
    _dialogContext = null;
  }

  static void _triggerEmergency() {
    _countdownTimer?.cancel();
    _isShowing = false;
    
    if (_dialogContext != null && _dialogContext!.mounted) {
      // Get the root navigator context BEFORE popping dialog
      final rootContext = navigatorKey.currentContext;
      
      // Close dialog first
      Navigator.of(_dialogContext!).pop();
      
      _dialogContext = null;
      
      // Navigate to emergency screen using root context
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          if (rootContext != null && rootContext.mounted) {
            debugPrint('🚨 Navigating to emergency screen');
            rootContext.go('/emergency');
          } else {
            debugPrint('❌ Navigation failed: root context not available');
          }
        } catch (e) {
          debugPrint('❌ Navigation error: $e');
        }
      });
    }
    
    // Send high-priority notification
    NotificationService.showEmergencyNotification();
    debugPrint('🚨 Emergency mode activated');
  }
}

class _FallDetectionDialog extends StatefulWidget {
  final Map<String, dynamic>? healthProfile;
  final VoidCallback onCancel;
  final VoidCallback onTimeout;

  const _FallDetectionDialog({
    this.healthProfile,
    required this.onCancel,
    required this.onTimeout,
  });

  @override
  State<_FallDetectionDialog> createState() => _FallDetectionDialogState();
}

class _FallDetectionDialogState extends State<_FallDetectionDialog> {
  int _remainingSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        widget.onTimeout();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emergencyContact = widget.healthProfile?['emergencyContact'];
    final userName = widget.healthProfile?['name'] ?? 'User';
    final bloodGroup = widget.healthProfile?['bloodGroup'];
    final allergies = widget.healthProfile?['allergies'] as List?;
    final conditions = widget.healthProfile?['conditions'] as List?;
    
    return AlertDialog(
      backgroundColor: Colors.red[700],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.all(20),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 50,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'FALL DETECTED!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // User Name
            Text(
              userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Countdown Timer
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Text(
                  '$_remainingSeconds',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'seconds remaining',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),

            // Health Info Card
            if (bloodGroup != null || (allergies != null && allergies.isNotEmpty) || (conditions != null && conditions.isNotEmpty))
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.medical_information, size: 18, color: Colors.red),
                        SizedBox(width: 6),
                        Text(
                          'Medical Information',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (bloodGroup != null) ...[
                      _buildInfoRow('Blood Group', bloodGroup),
                      const SizedBox(height: 4),
                    ],
                    
                    if (allergies != null && allergies.isNotEmpty) ...[
                      _buildInfoRow('Allergies', allergies.join(', ')),
                      const SizedBox(height: 4),
                    ],
                    
                    if (conditions != null && conditions.isNotEmpty)
                      _buildInfoRow('Conditions', conditions.join(', ')),
                  ],
                ),
              ),
            
            if (bloodGroup != null || (allergies != null && allergies.isNotEmpty) || (conditions != null && conditions.isNotEmpty))
              const SizedBox(height: 16),

            // Emergency Contact Card
            if (emergencyContact != null && emergencyContact['name'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.contact_phone, size: 18, color: Colors.red),
                        SizedBox(width: 6),
                        Text(
                          'Emergency Contact',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Name', emergencyContact['name'] ?? 'N/A'),
                    const SizedBox(height: 4),
                    if (emergencyContact['relationship'] != null)
                      _buildInfoRow('Relationship', emergencyContact['relationship']),
                    const SizedBox(height: 4),
                    if (emergencyContact['phone'] != null)
                      _buildInfoRow('Phone', emergencyContact['phone']),
                    
                    if (emergencyContact['phone'] != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _callEmergencyContact(emergencyContact['phone']),
                          icon: const Icon(Icons.call, size: 20),
                          label: const Text(
                            'Call Emergency Contact',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            
            if (emergencyContact == null || emergencyContact['name'] == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No emergency contact set',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),

            // Message
            const Text(
              'Tap "I\'m OK" if you\'re safe.\nOtherwise, emergency help will be contacted automatically.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: widget.onCancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'I\'m OK',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _callEmergencyContact(String phoneNumber) async {
    try {
      final uri = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        debugPrint('Could not launch phone dialer');
      }
    } catch (e) {
      debugPrint('Error launching phone dialer: $e');
    }
  }
}
