import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'utils/routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthProvider _authProvider = AuthProvider();
  bool _isInitialized = false;

  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _authProvider.initializeApp();
    final loggedIn = await _authProvider.isLoggedIn();
    setState(() {
      _isInitialized = true;
      _isLoggedIn = loggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If app is not initialized, show a loading screen
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final userLanguage = authProvider.currentUser?.languagePreference ?? 'en';

          return MaterialApp(
            title: 'SmartPOS',
            theme: AppTheme.getThemeData(),
            locale: Locale(userLanguage),
            supportedLocales: const [
              Locale('en', ''),
              Locale('hi', ''),
            ],
            localizationsDelegates: const [
              // Replace with AppLocalizations.delegate when it's properly generated
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: _isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}
