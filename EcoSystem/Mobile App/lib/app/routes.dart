// =============================================================================
// APP ROUTES - REward Application
// =============================================================================
// This file defines all navigation routes using go_router package.
// The routing structure follows the app's information architecture:
//
// Routes:
// - /                    → Splash screen (initial route)
// - /onboarding          → Onboarding carousel
// - /auth/login          → Login screen
// - /auth/signup         → Sign up screen
// - /auth/forgot-password → Password reset flow
// - /main/*              → Main app with bottom navigation
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Feature screens imports
import '../features/onboarding/screens/splash_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/qr_code_screen.dart';
import '../features/profile/screens/coupons_screen.dart';
import '../features/profile/screens/points_history_screen.dart';
import '../features/profile/screens/badges_screen.dart';
import '../features/profile/screens/help_center_screen.dart';
import '../features/profile/screens/about_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/map/screens/map_screen.dart';
import '../features/rankings/screens/rankings_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/offers/screens/offers_screen.dart';
import '../features/home/screens/plastic_metal_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../core/widgets/main_scaffold.dart';

/// -----------------------------------------------------------------------------
/// Route Path Constants
/// -----------------------------------------------------------------------------
/// Centralized route path definitions to avoid typos and enable easy refactoring.

class RoutePaths {
  RoutePaths._();

  // Onboarding & Auth
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String forgotPassword = '/auth/forgot-password';

  // Main App (with bottom navigation)
  static const String home = '/main/home';
  static const String profile = '/main/profile';
  static const String qrCode = '/main/qr-code';
  static const String rankings = '/main/rankings';
  static const String map = '/main/map';

  // Additional screens
  static const String notifications = '/notifications';
  static const String rewards = '/rewards';
  static const String howItWorks = '/how-it-works';
  static const String coupons = '/coupons';
  static const String pointsHistory = '/points-history';
  static const String badges = '/badges';
  static const String offers = '/offers';
  static const String adminDashboard = '/admin';
  static const String helpCenter = '/help-center';
  static const String about = '/about';
  static const String plasticMetal = '/plastic-metal';
  static const String editProfile = '/edit-profile';
}

/// -----------------------------------------------------------------------------
/// Route Names
/// -----------------------------------------------------------------------------
/// Named routes for programmatic navigation with parameters.

class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String signup = 'signup';
  static const String forgotPassword = 'forgotPassword';
  static const String home = 'home';
  static const String profile = 'profile';
  static const String qrCode = 'qrCode';
  static const String rankings = 'rankings';
  static const String map = 'map';
  static const String notifications = 'notifications';
}

/// -----------------------------------------------------------------------------
/// App Router Configuration
/// -----------------------------------------------------------------------------
/// Main router configuration using GoRouter with shell routes for bottom nav.

class AppRouter {
  AppRouter._();

  /// Global navigator key for accessing navigator state
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// Shell navigator key for bottom navigation
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  /// The main router instance
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true, // Enable logging in debug mode

    // -------------------------------------------------------------------------
    // Route Definitions
    // -------------------------------------------------------------------------
    routes: [
      // -----------------------------------------------------------------------
      // Splash Screen - Entry point
      // -----------------------------------------------------------------------
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // -----------------------------------------------------------------------
      // Onboarding Screen - First-time user experience
      // -----------------------------------------------------------------------
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // -----------------------------------------------------------------------
      // Authentication Routes
      // -----------------------------------------------------------------------
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        name: RouteNames.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // -----------------------------------------------------------------------
      // Main App Shell - Bottom Navigation Container
      // -----------------------------------------------------------------------
      // ShellRoute wraps the main screens with a persistent bottom nav bar.
      // This ensures the navigation bar remains visible while switching tabs.
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          // Home Tab
          GoRoute(
            path: RoutePaths.home,
            name: RouteNames.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          // Profile Tab
          GoRoute(
            path: RoutePaths.profile,
            name: RouteNames.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          // QR Code Tab (Central)
          GoRoute(
            path: RoutePaths.qrCode,
            name: RouteNames.qrCode,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: QrCodeScreen(),
            ),
          ),
          // Rankings Tab
          GoRoute(
            path: RoutePaths.rankings,
            name: RouteNames.rankings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RankingsScreen(),
            ),
          ),
          // Map Tab
          GoRoute(
            path: RoutePaths.map,
            name: RouteNames.map,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MapScreen(),
            ),
          ),
        ],
      ),

      // -----------------------------------------------------------------------
      // Standalone Routes (outside bottom nav)
      // -----------------------------------------------------------------------
      GoRoute(
        path: RoutePaths.notifications,
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RoutePaths.coupons,
        builder: (context, state) => const CouponsScreen(),
      ),
      GoRoute(
        path: RoutePaths.pointsHistory,
        builder: (context, state) => const PointsHistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.badges,
        builder: (context, state) => const BadgesScreen(),
      ),
      GoRoute(
        path: RoutePaths.offers,
        builder: (context, state) => const OffersScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.helpCenter,
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: RoutePaths.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: RoutePaths.plasticMetal,
        builder: (context, state) => const PlasticMetalScreen(),
      ),
      GoRoute(
        path: RoutePaths.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],

    // -------------------------------------------------------------------------
    // Error Handler
    // -------------------------------------------------------------------------
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page "${state.uri}" does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
