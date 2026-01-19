import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:go_router/go_router.dart';
import '../../services/session_manager.dart';
import '../../services/notification_service.dart';
import '../../services/lockscreen_service.dart';
import '../../services/emergency_web_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  Map<String, dynamic>? _emergencyData;
  String? _qrWebUrl;
  bool _isLoading = true;
  bool _useWebUrl = true; // Toggle between web URL and static text

  @override
  void initState() {
    super.initState();
    _loadEmergencyData();
    _enableEmergencyMode();
  }

  Future<void> _enableEmergencyMode() async {
    try {
      // Enable wakelock to keep screen on
      await WakelockPlus.enable();
      debugPrint('🔒 Screen wakelock enabled - screen will stay ON');
      
      // Enable lock screen flags to show over lock screen
      final lockScreenEnabled = await LockScreenService.enableLockScreenFlags();
      if (lockScreenEnabled) {
        debugPrint('🔓 Lock screen flags ENABLED - app will show over lock screen');
      } else {
        debugPrint('⚠️ Failed to enable lock screen flags');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to enable emergency mode: $e');
    }
  }

  @override
  void dispose() {
    _disableEmergencyMode();
    super.dispose();
  }

  Future<void> _disableEmergencyMode() async {
    try {
      // Disable wakelock
      await WakelockPlus.disable();
      debugPrint('🔓 Screen wakelock disabled');
      
      // Disable lock screen flags (return to normal secure behavior)
      final lockScreenDisabled = await LockScreenService.disableLockScreenFlags();
      if (lockScreenDisabled) {
        debugPrint('🔒 Lock screen flags DISABLED - app will hide when locked (secure)');
      } else {
        debugPrint('⚠️ Failed to disable lock screen flags');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to disable emergency mode: $e');
    }
  }

  Future<void> _loadEmergencyData() async {
    // Load from local storage (accessible offline)
    final data = await SessionManager.getEmergencyData();
    
    // Try to fetch web QR URL from emergencyMed service
    String? webUrl;
    try {
      webUrl = await EmergencyWebService.getQRCodeUrl();
      if (webUrl != null) {
        debugPrint('✅ Using emergencyMed web URL: $webUrl');
      } else {
        debugPrint('⚠️ EmergencyMed URL not available, using offline mode');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch web URL: $e');
    }
    
    setState(() {
      _emergencyData = data;
      _qrWebUrl = webUrl;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final name = _emergencyData?['name'] ?? 'Unknown Patient';
    final bloodGroup = _emergencyData?['bloodGroup'] ?? 'Unknown';
    final allergies = _emergencyData?['allergies'] ?? 'None listed';
    final emergencyContactName = _emergencyData?['emergencyContactName'] ?? 'Not set';
    final emergencyContactPhone = _emergencyData?['emergencyContactPhone'] ?? 'Not set';
    final emergencyContactName2 = _emergencyData?['emergencyContactName2'] ?? '';
    final emergencyContactPhone2 = _emergencyData?['emergencyContactPhone2'] ?? '';

    // QR Code data - use web URL if available, fallback to static text
    String qrData;
    if (_qrWebUrl != null && _useWebUrl) {
      // Web URL mode - points to emergencyMed web interface
      qrData = _qrWebUrl!;
      debugPrint('🌐 QR Code Mode: Web URL');
    } else {
      // Offline mode - static text
      qrData = '''
🚨 MEDICAL EMERGENCY
Name: $name
Blood Type: $bloodGroup
Allergies: $allergies
Emergency Contact 1: $emergencyContactName ($emergencyContactPhone)${emergencyContactName2.isNotEmpty ? '\nEmergency Contact 2: $emergencyContactName2 ($emergencyContactPhone2)' : ''}
''';
      debugPrint('📄 QR Code Mode: Offline Text');
    }

    return Scaffold(
      backgroundColor: Colors.red,
      body: SafeArea(
        child: Column(
          children: [
            // Screen Lock Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.red.shade900,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.screen_lock_portrait, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Screen Locked ON for Emergency',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
            children: [
              // Medical ID Card Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Emergency Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emergency,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    const Text(
                      'MEDICAL EMERGENCY',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fall Detected',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Patient Information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('NAME', name, isLarge: true),
                    const Divider(height: 32),
                    _buildInfoRow('BLOOD TYPE', bloodGroup, isHighlight: true),
                    const Divider(height: 32),
                    _buildInfoRow('ALLERGIES', allergies, isHighlight: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // QR Code with improved visibility
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'SCAN FOR FULL MEDICAL INFO',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_qrWebUrl != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'WEB',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_qrWebUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Opens in browser - No app needed',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300, width: 2),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '⚠️ High Contrast for Sunlight',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // PRIMARY ACTION: Call Emergency Contact 1
              if (emergencyContactPhone != 'Not set')
                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: ElevatedButton(
                    onPressed: () => _callEmergencyContact(emergencyContactPhone),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone, size: 32),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CALL EMERGENCY CONTACT 1',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                emergencyContactName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // SECONDARY ACTION: Call Emergency Contact 2 (if available)
              if (emergencyContactPhone2.isNotEmpty && emergencyContactPhone2 != 'Not set')
                const SizedBox(height: 12),
              if (emergencyContactPhone2.isNotEmpty && emergencyContactPhone2 != 'Not set')
                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: ElevatedButton(
                    onPressed: () => _callEmergencyContact(emergencyContactPhone2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_outlined, size: 32),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CALL EMERGENCY CONTACT 2',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                emergencyContactName2,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _cancelEmergency,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'I\'m OK - Cancel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false, bool isLarge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isHighlight ? Colors.red : Colors.black54,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 22 : 18,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }

  void _callEmergencyContact(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to make call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelEmergency() async {
    // Disable emergency mode (wakelock and lock screen flags)
    await _disableEmergencyMode();
    
    // Cancel notification
    NotificationService.cancelEmergencyNotification();
    
    // Navigate back to dashboard using GoRouter
    if (mounted) {
      context.go('/user-dashboard');
      
      // Show success message after navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency cancelled - You are safe'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }
}
