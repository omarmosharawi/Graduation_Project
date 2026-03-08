// =============================================================================
// BLE CONFIG SCREEN - Configure ESP32 Kiosk via Bluetooth
// =============================================================================
// Admin screen to scan for nearby ESP32 kiosks, connect via BLE, and
// send WiFi credentials + Kiosk ID configuration wirelessly.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../core/services/ble_config_service.dart';
import '../../../core/services/kiosk_service.dart';
import '../../../core/utils/logger.dart';

class BleConfigScreen extends StatefulWidget {
  const BleConfigScreen({super.key});

  @override
  State<BleConfigScreen> createState() => _BleConfigScreenState();
}

class _BleConfigScreenState extends State<BleConfigScreen> {
  final BleConfigService _bleService = BleConfigService();

  final _ssidController = TextEditingController();
  final _passController = TextEditingController();
  final _kioskIdController = TextEditingController();
  final _secretController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    _bleService.addListener(_onBleStateChanged);

    // Pre-fill with current defaults
    _ssidController.text = 'Wazonet';
    _kioskIdController.text = 'kiosk_01';
    _secretController.text = '53cdf4760cdd5bd629a0b214d80e15ec';
    _capacityController.text = '100';
  }

  void _onBleStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _bleService.removeListener(_onBleStateChanged);
    _bleService.dispose();
    _ssidController.dispose();
    _passController.dispose();
    _kioskIdController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configure Kiosk'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Scan Section
            _buildScanSection(),
            const SizedBox(height: 16),

            // Config Form (only when connected)
            if (_bleService.isConnected) ...[
              _buildConfigForm(),
              const SizedBox(height: 16),
              _buildSendButton(),
            ],

            // Success message
            if (_bleService.state == BleConfigState.success)
              _buildSuccessCard(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // STATUS CARD
  // ===========================================================================
  Widget _buildStatusCard() {
    final state = _bleService.state;
    Color statusColor;
    IconData statusIcon;

    switch (state) {
      case BleConfigState.idle:
        statusColor = AppColors.textHint;
        statusIcon = Icons.bluetooth;
        break;
      case BleConfigState.scanning:
        statusColor = AppColors.info;
        statusIcon = Icons.bluetooth_searching;
        break;
      case BleConfigState.connecting:
        statusColor = AppColors.warning;
        statusIcon = Icons.bluetooth_connected;
        break;
      case BleConfigState.connected:
        statusColor = AppColors.success;
        statusIcon = Icons.bluetooth_connected;
        break;
      case BleConfigState.sending:
        statusColor = AppColors.warning;
        statusIcon = Icons.send;
        break;
      case BleConfigState.success:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case BleConfigState.error:
        statusColor = AppColors.error;
        statusIcon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          if (state == BleConfigState.scanning ||
              state == BleConfigState.connecting ||
              state == BleConfigState.sending)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            )
          else
            Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stateLabel(_bleService.state),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _bleService.statusMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_bleService.isConnected)
            TextButton(
              onPressed: () => _bleService.disconnect(),
              child: const Text('Disconnect', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
    );
  }

  String _stateLabel(BleConfigState state) {
    switch (state) {
      case BleConfigState.idle:
        return 'Ready';
      case BleConfigState.scanning:
        return 'Scanning...';
      case BleConfigState.connecting:
        return 'Connecting...';
      case BleConfigState.connected:
        return 'Connected';
      case BleConfigState.sending:
        return 'Sending Config...';
      case BleConfigState.success:
        return 'Success!';
      case BleConfigState.error:
        return 'Error';
    }
  }

  // ===========================================================================
  // SCAN SECTION
  // ===========================================================================
  Widget _buildScanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scan button
        ElevatedButton.icon(
          onPressed: _bleService.state == BleConfigState.scanning
              ? () => _bleService.stopScan()
              : () async {
                  await _requestPermissions();
                  await _bleService.startScan();
                },
          icon: Icon(
            _bleService.state == BleConfigState.scanning
                ? Icons.stop
                : Icons.bluetooth_searching,
          ),
          label: Text(
            _bleService.state == BleConfigState.scanning
                ? 'Stop Scanning'
                : 'Scan for Kiosks',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 12),

        // Device list
        if (_bleService.scanResults.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Nearby Kiosks',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ...(_bleService.scanResults.map((result) => _buildDeviceTile(result))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDeviceTile(ScanResult result) {
    final device = result.device;
    final isConnected = _bleService.connectedDeviceName == device.platformName;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isConnected
              ? AppColors.success.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isConnected ? Icons.bluetooth_connected : Icons.router,
          color: isConnected ? AppColors.success : AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        device.platformName.isNotEmpty ? device.platformName : 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'RSSI: ${result.rssi} dBm • ${device.remoteId}',
        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
      ),
      trailing: isConnected
          ? const Chip(
              label: Text('Connected', style: TextStyle(fontSize: 11, color: Colors.white)),
              backgroundColor: AppColors.success,
              padding: EdgeInsets.zero,
            )
          : OutlinedButton(
              onPressed: _bleService.state == BleConfigState.connecting
                  ? null
                  : () async {
                      final connected = await _bleService.connectToDevice(device);
                      if (connected) {
                        // Try to read current config
                        final config = await _bleService.readCurrentConfig();
                        if (config.containsKey('ssid')) {
                          _ssidController.text = config['ssid']!;
                        }
                        if (config.containsKey('kioskId')) {
                          _kioskIdController.text = config['kioskId']!;
                        }
                      }
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Connect', style: TextStyle(fontSize: 12)),
            ),
    );
  }

  // ===========================================================================
  // CONFIG FORM
  // ===========================================================================
  Widget _buildConfigForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Kiosk Configuration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'These values will be sent to the ESP32 and saved to its flash memory.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Divider(height: 24),

          // WiFi SSID
          TextField(
            controller: _ssidController,
            decoration: const InputDecoration(
              labelText: 'WiFi SSID',
              hintText: 'Network name',
              prefixIcon: Icon(Icons.wifi),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // WiFi Password
          TextField(
            controller: _passController,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'WiFi Password',
              hintText: 'Network password',
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Kiosk ID
          TextField(
            controller: _kioskIdController,
            decoration: const InputDecoration(
              labelText: 'Kiosk ID',
              hintText: 'e.g. kiosk_01',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // API Secret
          TextField(
            controller: _secretController,
            obscureText: _obscureSecret,
            decoration: InputDecoration(
              labelText: 'API Secret Key',
              hintText: 'Server authentication key',
              prefixIcon: const Icon(Icons.key),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureSecret ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Storage Capacity
          TextField(
            controller: _capacityController,
            decoration: const InputDecoration(
              labelText: 'Storage Capacity (Max Items)',
              hintText: 'e.g. 100',
              prefixIcon: Icon(Icons.storage),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SEND BUTTON
  // ===========================================================================
  Widget _buildSendButton() {
    final isSending = _bleService.state == BleConfigState.sending;

    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isSending ? null : _sendConfig,
        icon: isSending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send),
        label: Text(isSending ? 'Sending...' : 'Send Configuration'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _sendConfig() async {
    // Validate
    if (_ssidController.text.isEmpty) {
      _showSnackBar('Please enter the WiFi SSID');
      return;
    }
    if (_passController.text.isEmpty) {
      _showSnackBar('Please enter the WiFi Password');
      return;
    }
    if (_kioskIdController.text.isEmpty) {
      _showSnackBar('Please enter the Kiosk ID');
      return;
    }
    if (_secretController.text.isEmpty) {
      _showSnackBar('Please enter the API Secret');
      return;
    }

    final success = await _bleService.sendConfig(
      ssid: _ssidController.text,
      password: _passController.text,
      kioskId: _kioskIdController.text,
      apiSecret: _secretController.text,
    );

    // Address issue: machine not appearing in list (consistent IDs and storage)
    if (success && mounted) {
      try {
        final kioskService = Provider.of<KioskService>(context, listen: false);
        final maxCap = int.tryParse(_capacityController.text) ?? 100;
        
        // Check if kiosk exists, if not create it
        final existingKiosk = await kioskService.getKiosk(_kioskIdController.text);
        if (existingKiosk == null) {
          AppLogger.info('Registering new kiosk in Firestore: ${_kioskIdController.text}');
          await kioskService.createKiosk(Kiosk(
            id: _kioskIdController.text,
            name: 'Kiosk ${_kioskIdController.text}',
            address: 'Configured via BLE',
            latitude: 30.0, // Default for testing
            longitude: 31.0, // Default for testing
            status: 'available',
            maxCapacity: maxCap,
          ));
        } else {
          AppLogger.info('Updating existing kiosk in Firestore: ${_kioskIdController.text}');
          await kioskService.updateKiosk(_kioskIdController.text, {
            'status': 'available',
            'maxCapacity': maxCap,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
        
        _showSnackBar('Config sent and Storage updated!', isSuccess: true);

        // Auto-disconnect after success (user request)
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          await _bleService.disconnect();
          _showSnackBar('Bluetooth disconnected.', isSuccess: true);
        }
      } catch (e) {
        AppLogger.error('Failed to register kiosk in Firestore: $e');
        _showSnackBar('Config sent, but database registration failed: $e');
      }
    }
  }

  // ===========================================================================
  // SUCCESS CARD
  // ===========================================================================
  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 48),
          SizedBox(height: 12),
          Text(
            'Configuration Sent!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'The kiosk is now reconnecting to WiFi with the new credentials. '
            'Check the kiosk screen for confirmation.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : null,
      ),
    );
  }
}
