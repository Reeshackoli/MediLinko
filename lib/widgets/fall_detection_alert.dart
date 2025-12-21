import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_service.dart';
import '../main.dart';

class FallDetectionAlert {
  static Timer? _countdownTimer;
  static bool _isShowing = false;
  static BuildContext? _dialogContext;

  static void show(BuildContext context) {
    if (_isShowing || !context.mounted) return;
    
    _isShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _dialogContext = dialogContext;
        return PopScope(
          canPop: false,
          child: _FallDetectionDialog(
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
  final VoidCallback onCancel;
  final VoidCallback onTimeout;

  const _FallDetectionDialog({
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
    return AlertDialog(
      backgroundColor: Colors.red,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
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
          const SizedBox(height: 20),

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
          const SizedBox(height: 16),

          // Message
          const Text(
            'Are you okay?',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Countdown Timer
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Text(
                '$_remainingSeconds',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'seconds remaining',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),

          // Message
          const Text(
            'Tap "I\'m OK" if you\'re safe.\nOtherwise, emergency help will be contacted automatically.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
}
