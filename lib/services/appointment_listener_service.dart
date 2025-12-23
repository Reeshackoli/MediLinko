import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants/api_config.dart';
import '../services/token_service.dart';
import '../services/notification_service.dart';

class AppointmentListenerService {
  static Timer? _appointmentTimer;
  static final Set<String> _notifiedAppointments = {}; // Track notified appointment IDs
  static bool _isListening = false;

  // Start listening for appointment changes
  // DISABLED: Backend now sends real-time FCM notifications immediately when:
  // - Doctor approves/rejects appointment (appointmentController.js)
  // - Patient books appointment (appointmentController.js) 
  // No need for polling - notifications are instant via Firebase Cloud Messaging
  static void startListening({
    required String userRole,
    required String userId,
  }) {
    debugPrint('⚠️ Appointment listener is DISABLED - backend sends real-time FCM notifications');
    debugPrint('📱 FCM handles: appointment approvals, rejections, and new bookings');
    // Polling disabled - all notifications are now real-time via FCM
  }

  // Stop listening
  static void stopListening() {
    // No-op: listener is disabled, nothing to stop
    debugPrint('⚠️ Appointment listener was already disabled');
  }

  // DISABLED: Original polling methods below (kept for reference)
  /*
  // Check for appointment updates
  static Future<void> _checkAppointments({
    required String userRole,
    required String userId,
  }) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return;

      final endpoint = userRole == 'doctor'
          ? '/appointments/doctor'
          : '/appointments';

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List appointments = data['appointments'] ?? [];

        if (userRole == 'doctor') {
          _handleDoctorAppointments(appointments);
        } else {
          _handlePatientAppointments(appointments);
        }

        // Schedule upcoming appointment reminders
        _scheduleUpcomingReminders(appointments);
      }
    } catch (e) {
      debugPrint('❌ Error checking appointments: $e');
    }
  }

  // Handle doctor-specific logic (new pending appointments)
  static void _handleDoctorAppointments(List appointments) {
    final now = DateTime.now();
    
    for (var apt in appointments) {
      if (apt['status'] == 'pending') {
        final createdAt = DateTime.parse(apt['createdAt'] ?? apt['date']);
        
        // Only notify for appointments created in last 5 minutes
        if (now.difference(createdAt).inMinutes <= 5) {
          final patientName = apt['userId']['fullName'] ?? 'A patient';
          final date = apt['date'] ?? 'Unknown date';
          final time = apt['time'] ?? 'Unknown time';
          
          NotificationService.showNewAppointmentNotification(
            patientName: patientName,
            date: date,
            time: time,
          );
          
          debugPrint('🔔 Notified doctor of new appointment');
        }
      }
    }
  }

  // Handle patient-specific logic (status changes)
  static void _handlePatientAppointments(List appointments) {
    for (var apt in appointments) {
      final appointmentId = apt['_id'] ?? '';
      final status = apt['status'];
      final doctorName = apt['doctorId']?['fullName'] ?? 'Doctor';
      final date = apt['date'] ?? '';
      final time = apt['time'] ?? '';

      // Create unique key for this appointment + status combination
      final notificationKey = '$appointmentId-$status';
      
      // Only notify if we haven't already notified for this appointment status
      if (_notifiedAppointments.contains(notificationKey)) {
        continue; // Skip - already notified
      }

      // Check if status is approved or rejected
      if (status == 'approved') {
        NotificationService.showAppointmentStatusNotification(
          status: 'approved',
          doctorName: doctorName,
          date: date,
          time: time,
        );
        
        _notifiedAppointments.add(notificationKey);
        debugPrint('🔔 Notified patient of approval for $appointmentId');
      } else if (status == 'rejected') {
        NotificationService.showAppointmentStatusNotification(
          status: 'rejected',
          doctorName: doctorName,
          date: date,
          time: time,
        );
        
        _notifiedAppointments.add(notificationKey);
        debugPrint('🔔 Notified patient of rejection for $appointmentId');
      }
    }
  }

  // Schedule notifications 1 hour before approved appointments
  static void _scheduleUpcomingReminders(List appointments) {
    final now = DateTime.now();
    
    for (var apt in appointments) {
      if (apt['status'] == 'approved') {
        try {
          // Parse appointment date and time
          final dateStr = apt['date'] as String;
          final timeStr = apt['time'] as String;
          
          // Format: "2024-12-23" and "14:30"
          final dateParts = dateStr.split('-');
          final timeParts = timeStr.split(':');
          
          final appointmentTime = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
          
          // Calculate 1 hour before
          final reminderTime = appointmentTime.subtract(const Duration(hours: 1));
          
          // If reminder time is in the future and within next 24 hours
          if (reminderTime.isAfter(now) && reminderTime.difference(now).inHours < 24) {
            final doctorName = apt['doctorId']?['fullName'] ?? 'your doctor';
            
            NotificationService.scheduleAppointmentReminder(
              appointmentId: apt['_id'],
              doctorName: doctorName,
              scheduledTime: reminderTime,
            );
            
            debugPrint('📅 Scheduled reminder for appointment at $appointmentTime');
          }
        } catch (e) {
          debugPrint('❌ Error scheduling reminder: $e');
        }
      }
    }
  }
  */
}
