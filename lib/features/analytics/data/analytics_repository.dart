import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/analytics_model.dart';

class AnalyticsRepository {
  final DioClient _dioClient;
  AnalyticsRepository({required DioClient dioClient})
      : _dioClient = dioClient;

  Future<AnalyticsDashboard> getDashboard() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.dashboard);
      if (response.data['success'] == true) {
        return AnalyticsDashboard.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      throw NetworkException(
          response.data['message'] ?? 'Failed to fetch analytics');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to fetch analytics: $e');
    }
  }
}
