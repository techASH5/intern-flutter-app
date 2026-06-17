import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/notification_model.dart';

class NotificationsRepository {
  final DioClient _dioClient;
  NotificationsRepository({required DioClient dioClient})
      : _dioClient = dioClient;

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.notifications);
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw NetworkException(
          response.data['message'] ?? 'Failed to fetch notifications');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to fetch notifications: $e');
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dioClient.put(ApiEndpoints.readAllNotifications);
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    try {
      await _dioClient.put(ApiEndpoints.readNotification(id));
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _dioClient.delete(ApiEndpoints.deleteNotification(id));
    } catch (_) {}
  }
}
