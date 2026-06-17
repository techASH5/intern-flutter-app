/// Vehicle model with health predictions
class Vehicle {
  final String id;
  final String userId;
  final String registrationNumber;
  final String manufacturer;
  final String model;
  final int year;
  final String fuelType;
  final DateTime purchaseDate;
  final int currentOdometer;
  final String vehicleType;
  final double? healthScore;
  final List<ComponentPrediction>? predictions;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Vehicle({
    required this.id,
    required this.userId,
    required this.registrationNumber,
    required this.manufacturer,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.purchaseDate,
    required this.currentOdometer,
    required this.vehicleType,
    this.healthScore,
    this.predictions,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['_id'] as String? ?? json['id'] as String,
      userId: json['user'] as String,
      registrationNumber: json['registrationNumber'] as String,
      manufacturer: json['manufacturer'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      fuelType: json['fuelType'] as String,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      currentOdometer: json['currentOdometer'] as int,
      vehicleType: json['vehicleType'] as String,
      healthScore: json['healthScore'] != null 
          ? (json['healthScore'] as num).toDouble()
          : null,
      predictions: json['predictions'] != null
          ? (json['predictions'] as List)
              .map((e) => ComponentPrediction.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'registrationNumber': registrationNumber,
      'manufacturer': manufacturer,
      'model': model,
      'year': year,
      'fuelType': fuelType,
      'purchaseDate': purchaseDate.toIso8601String(),
      'currentOdometer': currentOdometer,
      'vehicleType': vehicleType,
      'healthScore': healthScore,
      'predictions': predictions?.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  String get displayName => '$manufacturer $model ($year)';
}

/// Component prediction model for maintenance forecasting
class ComponentPrediction {
  final String component;
  final int? remainingKm;
  final int? remainingDays;
  final String status; // 'Healthy', 'Due Soon', 'Overdue'
  final DateTime? predictedDate;
  
  ComponentPrediction({
    required this.component,
    this.remainingKm,
    this.remainingDays,
    required this.status,
    this.predictedDate,
  });
  
  factory ComponentPrediction.fromJson(Map<String, dynamic> json) {
    return ComponentPrediction(
      component: json['component'] as String,
      remainingKm: json['remainingKm'] as int?,
      remainingDays: json['remainingDays'] as int?,
      status: json['status'] as String,
      predictedDate: json['predictedDate'] != null
          ? DateTime.parse(json['predictedDate'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'component': component,
      'remainingKm': remainingKm,
      'remainingDays': remainingDays,
      'status': status,
      'predictedDate': predictedDate?.toIso8601String(),
    };
  }
  
  bool get isHealthy => status == 'Healthy';
  bool get isDueSoon => status == 'Due Soon';
  bool get isOverdue => status == 'Overdue';
  
  double get progressPercentage {
    if (remainingKm == null) return 0;
    // Assuming max interval is around 10000 km for most components
    const maxInterval = 10000;
    return (remainingKm! / maxInterval).clamp(0.0, 1.0);
  }
}
