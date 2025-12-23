import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/material.dart';

class FallDetectionService {
  static FallDetectionService? _instance;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isMonitoring = false;
  DateTime? _lastFallDetected;
  final Duration _debounceDuration = const Duration(seconds: 30);
  DateTime? _highAccelerationStart;
  
  // Fall detection threshold (in G-force) - increased to reduce false positives
  static const double fallThreshold = 4.5;
  // Minimum duration of high acceleration to confirm fall (milliseconds)
  static const int minimumDurationMs = 150;
  
  // Global key to access navigator from anywhere
  static GlobalKey<NavigatorState>? navigatorKey;
  
  // Callback when fall is detected
  VoidCallback? onFallDetected;

  FallDetectionService._();

  static FallDetectionService get instance {
    _instance ??= FallDetectionService._();
    return _instance!;
  }

  void startMonitoring({VoidCallback? onFallDetected}) {
    if (_isMonitoring) return;
    
    this.onFallDetected = onFallDetected;
    _isMonitoring = true;

    debugPrint('🔔 Fall detection monitoring started');

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      _checkForFall(event);
    });
  }

  void _checkForFall(AccelerometerEvent event) {
    // Calculate total acceleration (magnitude)
    final double totalAcceleration = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Check if acceleration exceeds threshold
    if (totalAcceleration > fallThreshold * 9.81) { // Convert G to m/s²
      // Start tracking high acceleration
      if (_highAccelerationStart == null) {
        _highAccelerationStart = DateTime.now();
        return; // Don't trigger immediately
      }
      
      // Check if high acceleration sustained for minimum duration
      final duration = DateTime.now().difference(_highAccelerationStart!);
      if (duration.inMilliseconds < minimumDurationMs) {
        return; // Not sustained long enough
      }
      
      // Debounce - don't trigger if recently detected
      if (_lastFallDetected != null &&
          DateTime.now().difference(_lastFallDetected!) < _debounceDuration) {
        _highAccelerationStart = null;
        return;
      }

      _lastFallDetected = DateTime.now();
      _highAccelerationStart = null;
      debugPrint('⚠️ FALL DETECTED! Sustained acceleration: ${totalAcceleration.toStringAsFixed(2)} m/s² for ${duration.inMilliseconds}ms');
      
      // Trigger callback
      onFallDetected?.call();
    } else {
      // Reset if acceleration drops below threshold
      _highAccelerationStart = null;
    }
  }

  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _isMonitoring = false;
    debugPrint('🔕 Fall detection monitoring stopped');
  }

  bool get isMonitoring => _isMonitoring;

  void dispose() {
    stopMonitoring();
  }
}
