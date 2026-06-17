import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/admin_model.dart';

class AdminRepository {
  final DioClient _dioClient;
  AdminRepository({required DioClient dioClient}) : _dioClient = dioClient;

  Future<AdminStats> getStats() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.adminStats);
      if (response.data['success'] == true) {
        return AdminStats.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      throw NetworkException(
          response.data['message'] ?? 'Failed to fetch stats');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to fetch stats: $e');
    }
  }

  Future<List<AdminUser>> getUsers() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.adminUsers);
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list
            .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw NetworkException(
          response.data['message'] ?? 'Failed to fetch users');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to fetch users: $e');
    }
  }

  Future<void> toggleUserRole(String id, String role) async {
    try {
      await _dioClient.put(ApiEndpoints.adminUserRole(id),
          data: {'role': role});
    } catch (e) {
      throw NetworkException('Failed to update role: $e');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _dioClient.delete(ApiEndpoints.adminDeleteUser(id));
    } catch (e) {
      throw NetworkException('Failed to delete user: $e');
    }
  }
}
