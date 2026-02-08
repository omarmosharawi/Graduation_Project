// =============================================================================
// ONBOARDING SCREEN - First-Time User Experience
// =============================================================================
// Uses actual assets from assets/images folder for logo and illustration.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';

/// OnboardingScreen displays the welcome page before login
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // Profile Icon (top right as in Figma)
              // ---------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.textOnPrimary,
                      size: 22,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // REward Logo from assets
              // ---------------------------------------------------------------
              Image.asset(
                'assets/images/logo_text.png',
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  return RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'RE',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4A7C6F),
                          ),
                        ),
                        TextSpan(
                          text: 'ward',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD4A574),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                'Recycle • Reward',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textOnPrimary.withOpacity(0.6),
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 32),

              // ---------------------------------------------------------------
              // Illustration Card with actual illustration
              // ---------------------------------------------------------------
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/onboarding_illustration.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback illustration
                        return Container(
                          color: AppColors.secondaryLight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.recycling,
                                size: 80,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Recycle & Earn',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ---------------------------------------------------------------
              // Welcome Text
              // ---------------------------------------------------------------
              const Text(
                'Welcome to REward',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Earn rewards for recycling',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textOnPrimary.withOpacity(0.7),
                ),
              ),

              const SizedBox(height: 32),

              // ---------------------------------------------------------------
              // Get Started Button
              // ---------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(RoutePaths.login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryLight,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
