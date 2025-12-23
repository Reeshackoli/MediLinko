import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../core/constants/api_config.dart';
import 'token_service.dart';

class NotificationFetchService {
  /// Fetch user's notifications from backend
  static Future<List<NotificationItem>> fetchNotifications({
    bool? read,
    int limit = 50,
  }) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) {
        debugPrint('❌ No auth token found');
        return [];
      }

      String url = '${ApiConfig.baseUrl}/notifications';
      if (read != null) {
        url += '?read=$read';
      }
      url += '${read != null ? '&' : '?'}limit=$limit';

      debugPrint('📥 Fetching notifications from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List notificationsJson = data['notifications'] ?? [];
        
        final notifications = notificationsJson
            .map((n) => NotificationItem.fromJson(n))
            .toList();
        
        debugPrint('✅ Fetched ${notifications.length} notifications');
        return notifications;
      } else {
        debugPrint('❌ Failed to fetch notifications: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Notification marked as read: $notificationId');
        return true;
      } else {
        debugPrint('❌ Failed to mark notification as read: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllAsRead() async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ All notifications marked as read');
        return true;
      } else {
        debugPrint('❌ Failed to mark all notifications as read: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Notification deleted: $notificationId');
        return true;
      } else {
        debugPrint('❌ Failed to delete notification: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// Delete all notifications
  static Future<bool> deleteAllNotifications() async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ All notifications deleted');
        return true;
      } else {
        debugPrint('❌ Failed to delete all notifications: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error deleting all notifications: $e');
      return false;
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
    this.data,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      data: json['data'],
    );
  }

  IconData get icon {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'reminder':
        return Icons.alarm;
      case 'order':
        return Icons.shopping_bag;
      case 'alert':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case 'appointment':
        return const Color(0xFF4C9AFF);
      case 'reminder':
        return const Color(0xFF5FD4C4);
      case 'order':
        return const Color(0xFFFF9F43);
      case 'alert':
        return const Color(0xFFEE5A6F);
      default:
        return Colors.grey;
    }
  }
}
