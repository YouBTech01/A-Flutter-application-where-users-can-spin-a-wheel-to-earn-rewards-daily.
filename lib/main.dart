import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'providers/user_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_navigator.dart';
import 'services/ad_service.dart';

// Global error handling for Firebase initialization
Future<void> initializeApp() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for the app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay styles to match light splash screen
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp();
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint("Failed to initialize Firebase: $e");
    // This is expected when running the GitHub version without proper Firebase setup
    debugPrint(
      "Note: For GitHub users - you need to configure your own Firebase project",
    );
  }

  // Initialize AdMob via our AdService singleton to ensure test devices are configured
  try {
    await AdService().initialize();
    debugPrint("AdMob initialized successfully with test IDs");
  } catch (e) {
    debugPrint("Failed to initialize AdMob: $e");
    // Fallback initialization if the custom service fails
    try {
      await MobileAds.instance.initialize();
      debugPrint("AdMob initialized through fallback method");
    } catch (e) {
      debugPrint("All attempts to initialize AdMob failed: $e");
    }
  }
}

void main() async {
  try {
    await initializeApp();
    runApp(const MyApp());
  } catch (e) {
    debugPrint("Error during initialization: $e");
    // Show an error screen in case of failed initialization
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Text(
              'Failed to initialize app: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UserProvider()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'Spin to Earn',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          canvasColor: Colors.white,
          appBarTheme: const AppBarTheme(
            color: Colors.white,
            foregroundColor: Colors.black,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        builder: (context, child) {
          // Ensure the entire app uses a white background
          return Container(color: Colors.white, child: child);
        },
        home: const SplashNavigator(child: AuthWrapper()),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        // Show loading indicator while initializing
        if (userProvider.isLoading) {
          return Container(
            color: Colors.white,
            child: const Scaffold(
              backgroundColor: Colors.white, // Match splash screen color
              body: Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            ),
          );
        }

        // Show login screen if not authenticated
        if (!userProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Show home screen if authenticated
        return const HomeScreen();
      },
    );
  }
}
