/// Admin user model
class AdminUser {
  final String id;
  final String name;
  final String email;
  final bool isAdmin;
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      isAdmin: json['isAdmin'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Admin stats model
class AdminStats {
  final int totalUsers;
  final int totalVehicles;
  final int totalAppointments;
  final int pendingAppointments;
  final int totalServices;
  final double totalRevenue;

  AdminStats({
    required this.totalUsers,
    required this.totalVehicles,
    required this.totalAppointments,
    required this.pendingAppointments,
    required this.totalServices,
    required this.totalRevenue,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] as int? ?? 0,
      totalVehicles: json['totalVehicles'] as int? ?? 0,
      totalAppointments: json['totalAppointments'] as int? ?? 0,
      pendingAppointments: json['pendingAppointments'] as int? ?? 0,
      totalServices: json['totalServices'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
