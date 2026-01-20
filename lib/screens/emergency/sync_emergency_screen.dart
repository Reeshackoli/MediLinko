import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/emergency_web_service.dart';
import '../../services/session_manager.dart';
import '../../services/profile_service.dart';
import '../../services/token_service.dart';

class SyncEmergencyScreen extends StatefulWidget {
  const SyncEmergencyScreen({super.key});

  @override
  State<SyncEmergencyScreen> createState() => _SyncEmergencyScreenState();
}

class _SyncEmergencyScreenState extends State<SyncEmergencyScreen> {
  bool _isSyncing = false;
  String? _statusMessage;
  bool _syncSuccess = false;
  String? _qrCodeUrl;
  final TokenService _tokenService = TokenService();

  @override
  void initState() {
    super.initState();
    _checkExistingQR();
  }

  Future<void> _checkExistingQR() async {
    final url = await EmergencyWebService.getQRCodeUrl();
    if (mounted && url != null) {
      setState(() {
        _qrCodeUrl = url;
        _syncSuccess = true;
        _statusMessage = 'Your emergency QR code is ready!';
      });
    }
  }

  Future<void> _syncEmergencyProfile() async {
    setState(() {
      _isSyncing = true;
      _statusMessage = 'Syncing your emergency profile...';
    });

    try {
      // Check if user has auth token
      final token = await _tokenService.getToken();
      if (token == null) {
        setState(() {
          _isSyncing = false;
          _statusMessage = 'Error: Not logged in. Please login again.';
          _syncSuccess = false;
        });
        return;
      }

      // Get user session for userId
      final userData = await SessionManager.getUserSession();
      // Backend returns 'id' not 'userId' or '_id'
      final userId = userData?['id'] ?? userData?['userId'] ?? userData?['_id'] ?? '';
      
      debugPrint('🔍 User session data keys: ${userData?.keys.toList()}');
      debugPrint('🔍 User ID found: $userId');
      
      // Check if userId is valid
      if (userId.toString().isEmpty) {
        setState(() {
          _isSyncing = false;
          _statusMessage = 'Error: User ID not found. Please logout and login again.';
          _syncSuccess = false;
        });
        return;
      }

      // Get user's health profile
      final profileResponse = await ProfileService.getProfile();
      
      if (profileResponse['success'] != true || profileResponse['data'] == null) {
        setState(() {
          _isSyncing = false;
          _statusMessage = 'Error: Could not fetch your health profile. Please complete your profile first.';
          _syncSuccess = false;
        });
        return;
      }

      final healthProfile = profileResponse['data']['profile'] as Map<String, dynamic>?;
      
      if (healthProfile == null) {
        setState(() {
          _isSyncing = false;
          _statusMessage = 'Error: Health profile not found. Please complete your profile.';
          _syncSuccess = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Uploading to emergency service...';
      });

      // Sync to emergency service
      final emergencyUserId = await EmergencyWebService.syncEmergencyData(
        userId: userId.toString(),
        emergencyData: healthProfile,
      );

      if (emergencyUserId != null && emergencyUserId.isNotEmpty) {
        // Fetch the QR URL
        final qrUrl = await EmergencyWebService.getQRCodeUrl();
        
        if (!mounted) return;
        setState(() {
          _isSyncing = false;
          _syncSuccess = true;
          _qrCodeUrl = qrUrl;
          _statusMessage = 'Emergency profile synced successfully!';
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isSyncing = false;
          _syncSuccess = false;
          _statusMessage = 'Sync completed but QR code generation failed. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('❌ Sync error: $e');
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _syncSuccess = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Emergency Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _syncSuccess 
                    ? Colors.green.withOpacity(0.1) 
                    : AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _syncSuccess ? Icons.check_circle : Icons.cloud_sync,
                size: 60,
                color: _syncSuccess ? Colors.green : AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              _syncSuccess ? 'Profile Synced!' : 'Sync Your Emergency Profile',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              _syncSuccess
                  ? 'Your emergency QR code is ready. Anyone who scans it can view your medical information.'
                  : 'Sync your health profile to generate an emergency QR code. This QR code can be scanned by medical professionals to quickly access your vital information.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Status message
            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _syncSuccess 
                      ? Colors.green.withOpacity(0.1) 
                      : (_isSyncing 
                          ? Colors.blue.withOpacity(0.1) 
                          : Colors.orange.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (_isSyncing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        _syncSuccess ? Icons.check_circle : Icons.info_outline,
                        color: _syncSuccess ? Colors.green : Colors.orange,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _syncSuccess 
                              ? Colors.green[700] 
                              : (_isSyncing ? Colors.blue[700] : Colors.orange[700]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // What will be synced
            if (!_syncSuccess) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Information that will be synced:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(Icons.person, 'Name & Age'),
                    _buildInfoItem(Icons.water_drop, 'Blood Group'),
                    _buildInfoItem(Icons.warning_amber, 'Allergies'),
                    _buildInfoItem(Icons.medical_information, 'Medical Conditions'),
                    _buildInfoItem(Icons.medication, 'Current Medications'),
                    _buildInfoItem(Icons.contact_phone, 'Emergency Contact'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Sync button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _syncEmergencyProfile,
                icon: _isSyncing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_syncSuccess ? Icons.refresh : Icons.cloud_upload),
                label: Text(
                  _isSyncing 
                      ? 'Syncing...' 
                      : (_syncSuccess ? 'Sync Again' : 'Sync Now'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            if (_syncSuccess && _qrCodeUrl != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.qr_code),
                  label: const Text(
                    'View QR Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
