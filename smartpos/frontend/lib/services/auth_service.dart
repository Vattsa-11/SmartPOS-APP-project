import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const bool isDevelopmentMode = true;
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String tokenKey = 'auth_token';

  // Token storage methods
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  // Helper method to create mock responses
  Map<String, dynamic> _createMockResponse(String username, {String id = '999'}) {
    final token = 'dev_token_${DateTime.now().millisecondsSinceEpoch}';
    return {
      'access_token': token,
      'token_type': 'bearer',
      'user': {
        'username': username,
        'id': id,
        'phone': '9999999999',
        'shop_name': 'Development Shop',
      }
    };
  }

  // Login method that handles both development and production modes
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('Attempting login for user: $username');

      // Test credentials bypass
      if (isDevelopmentMode && username == "testuser" && password == "1234") {
        print('Using test credentials in development mode');
        final mockData = _createMockResponse(username, id: '1');
        await saveToken(mockData['access_token']);
        return mockData;
      }

      // Try real login if not using test credentials
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/auth/json-login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'username': username,
            'password': password,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          await saveToken(data['access_token']);
          return data;
        }
      } catch (e) {
        print('Server login attempt failed: $e');
        
        // In development mode, return mock data for any error
        if (isDevelopmentMode) {
          print('Development mode: Using mock data after server error');
          final mockData = _createMockResponse(username);
          await saveToken(mockData['access_token']);
          return mockData;
        }

        rethrow;
      }

      throw Exception('Login failed. Please check your credentials.');
    } catch (e) {
      print('Login error: $e');
      
      if (isDevelopmentMode &&
          (e.toString().contains('XMLHttpRequest error') ||
           e.toString().contains('Failed host lookup') || 
           e.toString().contains('Connection refused'))) {
        print('Development mode: Using mock data for connection error');
        final mockData = _createMockResponse(username);
        await saveToken(mockData['access_token']);
        return mockData;
      }
      
      rethrow;
    }
  }
}
