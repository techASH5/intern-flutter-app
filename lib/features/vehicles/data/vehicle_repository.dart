import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/vehicle_model.dart';

class VehicleRepository {
  final DioClient _dioClient;

  VehicleRepository({required DioClient dioClient}) : _dioClient = dioClient;

  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.vehicles);
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list
            .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw NetworkException(response.data['message'] ?? 'Failed to fetch vehicles');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to fetch vehicles: $e');
    }
  }

  Future<Vehicle> getVehicleById(String id) async {
    try {
      final response = await _dioClient.get(ApiEndpoints.vehicleById(id));
      if (response.data['success'] == true) {
        return Vehicle.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw NetworkException(response.data['message'] ?? 'Failed to fetch vehicle');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to fetch vehicle: $e');
    }
  }

  Future<Vehicle> createVehicle(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(ApiEndpoints.vehicles, data: data);
      if (response.data['success'] == true) {
        return Vehicle.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw NetworkException(response.data['message'] ?? 'Failed to create vehicle');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to create vehicle: $e');
    }
  }

  Future<Vehicle> updateVehicle(String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dioClient.put(ApiEndpoints.vehicleById(id), data: data);
      if (response.data['success'] == true) {
        return Vehicle.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw NetworkException(response.data['message'] ?? 'Failed to update vehicle');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to update vehicle: $e');
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      final response = await _dioClient.delete(ApiEndpoints.vehicleById(id));
      if (response.data['success'] != true) {
        throw NetworkException(response.data['message'] ?? 'Failed to delete vehicle');
      }
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to delete vehicle: $e');
    }
  }

  Future<Vehicle> updateTelemetry(String id, int odometer) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.vehicleTelemetry(id),
        data: {'currentOdometer': odometer},
      );
      if (response.data['success'] == true) {
        return Vehicle.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw NetworkException(response.data['message'] ?? 'Failed to update telemetry');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to update telemetry: $e');
    }
  }
}
