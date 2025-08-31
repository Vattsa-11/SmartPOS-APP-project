import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  final ApiService _apiService = ApiService();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Check if user is logged in by checking if token exists
  Future<bool> isLoggedIn() async {
    final token = await _apiService.getToken();
    return token != null;
  }

  // Initialize provider by checking token and loading user profile if token exists
  Future<void> initializeApp() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (await isLoggedIn()) {
        await getUserProfile();
      }
    } catch (e) {
      _error = e.toString();
      await _apiService.clearToken(); // Clear invalid token
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login user
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('AuthProvider: Attempting login with username: $username');
      
      // Try to login with the API service
      await _apiService.login(username, password);
      
      print('AuthProvider: Login successful, retrieving user profile');
      
      // Now try to get the user profile using the token
      try {
        await getUserProfile();
      } catch (profileError) {
        print('AuthProvider: Error fetching profile: $profileError');
        // Even if profile fetch fails, we still consider login successful if we have a token
        if (await _apiService.getToken() != null) {
          print('AuthProvider: We have a token, so login is successful even without profile');
          _currentUser = User(
            username: username,
            phone: '', // We don't have the phone number yet
            shopName: '', // We don't have the shop name yet
            languagePreference: 'en',
          );
          return true;
        } else {
          throw profileError;
        }
      }
      
      print('AuthProvider: Login and profile retrieval successful');
      return true;
    } catch (e) {
      print('AuthProvider: Login error: $e');
      _error = 'Login failed: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register user
  Future<bool> register(User user, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('AuthProvider: Starting registration for user: ${user.username}');
      await _apiService.register(user, password);
      print('AuthProvider: Registration successful');
      return true;
    } catch (e) {
      print('AuthProvider: Registration error: $e');
      // Remove the "Exception: " prefix from the error message for cleaner display
      String errorMsg = e.toString();
      if (errorMsg.startsWith("Exception: ")) {
        errorMsg = errorMsg.substring("Exception: ".length);
      }
      _error = errorMsg;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get user profile
  Future<void> getUserProfile() async {
    try {
      final user = await _apiService.getUserProfile();
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    await _apiService.clearToken();
    _currentUser = null;
    
    _isLoading = false;
    notifyListeners();
  }

  // Update user language preference
  Future<void> updateLanguagePreference(String languageCode) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(languagePreference: languageCode);
      notifyListeners();
      // Here you would normally also update the language on the server
    }
  }

  // Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
