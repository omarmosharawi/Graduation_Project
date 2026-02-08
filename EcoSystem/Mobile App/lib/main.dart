// =============================================================================
// MAIN.DART - REward Application Entry Point
// =============================================================================
// This is the entry point for the REward Flutter application.
// It initializes Firebase, sets up providers, and configures the router.
//
// Architecture:
// - Firebase for authentication and database
// - Provider for state management
// - GoRouter for navigation
// - Material 3 theming
// =============================================================================

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// App configuration imports
import 'app/theme.dart';
import 'app/routes.dart';

// Service imports
import 'core/services/firebase_auth_service.dart';
import 'core/services/ble_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/location_service.dart';

/// -----------------------------------------------------------------------------
/// Main Entry Point
/// -----------------------------------------------------------------------------
/// Initializes Flutter bindings, Firebase, and runs the app.
void main() async {
  // Ensure Flutter bindings are initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up background message handler for FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService().initialize();

  // Request location permission
  await LocationService().requestLocationPermission();

  // Set preferred orientations (portrait only for this app)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style (status bar appearance)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Run the app
  runApp(const RewardApp());
}

/// -----------------------------------------------------------------------------
/// RewardApp Widget
/// -----------------------------------------------------------------------------
/// Root widget that sets up providers and the MaterialApp router.
class RewardApp extends StatelessWidget {
  const RewardApp({super.key});

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // Provider Setup
    // -------------------------------------------------------------------------
    // MultiProvider wraps the app to provide services throughout the widget tree.
    return MultiProvider(
      providers: [
        // Firebase Authentication service provider
        ChangeNotifierProvider(
          create: (_) => FirebaseAuthService(),
        ),
        // Bluetooth Low Energy service provider for ESP32 communication
        ChangeNotifierProvider(
          create: (_) => BleService(),
        ),
      ],
      // -----------------------------------------------------------------------
      // MaterialApp Configuration
      // -----------------------------------------------------------------------
      child: MaterialApp.router(
        // App identification
        title: 'REward',
        debugShowCheckedModeBanner: false,

        // Theme configuration (uses our custom theme)
        theme: AppTheme.lightTheme,

        // Router configuration (uses GoRouter)
        routerConfig: AppRouter.router,
      ),
    );
  }
}
