import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/appointment_model.dart';

class AppointmentsRepository {
  final DioClient _dioClient;
  AppointmentsRepository({required DioClient dioClient})
      : _dioClient = dioClient;

  Future<List<Appointment>> getAppointments() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.appointments);
      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        return list
            .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw NetworkException(response.data['message'] ?? 'Failed to fetch appointments');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to fetch appointments: $e');
    }
  }

  Future<Appointment> createAppointment(Map<String, dynamic> data) async {
    try {
      final response =
          await _dioClient.post(ApiEndpoints.appointments, data: data);
      if (response.data['success'] == true) {
        return Appointment.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      throw NetworkException(
          response.data['message'] ?? 'Failed to create appointment');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to create appointment: $e');
    }
  }

  Future<Appointment> reschedule(String id, DateTime newDate) async {
    try {
      final response = await _dioClient.put(
        ApiEndpoints.rescheduleAppointment(id),
        data: {'appointmentDate': newDate.toIso8601String()},
      );
      if (response.data['success'] == true) {
        return Appointment.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      throw NetworkException(
          response.data['message'] ?? 'Failed to reschedule');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to reschedule: $e');
    }
  }

  Future<Appointment> cancel(String id) async {
    try {
      final response =
          await _dioClient.put(ApiEndpoints.cancelAppointment(id));
      if (response.data['success'] == true) {
        return Appointment.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      throw NetworkException(
          response.data['message'] ?? 'Failed to cancel appointment');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to cancel appointment: $e');
    }
  }

  Future<Appointment> updateStatus(String id, String status) async {
    try {
      final response = await _dioClient.put(
        ApiEndpoints.updateAppointmentStatus(id),
        data: {'status': status},
      );
      if (response.data['success'] == true) {
        return Appointment.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
      throw NetworkException(
          response.data['message'] ?? 'Failed to update status');
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to update status: $e');
    }
  }
}
