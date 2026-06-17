/// Appointment model for service bookings
class Appointment {
  final String id;
  final String vehicleId;
  final String userId;
  final String serviceCategory;
  final DateTime appointmentDate;
  final String status; // 'Pending', 'Approved', 'Rejected', 'Completed', 'Cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Appointment({
    required this.id,
    required this.vehicleId,
    required this.userId,
    required this.serviceCategory,
    required this.appointmentDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['_id'] as String? ?? json['id'] as String,
      vehicleId: json['vehicle'] as String,
      userId: json['user'] as String,
      serviceCategory: json['serviceCategory'] as String,
      appointmentDate: DateTime.parse(json['appointmentDate'] as String),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'vehicle': vehicleId,
      'user': userId,
      'serviceCategory': serviceCategory,
      'appointmentDate': appointmentDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';
  bool get isCompleted => status == 'Completed';
  bool get isCancelled => status == 'Cancelled';
}
