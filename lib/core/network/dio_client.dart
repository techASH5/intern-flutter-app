import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_endpoints.dart';
import '../../config/constants.dart';

/// Custom Dio client with JWT refresh interceptor and error handling
class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  
  DioClient({
    required String baseUrl,
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.requestTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.requestTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // Add interceptors
    _dio.interceptors.add(_MockInterceptor()); // Standalone demo mode interceptor
    _dio.interceptors.add(_AuthInterceptor(_dio, _secureStorage));
    _dio.interceptors.add(_LoggingInterceptor());
  }
  
  Dio get dio => _dio;
  
  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}

/// Authentication Interceptor for JWT token management
class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  
  _AuthInterceptor(this._dio, this._secureStorage);
  
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip adding token for auth endpoints
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/register') ||
        options.path.contains('/auth/refresh') ||
        options.path.contains('/auth/forgotpassword') ||
        options.path.contains('/auth/resetpassword')) {
      return handler.next(options);
    }
    
    // Get access token from secure storage
    final accessToken = await _secureStorage.read(key: AppConstants.accessTokenKey);
    
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    
    return handler.next(options);
  }
  
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - Token expired
    if (err.response?.statusCode == 401) {
      // Avoid infinite loop for refresh endpoint
      if (err.requestOptions.path.contains('/auth/refresh')) {
        return handler.next(err);
      }
      
      // Try to refresh the token
      try {
        final newAccessToken = await _refreshToken();
        
        if (newAccessToken != null) {
          // Retry the failed request with new token
          final opts = Options(
            method: err.requestOptions.method,
            headers: {
              ...err.requestOptions.headers,
              'Authorization': 'Bearer $newAccessToken',
            },
          );
          
          final response = await _dio.request(
            err.requestOptions.path,
            options: opts,
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
          );
          
          return handler.resolve(response);
        }
      } catch (e) {
        // Refresh failed, clear tokens and let the error propagate
        await _clearTokens();
        return handler.next(err);
      }
    }
    
    return handler.next(err);
  }
  
  /// Refresh the access token using refresh token
  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: AppConstants.refreshTokenKey);
      
      if (refreshToken == null) {
        return null;
      }
      
      final response = await _dio.post(
        ApiEndpoints.refresh,
        options: Options(
          headers: {
            'Authorization': 'Bearer $refreshToken',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final newAccessToken = response.data['token'] as String?;
        
        if (newAccessToken != null) {
          await _secureStorage.write(
            key: AppConstants.accessTokenKey,
            value: newAccessToken,
          );
          return newAccessToken;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Clear all stored tokens
  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    await _secureStorage.delete(key: AppConstants.userDataKey);
  }
}

/// Logging Interceptor for debugging
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('🌐 REQUEST[${options.method}] => PATH: ${options.path}');
    print('📤 Data: ${options.data}');
    return super.onRequest(options, handler);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    print('📥 Data: ${response.data}');
    return super.onResponse(response, handler);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    print('📛 Error: ${err.message}');
    print('📛 Response: ${err.response?.data}');
    return super.onError(err, handler);
  }
}

/// Exception handler for network errors
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  
  NetworkException(this.message, {this.statusCode});
  
  @override
  String toString() => message;
  
  factory NetworkException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout. Please try again.', statusCode: 408);
        
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 
                       error.response?.data?['error'] ?? 
                       'Something went wrong';
        return NetworkException(message, statusCode: statusCode);
        
      case DioExceptionType.cancel:
        return NetworkException('Request cancelled', statusCode: 499);
        
      case DioExceptionType.connectionError:
        return NetworkException(
          'No internet connection. Please check your network.',
          statusCode: 503,
        );
        
      case DioExceptionType.badCertificate:
        return NetworkException('Certificate verification failed', statusCode: 495);
        
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NetworkException(
            'No internet connection. Please check your network.',
            statusCode: 503,
          );
        }
        return NetworkException('Unexpected error occurred', statusCode: 500);
    }
  }
}

