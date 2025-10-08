
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/cart_provider.dart';
import 'theme/app_theme.dart';
import 'utils/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
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
    try {
      // Check if there's a current user
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session != null) {
        // Wait a bit for auth provider to initialize
        await Future.delayed(Duration(milliseconds: 500));
        
        setState(() {
          _isInitialized = true;
          _isLoggedIn = _authProvider.isAuthenticated;
          // Shop selection will be handled by DashboardWrapper
        });
      } else {
        setState(() {
          _isInitialized = true;
          _isLoggedIn = false;
        });
      }

      // Listen for auth state changes
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        
        print('**** onAuthStateChange: $event');
        
        setState(() {
          switch (event) {
            case AuthChangeEvent.signedIn:
              _isLoggedIn = session != null;
              break;
            case AuthChangeEvent.signedOut:
              _isLoggedIn = false;
              break;
            case AuthChangeEvent.tokenRefreshed:
              _isLoggedIn = session != null;
              break;
            case AuthChangeEvent.userDeleted:
              _isLoggedIn = false;
              break;
            default:
              // Handle other cases if needed
              break;
          }
        });
      });
    } catch (e) {
      debugPrint('Error initializing app: $e');
      setState(() {
        _isInitialized = true;
        _isLoggedIn = false;
      });
    }
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
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'SmartPOS',
            theme: AppTheme.getThemeData(),
            locale: const Locale('en'),
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
