// =============================================================================
// AUTH BACKGROUND - Curved Green Background for Auth Screens
// =============================================================================
// Custom painter that draws the curved green background matching Figma design.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// Custom painter for the curved auth background
class AuthBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Start from top-left
    path.moveTo(0, 0);
    
    // Go to top-right
    path.lineTo(size.width, 0);
    
    // Go down on the right side with a curve
    path.lineTo(size.width, size.height * 0.6);
    
    // Create the curved bottom
    path.quadraticBezierTo(
      size.width * 0.7, size.height * 0.85,
      size.width * 0.35, size.height * 0.75,
    );
    
    // Continue the curve with wave effect
    path.quadraticBezierTo(
      size.width * 0.15, size.height * 0.68,
      0, size.height * 0.85,
    );
    
    // Back to start
    path.lineTo(0, 0);
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget wrapper for the auth background
class AuthBackground extends StatelessWidget {
  final double height;
  final Widget? child;

  const AuthBackground({
    super.key,
    required this.height,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(double.infinity, height),
            painter: AuthBackgroundPainter(),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