// ---------------------------------------------------------------------------
// High-Fidelity Standalone Mock Interceptor (Demo Mode)
// ---------------------------------------------------------------------------
class _MockInterceptor extends Interceptor {
  static final List<Map<String, dynamic>> _vehicles = [
    {
      '_id': 'vehicle-1',
      'id': 'vehicle-1',
      'user': 'user-admin-1',
      'registrationNumber': 'N737AA',
      'manufacturer': 'Boeing',
      'model': '737-800',
      'year': 2018,
      'fuelType': 'Jet-A',
      'purchaseDate': '2018-06-15T00:00:00.000Z',
      'currentOdometer': 145000,
      'vehicleType': 'Commercial Jet',
      'healthScore': 94.0,
      'predictions': [
        {
          'component': 'Engine Oil',
          'remainingKm': 3500,
          'remainingDays': 45,
          'status': 'Healthy',
          'predictedDate': '2026-07-28T00:00:00.000Z',
        },
        {
          'component': 'Brake System',
          'remainingKm': 6200,
          'remainingDays': 80,
          'status': 'Healthy',
          'predictedDate': '2026-09-01T00:00:00.000Z',
        },
        {
          'component': 'Battery',
          'remainingKm': 8000,
          'remainingDays': 120,
          'status': 'Healthy',
          'predictedDate': '2026-10-10T00:00:00.000Z',
        }
      ],
      'createdAt': '2025-01-01T00:00:00.000Z',
      'updatedAt': '2026-06-13T00:00:00.000Z',
    },
    {
      '_id': 'vehicle-2',
      'id': 'vehicle-2',
      'user': 'user-admin-1',
      'registrationNumber': 'N320UA',
      'manufacturer': 'Airbus',
      'model': 'A320',
      'year': 2019,
      'fuelType': 'Jet-A',
      'purchaseDate': '2019-09-20T00:00:00.000Z',
      'currentOdometer': 98000,
      'vehicleType': 'Commercial Jet',
      'healthScore': 82.0,
      'predictions': [
        {
          'component': 'Brake System',
          'remainingKm': 800,
          'remainingDays': 12,
          'status': 'Due Soon',
          'predictedDate': '2026-06-25T00:00:00.000Z',
        },
        {
          'component': 'Engine Oil',
          'remainingKm': 4800,
          'remainingDays': 65,
          'status': 'Healthy',
          'predictedDate': '2026-08-17T00:00:00.000Z',
        }
      ],
      'createdAt': '2025-01-01T00:00:00.000Z',
      'updatedAt': '2026-06-13T00:00:00.000Z',
    },
    {
      '_id': 'vehicle-3',
      'id': 'vehicle-3',
      'user': 'user-admin-1',
      'registrationNumber': 'N190JB',
      'manufacturer': 'Embraer',
      'model': 'E190',
      'year': 2015,
      'fuelType': 'Jet-A',
      'purchaseDate': '2015-11-05T00:00:00.000Z',
      'currentOdometer': 230000,
      'vehicleType': 'Regional Jet',
      'healthScore': 58.0,
      'predictions': [
        {
          'component': 'Battery',
          'remainingKm': -120,
          'remainingDays': -5,
          'status': 'Overdue',
          'predictedDate': '2026-06-08T00:00:00.000Z',
        },
        {
          'component': 'Engine Oil',
          'remainingKm': 750,
          'remainingDays': 9,
          'status': 'Due Soon',
          'predictedDate': '2026-06-22T00:00:00.000Z',
        }
      ],
      'createdAt': '2025-01-01T00:00:00.000Z',
      'updatedAt': '2026-06-13T00:00:00.000Z',
    }
  ];

