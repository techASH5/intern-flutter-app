/// API endpoint constants
class ApiEndpoints {
  // Auth Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/me';
  static const String changePassword = '/auth/changepassword';
  static const String forgotPassword = '/auth/forgotpassword';
  static String resetPassword(String token) => '/auth/resetpassword/$token';
  
  // Vehicle Endpoints
  static const String vehicles = '/vehicles';
  static String vehicleById(String id) => '/vehicles/$id';
  static String vehicleTelemetry(String id) => '/vehicles/$id/telemetry';
  
  // Service Endpoints
  static const String services = '/services';
  static String serviceById(String id) => '/services/$id';
  static String servicesByVehicle(String vehicleId) => '/services/vehicle/$vehicleId';
  
  // Appointment Endpoints
  static const String appointments = '/appointments';
  static String appointmentById(String id) => '/appointments/$id';
  static String rescheduleAppointment(String id) => '/appointments/$id/reschedule';
  static String cancelAppointment(String id) => '/appointments/$id/cancel';
  static String updateAppointmentStatus(String id) => '/appointments/$id/status';
  
  // Notification Endpoints
  static const String notifications = '/notifications';
  static const String readAllNotifications = '/notifications/read-all';
  static String readNotification(String id) => '/notifications/$id/read';
  static String deleteNotification(String id) => '/notifications/$id';
  
  // Analytics Endpoints
  static const String dashboard = '/analytics/dashboard';
  
  // Admin Endpoints
  static const String adminUsers = '/admin/users';
  static String adminUserRole(String id) => '/admin/users/$id/role';
  static String adminDeleteUser(String id) => '/admin/users/$id';
  static const String adminStats = '/admin/stats';
}
