// =============================================================================
// QR CODE SCREEN - User Identification at Kiosks
// =============================================================================
// Central screen displaying the user's unique QR code for kiosk identification.
// This is the primary action for starting a recycling session.
//
// Features:
// - Large, scannable QR code
// - User ID encoded in QR
// - Instructions for use
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';

/// QrCodeScreen displays the user's unique QR code for kiosk identification
class QrCodeScreen extends StatelessWidget {
  const QrCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<FirebaseAuthService>();
    final user = authService.currentUser;

    // Use persistent 8-digit kiosk code for QR identification
    final kioskCode = user?.kioskCode ?? 'NO_CODE';
    final qrData = 'reward:$kioskCode';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My QR Code'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // QR Code Container
              // ---------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // QR Code
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 250,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.primary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.primary,
                      ),
                      embeddedImage: null, // Could add logo here
                      embeddedImageStyle: const QrEmbeddedImageStyle(
                        size: Size(40, 40),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 8-digit kiosk code (for manual entry)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        kioskCode.replaceAllMapped(
                          RegExp(r'.{4}'),
                          (match) => '${match.group(0)} ',
                        ).trim(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: AppColors.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your Kiosk ID',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // User info
                    Text(
                      user?.name ?? 'Guest User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'Please login',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ---------------------------------------------------------------
              // Instructions
              // ---------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'How to Use',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _InstructionStep(
                      number: '1',
                      text: 'Find a REward kiosk near you',
                    ),
                    const _InstructionStep(
                      number: '2',
                      text: 'Scan this QR code or enter code on keypad',
                    ),
                    const _InstructionStep(
                      number: '3',
                      text: 'Insert your bottles and cans',
                    ),
                    const _InstructionStep(
                      number: '4',
                      text: 'Collect your points automatically!',
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 100), // Bottom nav padding
            ],
          ),
        ),
      ),
    );
  }
}

/// Instruction step widget
class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
