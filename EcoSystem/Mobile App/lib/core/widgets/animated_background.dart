// =============================================================================
// ANIMATED BACKGROUND - Decorative floating shapes for home screen
// =============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Animated background with floating decorative shapes
class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    
    // Different speeds for each shape
    _controller1 = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
    
    _controller2 = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    
    _controller3 = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Large primary shape (top-right)
        AnimatedBuilder(
          animation: _controller1,
          builder: (context, child) {
            return Positioned(
              top: -50 + (20 * math.sin(_controller1.value * math.pi * 2)),
              right: -100 + (15 * math.cos(_controller1.value * math.pi * 2)),
              child: Transform.rotate(
                angle: _controller1.value * 0.1,
                child: CustomPaint(
                  size: const Size(350, 350),
                  painter: _WavyShapePainter(
                    color: AppColors.primary.withOpacity(0.12),
                    progress: _controller1.value,
                  ),
                ),
              ),
            );
          },
        ),
        
        // Secondary shape (left side)
        AnimatedBuilder(
          animation: _controller2,
          builder: (context, child) {
            return Positioned(
              top: 80 + (25 * math.sin(_controller2.value * math.pi * 2)),
              left: -100 + (10 * math.cos(_controller2.value * math.pi * 2)),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.02),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        // Small accent shape (bottom-right)
        AnimatedBuilder(
          animation: _controller3,
          builder: (context, child) {
            return Positioned(
              bottom: 200 + (15 * math.sin(_controller3.value * math.pi * 2)),
              right: -50 + (20 * math.cos(_controller3.value * math.pi * 2)),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.08),
                      AppColors.primary.withOpacity(0.01),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        // Main content
        widget.child,
      ],
    );
  }
}

/// Custom painter for wavy/organic shape similar to auth_background.svg
class _WavyShapePainter extends CustomPainter {
  final Color color;
  final double progress;

  _WavyShapePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Create organic shape inspired by auth_background.svg
    // Animated with slight morphing based on progress
    final waveOffset = progress * 10;
    
    path.moveTo(size.width * 0.1, 0);
    path.quadraticBezierTo(
      size.width * 0.5, 
      size.height * 0.1 + waveOffset,
      size.width * 0.9, 
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 1.1, 
      size.height * 0.4 - waveOffset,
      size.width * 0.95, 
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.8, 
      size.height * 0.85 + waveOffset,
      size.width * 0.4, 
      size.height * 0.9,
    );
    path.quadraticBezierTo(
      size.width * 0.1, 
      size.height * 0.95 - waveOffset,
      size.width * 0.05, 
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      0, 
      size.height * 0.4 + waveOffset,
      size.width * 0.1, 
      0,
    );
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavyShapePainter oldDelegate) => 
      oldDelegate.progress != progress;
}
