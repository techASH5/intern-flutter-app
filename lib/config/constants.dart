/// App-wide constants and configuration values
class AppConstants {
  // API Configuration
  // For Android Emulator, use http://10.0.2.2:5000
  // For iOS Simulator, use http://127.0.0.1:5000
  // For physical devices, use your machine's local IP
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  // Alternative base URLs for different platforms
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:5000/api';
  static const String iosSimulatorBaseUrl = 'http://127.0.0.1:5000/api';
  
  // Secure Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  
  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String vehiclesEndpoint = '/vehicles';
  static const String servicesEndpoint = '/services';
  static const String appointmentsEndpoint = '/appointments';
  static const String notificationsEndpoint = '/notifications';
  static const String analyticsEndpoint = '/analytics';
  static const String adminEndpoint = '/admin';
  
  // App Settings
  static const int requestTimeout = 30000; // milliseconds
  static const int maxRetries = 3;
  
  // Notification Settings
  static const String notificationChannelId = 'aerokeep_channel';
  static const String notificationChannelName = 'AeroKeep Notifications';
  static const String notificationChannelDescription = 'Vehicle maintenance alerts';
  
  // Vehicle Component Types
  static const List<String> monitoredComponents = [
    'Engine Oil',
    'Brake System',
    'Battery',
    'Coolant',
    'Air Filter',
    'Tires',
  ];
  
  // Service Categories
  static const List<String> serviceCategories = [
    'Engine Oil Change',
    'Brake Maintenance',
    'Battery Service',
    'Coolant Service',
    'Air Filter Replacement',
    'Tire Maintenance',
    'General Inspection',
    'Other',
  ];
  
  // Fuel Types
  static const List<String> fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'Hybrid',
    'CNG',
    'LPG',
  ];
  
  // Vehicle Types
  static const List<String> vehicleTypes = [
    'Sedan',
    'SUV',
    'Hatchback',
    'Truck',
    'Van',
    'Motorcycle',
    'Other',
  ];
  
  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
  static const String apiDateFormat = 'yyyy-MM-dd';
}
