// =============================================================================
// SPLASH SCREEN - App Entry Animation
// =============================================================================
// The splash screen displays the REward logo on a deep green background.
// Uses actual logo assets from assets/images folder.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';

/// SplashScreen displays the app logo and handles initial navigation.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller for logo entrance
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _animationController.forward();

    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndNavigate();
    });
  }

  /// Initialize services and navigate to appropriate screen
  Future<void> _initializeAndNavigate() async {
    // Initialize auth service
    final authService = context.read<FirebaseAuthService>();
    await authService.initialize();

    // Wait for animation to complete plus a small delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Navigate based on auth state
    if (authService.isAuthenticated) {
      // User is logged in, go to home
      context.go(RoutePaths.home);
    } else {
      // New user, show onboarding
      context.go(RoutePaths.onboarding);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Deep forest green background matching Figma
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // RE Logo from assets
              Image.asset(
                'assets/images/logo_re.png',
                width: 140,
                height: 140,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image not found
                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D5A50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'RE',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4A7C6F),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // REward Logo Text from assets
              Image.asset(
                'assets/images/logo_text.png',
                height: 50,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image not found
                  return RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'RE',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4A7C6F),
                          ),
                        ),
                        TextSpan(
                          text: 'ward',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD4A574),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              // Tagline
              Text(
                'Recycle • Reward',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textOnPrimary.withOpacity(0.7),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
