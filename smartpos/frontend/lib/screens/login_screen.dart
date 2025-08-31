import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import '../utils/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;
  String _selectedLanguage = 'en';

  @override
  void dispose() {
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
    Locale newLocale = Locale(languageCode);
    // This is a simple approach. In a production app, you might want to use
    // the Locale.fromSubtags constructor and handle scripts and countries.
    Provider.of<AuthProvider>(context, listen: false)
        .updateLanguagePreference(languageCode);
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

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
                Text('Logging in...'),
              ],
            ),
          ),
        );
        
        final success = await authProvider.login(
          _phoneController.text,
          _pinController.text,
        );

        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        if (success) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Login successful')),
          );
          // Navigate to success page after successful login
          Navigator.pushReplacementNamed(context, AppRoutes.loginSuccess);
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'An error occurred'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        // Close loading dialog if still showing
        if (Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo or app name
                  Icon(
                    Icons.storefront,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to SmartPOS',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
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
                  
                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Register link
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('Register'),
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
