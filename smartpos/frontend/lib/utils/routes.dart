import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_success_screen.dart';

class AppRoutes {
  // Route name constants
  static const String login = '/login';
  static const String register = '/register';
  static const String loginSuccess = '/login-success';
  static const String dashboard = '/dashboard';
  static const String addProduct = '/add-product';
  static const String inventory = '/inventory';
  static const String billing = '/billing';
  static const String customers = '/customers';
  static const String reports = '/reports';
  static const String settings = '/settings';

  // Generate route function for MaterialApp
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      case loginSuccess:
        return _buildRoute(const LoginSuccessScreen(), settings);
      case dashboard:
        return _buildRoute(const DashboardScreen(), settings);
      // Add more routes as they are implemented
      // case addProduct:
      //   return _buildRoute(const AddProductScreen(), settings);
      // case inventory:
      //   return _buildRoute(const InventoryScreen(), settings);
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

  // Helper method for custom page transition
  static PageRoute _buildFadeRoute(Widget widget, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => widget,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        var curve = Curves.easeInOut;
        var curveTween = CurveTween(curve: curve);
        var tween = Tween(begin: begin, end: end).chain(curveTween);
        var opacityAnimation = animation.drive(tween);
        return FadeTransition(opacity: opacityAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
