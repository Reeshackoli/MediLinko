import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionManager {
  // Request all required permissions
  static Future<bool> requestAllPermissions(BuildContext context) async {
    // Critical permissions for emergency features
    final permissions = [
      Permission.location,
      Permission.activityRecognition,
      Permission.phone,
      Permission.sms,
      Permission.notification,
    ];

    bool allGranted = true;

    for (var permission in permissions) {
      final status = await permission.request();
      if (!status.isGranted) {
        allGranted = false;
        debugPrint('⚠️ Permission denied: $permission');
      }
    }

    return allGranted;
  }

  // Check if critical permissions are granted
  static Future<bool> hasRequiredPermissions() async {
    final location = await Permission.location.isGranted;
    final activity = await Permission.activityRecognition.isGranted;
    
    return location && activity;
  }

  // Show permission rationale dialog
  static Future<void> showPermissionRationale(BuildContext context) async {
    if (!context.mounted) return;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'MediLinko needs the following permissions for emergency fall detection:\n\n'
          '• Location - To share your location in emergencies\n'
          '• Activity Recognition - To detect falls\n'
          '• Phone - To call emergency contacts\n'
          '• SMS - To send emergency alerts\n'
          '• Notifications - To show emergency alerts',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
