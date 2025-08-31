import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../utils/routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;
  String _selectedLanguage = 'en';

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _togglePinVisibility() {
    setState(() {
      _obscurePin = !_obscurePin;
    });
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _selectedLanguage = languageCode;
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final user = User(
        username: _ownerNameController.text,
        phone: _phoneController.text,
        shopName: _shopNameController.text,
        languagePreference: _selectedLanguage,
      );

      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Registering...'),
              ],
            ),
          ),
        );

        final success = await authProvider.register(user, _pinController.text);
        
        // Close loading dialog
        if (Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (success) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Registration successful')),
          );
          // Navigate to login success screen after successful registration
          Navigator.pushReplacementNamed(context, AppRoutes.loginSuccess);
        } else {
          final error = authProvider.error?.toLowerCase() ?? '';
          
          // Check if the error is related to phone number already registered
          if (error.contains('phone') && error.contains('already registered')) {
            // Show dialog for phone number already exists
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Registration Failed'),
                content: const Text('This phone number is already registered. Please log in instead.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            
            // Navigate to login page
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          } else if (error.contains('username') && error.contains('already registered')) {
            // Show dialog for username already exists
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Registration Failed'),
                content: const Text('This username is already registered. Please log in or choose a different username.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            // Show generic error
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text(authProvider.error ?? 'An error occurred')),
            );
          }
        }
      } catch (e) {
        // Close loading dialog if still showing
        if (Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        
        // Show error message
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Registration error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Shop name field
                  TextFormField(
                    controller: _shopNameController,
                    decoration: InputDecoration(
                      labelText: 'Shop Name',
                      hintText: 'Enter your shop name',
                      prefixIcon: const Icon(Icons.store),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Shop name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Owner name field
                  TextFormField(
                    controller: _ownerNameController,
                    decoration: InputDecoration(
                      labelText: 'Owner Name',
                      hintText: 'Enter your name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Owner name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone number field
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // PIN field
                  TextFormField(
                    controller: _pinController,
                    decoration: InputDecoration(
                      labelText: 'PIN',
                      hintText: 'Enter your PIN',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: _togglePinVisibility,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(4),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'PIN is required';
                      }
                      if (value.length != 4) {
                        return 'PIN must be 4 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Language selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('English'),
                        selected: _selectedLanguage == 'en',
                        onSelected: (selected) {
                          if (selected) _changeLanguage('en');
                        },
                      ),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: const Text('हिंदी'),
                        selected: _selectedLanguage == 'hi',
                        onSelected: (selected) {
                          if (selected) _changeLanguage('hi');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Register'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
