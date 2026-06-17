import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/service_log_model.dart';

class ServiceLogRepository {
  final DioClient _dioClient;
  ServiceLogRepository({required DioClient dioClient}) : _dioClient = dioClient;

  Future<List<ServiceLog>> getAllLogs() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.services);
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list
            .map((e) => ServiceLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw NetworkException(response.data['message'] ?? 'Failed to fetch logs');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to fetch logs: $e');
    }
  }

  Future<List<ServiceLog>> getLogsByVehicle(String vehicleId) async {
    try {
      final response =
          await _dioClient.get(ApiEndpoints.servicesByVehicle(vehicleId));
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list
            .map((e) => ServiceLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw NetworkException(response.data['message'] ?? 'Failed to fetch logs');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to fetch logs: $e');
    }
  }

  Future<ServiceLog> createLog(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(ApiEndpoints.services, data: data);
      if (response.data['success'] == true) {
        return ServiceLog.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      throw NetworkException(response.data['message'] ?? 'Failed to create log');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to create log: $e');
    }
  }

  Future<ServiceLog> updateLog(String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dioClient.put(ApiEndpoints.serviceById(id), data: data);
      if (response.data['success'] == true) {
        return ServiceLog.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      throw NetworkException(response.data['message'] ?? 'Failed to update log');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to update log: $e');
    }
  }

  Future<void> deleteLog(String id) async {
    try {
      final response =
          await _dioClient.delete(ApiEndpoints.serviceById(id));
      if (response.data['success'] != true) {
        throw NetworkException(
            response.data['message'] ?? 'Failed to delete log');
      }
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to delete log: $e');
    }
  }
}