  static final List<Map<String, dynamic>> _services = [
    {
      '_id': 'service-1',
      'id': 'service-1',
      'vehicle': 'vehicle-1',
      'user': 'user-admin-1',
      'serviceCategory': 'Engine',
      'serviceDescription': 'Routine synthetic engine oil replacement and filter change.',
      'cost': 12500.0,
      'odometerReading': 142000,
      'serviceDate': '2026-05-15T00:00:00.000Z',
      'serviceCenter': 'AeroKeep Depot A',
      'createdAt': '2026-05-15T00:00:00.000Z',
      'updatedAt': '2026-05-15T00:00:00.000Z',
    },
    {
      '_id': 'service-2',
      'id': 'service-2',
      'vehicle': 'vehicle-2',
      'user': 'user-admin-1',
      'serviceCategory': 'Brakes',
      'serviceDescription': 'Flushed brake hydraulic lines and refilled fluid.',
      'cost': 3200.0,
      'odometerReading': 97500,
      'serviceDate': '2026-05-10T00:00:00.000Z',
      'serviceCenter': 'AeroKeep Depot B',
      'createdAt': '2026-05-10T00:00:00.000Z',
      'updatedAt': '2026-05-10T00:00:00.000Z',
    }
  ];

  static final List<Map<String, dynamic>> _appointments = [
    {
      '_id': 'appointment-1',
      'id': 'appointment-1',
      'vehicle': 'vehicle-1',
      'user': 'user-admin-1',
      'serviceCategory': 'Routine Inspection',
      'appointmentDate': '2026-06-20T10:00:00.000Z',
      'status': 'Approved',
      'createdAt': '2026-06-12T00:00:00.000Z',
      'updatedAt': '2026-06-12T00:00:00.000Z',
    },
    {
      '_id': 'appointment-2',
      'id': 'appointment-2',
      'vehicle': 'vehicle-2',
      'user': 'user-admin-1',
      'serviceCategory': 'Brake Pad Replacement',
      'appointmentDate': '2026-06-24T14:30:00.000Z',
      'status': 'Pending',
      'createdAt': '2026-06-13T00:00:00.000Z',
      'updatedAt': '2026-06-13T00:00:00.000Z',
    }
  ];

  static final List<Map<String, dynamic>> _notifications = [
    {
      '_id': 'notification-1',
      'id': 'notification-1',
      'title': 'Overdue Battery Replacement',
      'message': 'Embraer E190 (N190JB) battery has exceeded predicted lifespan by 120 km. Replace immediately.',
      'type': 'alert',
      'isRead': false,
      'createdAt': '2026-06-08T08:30:00.000Z',
    },
    {
      '_id': 'notification-2',
      'id': 'notification-2',
      'title': 'Maintenance Scheduled',
      'message': 'Routine inspection scheduled for Boeing 737-800 on June 20 at 10:00 AM.',
      'type': 'info',
      'isRead': false,
      'createdAt': '2026-06-12T14:00:00.000Z',
    }
  ];

  static final List<Map<String, dynamic>> _adminUsers = [
    {
      'id': 'user-admin-1',
      '_id': 'user-admin-1',
      'name': 'Alex Mercer',
      'email': 'alex@aerokeep.com',
      'isAdmin': true,
      'createdAt': '2026-01-01T00:00:00.000Z',
    },
    {
      'id': 'user-2',
      '_id': 'user-2',
      'name': 'Bruce Wayne',
      'email': 'bruce@waynecorp.com',
      'isAdmin': false,
      'createdAt': '2026-02-15T00:00:00.000Z',
    },
    {
      'id': 'user-3',
      '_id': 'user-3',
      'name': 'Selina Kyle',
      'email': 'selina@cat.org',
      'isAdmin': false,
      'createdAt': '2026-03-20T00:00:00.000Z',
    }
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Short simulated network delay for realistic loading spinners
    Future.delayed(const Duration(milliseconds: 200), () {
      try {
        final response = _handleRequest(options);
        if (response != null) {
          handler.resolve(response);
          return;
        }
      } catch (e) {
        handler.reject(DioException(
          requestOptions: options,
          error: e.toString(),
        ));
        return;
      }
      handler.next(options);
    });
  }

