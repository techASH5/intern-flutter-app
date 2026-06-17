/// Service log model for maintenance records
class ServiceLog {
  final String id;
  final String vehicleId;
  final String userId;
  final DateTime serviceDate;
  final int odometerReading;
  final String serviceCategory;
  final String serviceDescription;
  final double cost;
  final String? serviceCenter;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  ServiceLog({
    required this.id,
    required this.vehicleId,
    required this.userId,
    required this.serviceDate,
    required this.odometerReading,
    required this.serviceCategory,
    required this.serviceDescription,
    required this.cost,
    this.serviceCenter,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory ServiceLog.fromJson(Map<String, dynamic> json) {
    return ServiceLog(
      id: json['_id'] as String? ?? json['id'] as String,
      vehicleId: json['vehicle'] as String,
      userId: json['user'] as String,
      serviceDate: DateTime.parse(json['serviceDate'] as String),
      odometerReading: json['odometerReading'] as int,
      serviceCategory: json['serviceCategory'] as String,
      serviceDescription: json['serviceDescription'] as String,
      cost: (json['cost'] as num).toDouble(),
      serviceCenter: json['serviceCenter'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'vehicle': vehicleId,
      'user': userId,
      'serviceDate': serviceDate.toIso8601String(),
      'odometerReading': odometerReading,
      'serviceCategory': serviceCategory,
      'serviceDescription': serviceDescription,
      'cost': cost,
      'serviceCenter': serviceCenter,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
