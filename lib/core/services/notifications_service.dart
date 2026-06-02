import 'dart:convert';

import '../../models/notification_model.dart';
import 'api_service.dart';

class NotificationsService {
  static Future<List<NotificationModel>> getParentNotifications(
      int parentId) async {
    final response = await ApiService.get('/parents/$parentId/notifications');
    final decoded = jsonDecode(response.body);
    final rawList = _extractList(decoded);

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  static Future<void> markAsRead(String notificationId) async {
    await ApiService.put('/notifications/$notificationId/read');
  }

  static Future<void> markAllAsRead(int parentId) async {
    await ApiService.put('/parents/$parentId/notifications/read-all');
  }

  static List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final data =
          decoded['data'] ?? decoded['content'] ?? decoded['notifications'];
      if (data is List) return data;
    }
    return [];
  }
}