  Response? _handleRequest(RequestOptions options) {
    final path = options.path;
    final method = options.method;

    Response successResponse(dynamic data) {
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'success': true,
          'data': data,
        },
      );
    }

    // Auth Login & Register
    if (path.endsWith('/auth/login') || path.endsWith('/auth/register')) {
      final email = options.data?['email'] ?? 'alex@aerokeep.com';
      final name = options.data?['name'] ?? 'Alex Mercer';
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'success': true,
          'token': 'mock-jwt-token-value-12345',
          'data': {
            'id': 'user-admin-1',
            '_id': 'user-admin-1',
            'name': name,
            'email': email,
            'isAdmin': true,
            'createdAt': '2026-01-01T00:00:00.000Z',
          }
        },
      );
    }

    // Auth Me / Update Profile
    if (path.endsWith('/auth/me')) {
      if (method == 'PUT') {
        final data = options.data as Map<String, dynamic>;
        _adminUsers[0]['name'] = data['name'] ?? _adminUsers[0]['name'];
        _adminUsers[0]['email'] = data['email'] ?? _adminUsers[0]['email'];
      }
      return successResponse(_adminUsers[0]);
    }

    // Change password / forgot / reset
    if (path.endsWith('/auth/changepassword') || 
        path.endsWith('/auth/forgotpassword') || 
        path.contains('/auth/resetpassword/')) {
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {'success': true, 'message': 'Operation successful'},
      );
    }

    // GET /vehicles
    if (path == '/vehicles') {
      return successResponse(_vehicles);
    }

    // GET /vehicles/:id
    if (path.startsWith('/vehicles/') && !path.endsWith('/telemetry') && method == 'GET') {
      final id = path.substring(10);
      final v = _vehicles.firstWhere((e) => e['id'] == id, orElse: () => <String, dynamic>{});
      if (v.isNotEmpty) return successResponse(v);
      return Response(
        requestOptions: options,
        statusCode: 404,
        data: {'success': false, 'message': 'Vehicle not found'},
      );
    }

    // POST /vehicles
    if (path == '/vehicles' && method == 'POST') {
      final data = options.data as Map<String, dynamic>;
      final id = 'vehicle-${DateTime.now().millisecondsSinceEpoch}';
      final newVehicle = {
        '_id': id,
        'id': id,
        'user': 'user-admin-1',
        'registrationNumber': data['registrationNumber'] ?? 'NEW-VEH',
        'manufacturer': data['manufacturer'] ?? 'Generic',
        'model': data['model'] ?? 'Vehicle',
        'year': data['year'] ?? 2022,
        'fuelType': data['fuelType'] ?? 'Jet-A',
        'purchaseDate': data['purchaseDate'] ?? DateTime.now().toIso8601String(),
        'currentOdometer': data['currentOdometer'] ?? 0,
        'vehicleType': data['vehicleType'] ?? 'Commercial Jet',
        'healthScore': 100.0,
        'predictions': [
          {
            'component': 'Engine Oil',
            'remainingKm': 10000,
            'remainingDays': 180,
            'status': 'Healthy',
            'predictedDate': DateTime.now().add(const Duration(days: 180)).toIso8601String(),
          }
        ],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      _vehicles.add(newVehicle);
      return successResponse(newVehicle);
    }

    // PUT /vehicles/:id
    if (path.startsWith('/vehicles/') && method == 'PUT') {
      final id = path.substring(10);
      final data = options.data as Map<String, dynamic>;
      final idx = _vehicles.indexWhere((e) => e['id'] == id);
      if (idx != -1) {
        _vehicles[idx] = {
          ..._vehicles[idx],
          ...data,
          'updatedAt': DateTime.now().toIso8601String(),
        };
        return successResponse(_vehicles[idx]);
      }
    }

    // DELETE /vehicles/:id
    if (path.startsWith('/vehicles/') && method == 'DELETE') {
      final id = path.substring(10);
      _vehicles.removeWhere((e) => e['id'] == id);
      return Response(requestOptions: options, statusCode: 200, data: {'success': true});
    }

    // POST /vehicles/:id/telemetry
    if (path.startsWith('/vehicles/') && path.endsWith('/telemetry')) {
      final parts = path.split('/');
      final id = parts[2];
      final val = options.data?['currentOdometer'] as int? ?? 0;
      final idx = _vehicles.indexWhere((e) => e['id'] == id);
      if (idx != -1) {
        final currentOdo = _vehicles[idx]['currentOdometer'] as int;
        final difference = val - currentOdo;
        _vehicles[idx]['currentOdometer'] = val;
        
        final List<dynamic> oldPredictions = _vehicles[idx]['predictions'] ?? [];
        final newPredictions = oldPredictions.map((p) {
          final remKm = p['remainingKm'] as int? ?? 0;
          final newRemKm = remKm - difference;
          var status = 'Healthy';
          if (newRemKm <= 0) {
            status = 'Overdue';
          } else if (newRemKm <= 1000) {
            status = 'Due Soon';
          }
          return {
            ...p,
            'remainingKm': newRemKm,
            'status': status,
          };
        }).toList();

        _vehicles[idx]['predictions'] = newPredictions;
        
        final overdueCount = newPredictions.where((p) => p['status'] == 'Overdue').length;
        final dueSoonCount = newPredictions.where((p) => p['status'] == 'Due Soon').length;
        var newScore = 100.0 - (overdueCount * 25.0) - (dueSoonCount * 10.0);
        newScore = newScore.clamp(10.0, 100.0);
        _vehicles[idx]['healthScore'] = newScore;
        
        return successResponse(_vehicles[idx]);
      }
    }

    // GET /services
    if (path == '/services') {
      return successResponse(_services);
    }

    // GET /services/vehicle/:vehicleId
    if (path.startsWith('/services/vehicle/')) {
      final vehicleId = path.substring(18);
      final filtered = _services.where((e) => e['vehicle'] == vehicleId).toList();
      return successResponse(filtered);
    }

    // POST /services
    if (path == '/services' && method == 'POST') {
      final data = options.data as Map<String, dynamic>;
      final id = 'service-${DateTime.now().millisecondsSinceEpoch}';
      final newService = {
        '_id': id,
        'id': id,
        'user': 'user-admin-1',
        'vehicle': data['vehicle'] ?? 'vehicle-1',
        'serviceDate': data['serviceDate'] ?? DateTime.now().toIso8601String(),
        'odometerReading': data['odometerReading'] ?? 0,
        'serviceCategory': data['serviceCategory'] ?? 'General',
        'serviceDescription': data['serviceDescription'] ?? '',
        'cost': (data['cost'] as num?)?.toDouble() ?? 0.0,
        'serviceCenter': data['serviceCenter'] ?? 'AeroKeep Center',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      _services.add(newService);
      return successResponse(newService);
    }

    // GET /appointments
    if (path == '/appointments') {
      return successResponse(_appointments);
    }

    // POST /appointments
    if (path == '/appointments' && method == 'POST') {
      final data = options.data as Map<String, dynamic>;
      final id = 'appointment-${DateTime.now().millisecondsSinceEpoch}';
      final newAppointment = {
        '_id': id,
        'id': id,
        'user': 'user-admin-1',
        'vehicle': data['vehicle'] ?? 'vehicle-1',
        'serviceCategory': data['serviceCategory'] ?? 'Routine Inspection',
        'appointmentDate': data['appointmentDate'] ?? DateTime.now().toIso8601String(),
        'status': 'Pending',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      _appointments.add(newAppointment);
      return successResponse(newAppointment);
    }

    // Cancel appointment
    if (path.startsWith('/appointments/') && path.endsWith('/cancel')) {
      final parts = path.split('/');
      final id = parts[2];
      final idx = _appointments.indexWhere((e) => e['id'] == id);
      if (idx != -1) {
        _appointments[idx]['status'] = 'Cancelled';
        return successResponse(_appointments[idx]);
      }
    }

    // Reschedule appointment
    if (path.startsWith('/appointments/') && path.endsWith('/reschedule')) {
      final parts = path.split('/');
      final id = parts[2];
      final idx = _appointments.indexWhere((e) => e['id'] == id);
      final newDate = options.data?['appointmentDate'] as String?;
      if (idx != -1 && newDate != null) {
        _appointments[idx]['appointmentDate'] = newDate;
        return successResponse(_appointments[idx]);
      }
    }

    // Update appointment status
    if (path.startsWith('/appointments/') && path.endsWith('/status')) {
      final parts = path.split('/');
      final id = parts[2];
      final status = options.data?['status'] as String?;
      final idx = _appointments.indexWhere((e) => e['id'] == id);
      if (idx != -1 && status != null) {
        _appointments[idx]['status'] = status;
        if (status == 'Completed') {
          final appt = _appointments[idx];
          final idLog = 'service-auto-${DateTime.now().millisecondsSinceEpoch}';
          _services.add({
            '_id': idLog,
            'id': idLog,
            'vehicle': appt['vehicle'],
            'user': 'user-admin-1',
            'serviceCategory': appt['serviceCategory'],
            'serviceDescription': 'Completed scheduled service slot.',
            'cost': 4500.0,
            'odometerReading': 146000,
            'serviceDate': DateTime.now().toIso8601String(),
            'serviceCenter': 'AeroKeep Hub',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
        return successResponse(_appointments[idx]);
      }
    }

    // GET /notifications
    if (path == '/notifications') {
      return successResponse(_notifications);
    }

    // POST /notifications/read-all
    if (path == '/notifications/read-all') {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
      return Response(requestOptions: options, statusCode: 200, data: {'success': true});
    }

    // POST /notifications/:id/read
    if (path.startsWith('/notifications/') && path.endsWith('/read')) {
      final parts = path.split('/');
      final id = parts[2];
      final idx = _notifications.indexWhere((e) => e['id'] == id);
      if (idx != -1) {
        _notifications[idx]['isRead'] = true;
        return successResponse(_notifications[idx]);
      }
    }

    // DELETE /notifications/:id
    if (path.startsWith('/notifications/') && method == 'DELETE') {
      final parts = path.split('/');
      final id = parts[2];
      _notifications.removeWhere((e) => e['id'] == id);
      return Response(requestOptions: options, statusCode: 200, data: {'success': true});
    }

    // GET /analytics/dashboard
    if (path == '/analytics/dashboard') {
      double totalSpent = 0;
      for (var s in _services) {
        totalSpent += (s['cost'] as num).toDouble();
      }
      return successResponse({
        'monthlyCosts': [
          {'month': 'Jan', 'cost': 15000.0},
          {'month': 'Feb', 'cost': 8500.0},
          {'month': 'Mar', 'cost': 12000.0},
          {'month': 'Apr', 'cost': 9800.0},
          {'month': 'May', 'cost': 17000.0},
          {'month': 'Jun', 'cost': totalSpent > 0 ? totalSpent : 16200.0},
        ],
        'categoryCosts': [
          {'category': 'Engine', 'cost': 25000.0},
          {'category': 'Brakes', 'cost': 7700.0},
          {'category': 'Electrical', 'cost': 4500.0},
          {'category': 'Tires', 'cost': 6000.0},
        ],
        'upcomingAlerts': _notifications
            .where((n) => n['type'] == 'alert')
            .map((n) => {
                  'component': n['title'].toString().replaceAll('Overdue ', ''),
                  'days': 5,
                  'isUrgent': true,
                })
            .toList(),
        'totalSpent': totalSpent,
        'totalServices': _services.length,
      });
    }

    // GET /admin/stats
    if (path == '/admin/stats') {
      return successResponse({
        'totalUsers': _adminUsers.length,
        'totalVehicles': _vehicles.length,
        'pendingAppointments': _appointments.where((a) => a['status'] == 'Pending').length,
        'systemHealthScore': 88.5,
      });
    }

    // GET /admin/users
    if (path == '/admin/users') {
      return successResponse(_adminUsers);
    }

    // POST /admin/users/:id/role
    if (path.startsWith('/admin/users/') && path.endsWith('/role')) {
      final parts = path.split('/');
      final id = parts[3];
      final role = options.data?['role'] as String?;
      final idx = _adminUsers.indexWhere((e) => e['id'] == id);
      if (idx != -1 && role != null) {
        _adminUsers[idx]['isAdmin'] = role == 'admin';
        return successResponse(_adminUsers[idx]);
      }
    }

    // DELETE /admin/users/:id
    if (path.startsWith('/admin/users/') && method == 'DELETE') {
      final parts = path.split('/');
      final id = parts[3];
      _adminUsers.removeWhere((e) => e['id'] == id);
      return Response(requestOptions: options, statusCode: 200, data: {'success': true});
    }

    return null;
  }
}

