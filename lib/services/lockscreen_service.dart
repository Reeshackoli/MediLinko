import 'package:flutter/services.dart';

/// Service to control lock screen behavior dynamically
/// This allows the app to show over lock screen only during emergencies
class LockScreenService {
  static const _channel = MethodChannel('com.medilinko/lockscreen');
  static bool _isEnabled = false;

  /// Enable lock screen flags - app will show over lock screen
  /// Call this when entering emergency mode
  static Future<bool> enableLockScreenFlags() async {
    try {
      final result = await _channel.invokeMethod('enableLockScreenFlags');
      _isEnabled = result == true;
      return _isEnabled;
    } on PlatformException catch (e) {
      print('⚠️ Failed to enable lock screen flags: ${e.message}');
      return false;
    }
  }

  /// Disable lock screen flags - app will hide when locked (default behavior)
  /// Call this when exiting emergency mode
  static Future<bool> disableLockScreenFlags() async {
    try {
      final result = await _channel.invokeMethod('disableLockScreenFlags');
      _isEnabled = false;
      return result == true;
    } on PlatformException catch (e) {
      print('⚠️ Failed to disable lock screen flags: ${e.message}');
      return false;
    }
  }

  /// Check if lock screen flags are currently enabled
  static bool get isEnabled => _isEnabled;
}
