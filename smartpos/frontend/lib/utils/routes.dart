import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_success_screen.dart';
import '../screens/product_management_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/billing_screen.dart';
import '../screens/test_supabase_page.dart';

class AppRoutes {
  // Route name constants
  static const String login = '/login';
  static const String register = '/register';
  static const String loginSuccess = '/login-success';
  static const String shopSelection = '/shop-selection';
  static const String createShop = '/create-shop';
  static const String dashboard = '/dashboard';
  static const String addProduct = '/add-product';
  static const String inventory = '/inventory';
  static const String billing = '/billing';
  static const String customers = '/customers';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String testSupabase = '/test-supabase';

  // Generate route function for MaterialApp
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      case loginSuccess:
        return _buildRoute(const LoginSuccessScreen(), settings);
      case shopSelection:
        return _buildRoute(_buildPlaceholderScreen('Shop Selection (Coming Soon)'), settings);
      case createShop:
        return _buildRoute(_buildPlaceholderScreen('Create Shop (Coming Soon)'), settings);
      case dashboard:
        return _buildRoute(const DashboardScreen(), settings);
      case addProduct:
        return _buildRoute(ProductManagementScreen(), settings);
      case inventory:
        return _buildRoute(const InventoryScreen(), settings);
      case billing:
        return _buildRoute(const BillingScreen(), settings);
      case testSupabase:
        return _buildRoute(const TestSupabasePage(), settings);
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  // Helper method to build route with transition
  static PageRoute _buildRoute(Widget widget, RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => widget,
    );
  }

  // Helper method to build placeholder screens
  static Widget _buildPlaceholderScreen(String title) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
