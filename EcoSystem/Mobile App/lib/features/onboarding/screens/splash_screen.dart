import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
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
    with TickerProviderStateMixin {
  // Animation controller for glow effect
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  
  // Animation controller for scale/bounce/dissolve effect
  late AnimationController _transitionController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _blurAnimation;
  
  // Audio player for the recycling sound effect
  final AudioPlayer _audioPlayer = AudioPlayer();

  // State to track transition
  bool _transitionTriggered = false;

  @override
  void initState() {
    super.initState();

    // 1. Setup pulsing glow animation (only for the green logo)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 2. Setup transition animation (dissolve + scale)
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Scaling for the secondary logo
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30), // Delay scale
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.1).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 30),
    ]).animate(_transitionController);

    // Opacity/Dissolve timing
    _opacityAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
    );

    // Blur effect for the dissolve
    _blurAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Initial audio setup
    _audioPlayer.setSourceAsset('audio/recycle_chime.mp3');

    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimationSequence();
    });
  }

  /// Sequence: Wait -> Dissolve/Sound -> Wait -> Navigate
  Future<void> _startAnimationSequence() async {
    // 1. Initialize services while showing the green logo
    final authService = context.read<FirebaseAuthService>();
    await authService.initialize();

    // Show initial logo pulsating for a moment
    await Future.delayed(const Duration(seconds: 1));
    
    // 2. Trigger dissolve animation and sound
    if (!mounted) return;
    
    // Play the transition chime
    _audioPlayer.play(AssetSource('audio/recycle_chime.mp3'));
    
    // Start the transition
    _transitionController.forward();

    setState(() {
      _transitionTriggered = true;
    });

    // Stop animating glow once it starts dissolving
    _animationController.stop();

    // 3. Wait for animation to settle
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // Navigate based on auth state
    if (authService.isAuthenticated) {
      context.go(RoutePaths.home);
    } else {
      context.go(RoutePaths.onboarding);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transitionController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_animationController, _transitionController]),
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Primary Logo (Dissolving)
                Opacity(
                  opacity: 1.0 - _opacityAnimation.value,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: _blurAnimation.value,
                      sigmaY: _blurAnimation.value,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (!_transitionTriggered) 
                            BoxShadow(
                              color: const Color(0xFF4A7C6F).withOpacity(0.6),
                              blurRadius: _glowAnimation.value * 3,
                              spreadRadius: _glowAnimation.value,
                            ),
                        ],
                      ),
                      child: _buildLogo('assets/logo/RE greensvg.png'),
                    ),
                  ),
                ),

                // Secondary Logo (Emerging)
                Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _buildLogo('assets/logo/logo_white.png'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo(String assetPath) {
    return Image.asset(
      assetPath,
      width: 250,
      height: 250,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox(
          width: 250,
          height: 250,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      },
    );
  }
}
