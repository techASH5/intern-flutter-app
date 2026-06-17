/// Analytics dashboard data model
class AnalyticsDashboard {
  final List<MonthlyCost> monthlyCosts;
  final List<CategoryCost> categoryCosts;
  final List<UpcomingAlert> upcomingAlerts;
  final double totalSpent;
  final int totalServices;

  AnalyticsDashboard({
    required this.monthlyCosts,
    required this.categoryCosts,
    required this.upcomingAlerts,
    required this.totalSpent,
    required this.totalServices,
  });

  factory AnalyticsDashboard.fromJson(Map<String, dynamic> json) {
    return AnalyticsDashboard(
      monthlyCosts: (json['monthlyCosts'] as List? ?? [])
          .map((e) => MonthlyCost.fromJson(e as Map<String, dynamic>))
          .toList(),
      categoryCosts: (json['categoryCosts'] as List? ?? [])
          .map((e) => CategoryCost.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcomingAlerts: (json['upcomingAlerts'] as List? ?? [])
          .map((e) => UpcomingAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSpent:
          (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      totalServices: json['totalServices'] as int? ?? 0,
    );
  }
}

class MonthlyCost {
  final String month; // e.g. "Jan 2025"
  final double amount;

  MonthlyCost({required this.month, required this.amount});

  factory MonthlyCost.fromJson(Map<String, dynamic> json) {
    return MonthlyCost(
      month: json['month'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CategoryCost {
  final String category;
  final double amount;
  final int count;

  CategoryCost(
      {required this.category, required this.amount, required this.count});

  factory CategoryCost.fromJson(Map<String, dynamic> json) {
    return CategoryCost(
      category: json['category'] as String? ?? 'Unknown',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      count: json['count'] as int? ?? 0,
    );
  }
}

class UpcomingAlert {
  final String vehicleName;
  final String component;
  final String status;
  final int? remainingKm;
  final int? remainingDays;

  UpcomingAlert({
    required this.vehicleName,
    required this.component,
    required this.status,
    this.remainingKm,
    this.remainingDays,
  });

  factory UpcomingAlert.fromJson(Map<String, dynamic> json) {
    return UpcomingAlert(
      vehicleName: json['vehicleName'] as String? ?? 'Vehicle',
      component: json['component'] as String? ?? 'Component',
      status: json['status'] as String? ?? 'Due Soon',
      remainingKm: json['remainingKm'] as int?,
      remainingDays: json['remainingDays'] as int?,
    );
  }
}
