import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../config/constants.dart';
import '../domain/user_model.dart';

/// Repository for authentication operations
class AuthRepository {
  final DioClient _dioClient;
  final FlutterSecureStorage _secureStorage;
  
  AuthRepository({
    required DioClient dioClient,
    FlutterSecureStorage? secureStorage,
  })  : _dioClient = dioClient,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();
  
  /// Register a new user
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
      
      if (response.data['success'] == true) {
        final token = response.data['token'] as String;
        final user = User.fromJson(response.data['data'] as Map<String, dynamic>);
        
        // Save token and user data
        await _saveAuthData(token, user);
        
        return user;
      } else {
        throw NetworkException(response.data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Registration failed: $e');
    }
  }
  
  /// Login user
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.data['success'] == true) {
        final token = response.data['token'] as String;
        final user = User.fromJson(response.data['data'] as Map<String, dynamic>);
        
        // Save token and user data
        await _saveAuthData(token, user);
        
        return user;
      } else {
        throw NetworkException(response.data['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Login failed: $e');
    }
  }
  
  /// Logout user
  Future<void> logout() async {
    try {
      await _dioClient.post(ApiEndpoints.logout);
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      await _clearAuthData();
    }
  }
  
  /// Get current user profile
  Future<User> getCurrentUser() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.me);
      
      if (response.data['success'] == true) {
        final user = User.fromJson(response.data['data'] as Map<String, dynamic>);
        await _saveUserData(user);
        return user;
      } else {
        throw NetworkException(response.data['message'] ?? 'Failed to fetch user');
      }
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Failed to fetch user: $e');
    }
  }
  
  /// Update user profile
  Future<User> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      final response = await _dioClient.put(
        ApiEndpoints.updateProfile,
        data: {
          'name': name,
          'email': email,
        },
      );
      
      if (response.data['success'] == true) {
        final user = User.fromJson(response.data['data'] as Map<String, dynamic>);
        await _saveUserData(user);
        return user;
      } else {
        throw NetworkException(response.data['message'] ?? 'Update failed');
      }
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Update failed: $e');
    }
  }
  
  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dioClient.put(
        ApiEndpoints.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      
      if (response.data['success'] != true) {
        throw NetworkException(response.data['message'] ?? 'Password change failed');
      }
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Password change failed: $e');
    }
  }
  
  /// Request password reset
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      
      if (response.data['success'] != true) {
        throw NetworkException(response.data['message'] ?? 'Request failed');
      }
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Request failed: $e');
    }
  }
  
  /// Reset password with token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _dioClient.put(
        ApiEndpoints.resetPassword(token),
        data: {'password': newPassword},
      );
      
      if (response.data['success'] != true) {
        throw NetworkException(response.data['message'] ?? 'Password reset failed');
      }
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException('Password reset failed: $e');
    }
  }
  
  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }
  
  /// Get cached user data
  Future<User?> getCachedUser() async {
    final userData = await _secureStorage.read(key: AppConstants.userDataKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData) as Map<String, dynamic>);
    }
    return null;
  }
  
  /// Save authentication data
  Future<void> _saveAuthData(String token, User user) async {
    await _secureStorage.write(key: AppConstants.accessTokenKey, value: token);
    await _secureStorage.write(key: AppConstants.refreshTokenKey, value: token);
    await _saveUserData(user);
  }
  
  /// Save user data
  Future<void> _saveUserData(User user) async {
    await _secureStorage.write(
      key: AppConstants.userDataKey,
      value: jsonEncode(user.toJson()),
    );
  }
  
  /// Clear all authentication data
  Future<void> _clearAuthData() async {
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    await _secureStorage.delete(key: AppConstants.userDataKey);
  }
}
