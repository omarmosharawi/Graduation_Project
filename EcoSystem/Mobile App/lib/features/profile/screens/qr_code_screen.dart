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
// - Optional: Bluetooth connection status
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/ble_service.dart';

/// QrCodeScreen displays the user's unique QR code for kiosk identification
class QrCodeScreen extends StatelessWidget {
  const QrCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<FirebaseAuthService>();
    final bleService = context.watch<BleService>();
    final user = authService.currentUser;

    // Generate unique QR data (user ID + timestamp for security)
    final qrData = 'reward:${user?.id ?? "guest"}:${DateTime.now().millisecondsSinceEpoch}';

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
                    const SizedBox(height: 20),
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
                      text: 'Show this QR code to the scanner',
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

              const SizedBox(height: 24),

              // ---------------------------------------------------------------
              // Bluetooth Connection Status (Optional)
              // ---------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: bleService.isConnected
                        ? AppColors.success
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      bleService.isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: bleService.isConnected
                          ? AppColors.success
                          : AppColors.textHint,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bleService.isConnected
                                ? 'Connected to Kiosk'
                                : 'Not Connected',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: bleService.isConnected
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            bleService.isConnected
                                ? bleService.connectedDevice?.name ?? 'Unknown'
                                : 'Scan QR at kiosk to connect',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!bleService.isConnected)
                      TextButton(
                        onPressed: () async {
                          // Start BLE scan
                          await bleService.startScan();
                          // Show device selection dialog
                          if (context.mounted) {
                            _showDeviceSelectionDialog(context, bleService);
                          }
                        },
                        child: const Text('Scan'),
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

  /// Show dialog to select a BLE device
  void _showDeviceSelectionDialog(BuildContext context, BleService bleService) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer<BleService>(
        builder: (context, ble, _) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Kiosk',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (ble.connectionState == BleConnectionState.scanning)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (ble.discoveredDevices.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.bluetooth_searching,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Searching for kiosks...',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...ble.discoveredDevices.map((device) => ListTile(
                        leading: const Icon(Icons.recycling),
                        title: Text(device.name),
                        subtitle: Text('Signal: ${device.rssi} dBm'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          Navigator.pop(context);
                          await ble.connect(device);
                        },
                      )),
              ],
            ),
          );
        },
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
