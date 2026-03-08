// =============================================================================
// BLE CONFIG SERVICE - Configure ESP32 Kiosk via Bluetooth
// =============================================================================
// Scans for "REward-Kiosk" BLE devices, connects, and writes WiFi/Kiosk
// config values to the ESP32's BLE characteristics.
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/logger.dart';

/// BLE UUIDs matching the ESP32 KioskBLE.h definitions
class BleUuids {
  static final Guid service = Guid("12345678-1234-1234-1234-123456789abc");
  static final Guid charSsid = Guid("12345678-1234-1234-1234-000000000001");
  static final Guid charPass = Guid("12345678-1234-1234-1234-000000000002");
  static final Guid charKiosk = Guid("12345678-1234-1234-1234-000000000003");
  static final Guid charSecret = Guid("12345678-1234-1234-1234-000000000004");
}

/// Connection state for the BLE config flow
enum BleConfigState {
  idle,
  scanning,
  connecting,
  connected,
  sending,
  success,
  error,
}

/// BLE Configuration Service
class BleConfigService extends ChangeNotifier {
  BleConfigState _state = BleConfigState.idle;
  String _statusMessage = 'Ready to scan';
  final List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;
  BluetoothService? _configService;

  BleConfigState get state => _state;
  String get statusMessage => _statusMessage;
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);
  bool get isConnected => _state == BleConfigState.connected;
  String? get connectedDeviceName => _connectedDevice?.platformName;

  StreamSubscription<List<ScanResult>>? _scanSub;
  DateTime? _lastScanTime; // Cooldown to avoid Android scan throttle

  void _setState(BleConfigState newState, String message) {
    _state = newState;
    _statusMessage = message;
    notifyListeners();
  }

  // ===========================================================================
  // SCAN
  // ===========================================================================
  Future<void> startScan() async {
    try {
      // Guard: already scanning
      if (_state == BleConfigState.scanning) {
        return;
      }

      // Guard: Android throttle cooldown (max ~5 scans per 30s)
      if (_lastScanTime != null) {
        final elapsed = DateTime.now().difference(_lastScanTime!);
        if (elapsed.inSeconds < 8) {
          final wait = 8 - elapsed.inSeconds;
          _setState(BleConfigState.error,
              'Please wait $wait seconds before scanning again.');
          return;
        }
      }

      // Check Bluetooth is on
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        _setState(BleConfigState.error, 'Bluetooth is OFF. Please turn it on.');
        return;
      }

      _scanResults.clear();
      _setState(BleConfigState.scanning, 'Scanning for kiosks...');
      _lastScanTime = DateTime.now();

      // Cancel any previous scan
      await FlutterBluePlus.stopScan();

      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        _scanResults.clear();
        for (final r in results) {
          // Only show devices named "REward-Kiosk"
          if (r.device.platformName.contains('REward-Kiosk')) {
            _scanResults.add(r);
          }
        }
        notifyListeners();
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );

      if (_state == BleConfigState.scanning) {
        _setState(
          BleConfigState.idle,
          _scanResults.isEmpty
              ? 'No kiosks found. Make sure the ESP32 is powered on.'
              : '${_scanResults.length} kiosk(s) found',
        );
      }
    } catch (e) {
      AppLogger.error('BLE scan error: $e');
      final msg = e.toString();
      if (msg.contains('too frequently') || msg.contains('throttle')) {
        _setState(BleConfigState.error,
            'Scanning too fast. Please wait 30 seconds and try again.');
      } else {
        _setState(BleConfigState.error, 'Scan failed: $e');
      }
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    if (_state == BleConfigState.scanning) {
      _setState(BleConfigState.idle, 'Scan stopped');
    }
  }

  // ===========================================================================
  // CONNECT
  // ===========================================================================
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _setState(BleConfigState.connecting, 'Connecting to ${device.platformName}...');

      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Find our config service
      _configService = null;
      for (final s in services) {
        if (s.uuid == BleUuids.service) {
          _configService = s;
          break;
        }
      }

      if (_configService == null) {
        await device.disconnect();
        _setState(BleConfigState.error, 'Kiosk service not found. Is the firmware updated?');
        return false;
      }

      _setState(BleConfigState.connected, 'Connected to ${device.platformName}');
      AppLogger.info('BLE connected to ${device.platformName}');

      // Listen for disconnection
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _configService = null;
          if (_state != BleConfigState.success) {
            _setState(BleConfigState.idle, 'Disconnected');
          }
        }
      });

      return true;
    } catch (e) {
      AppLogger.error('BLE connect error: $e');
      _setState(BleConfigState.error, 'Connection failed: $e');
      return false;
    }
  }

  // ===========================================================================
  // SEND CONFIG
  // ===========================================================================
  Future<bool> sendConfig({
    required String ssid,
    required String password,
    required String kioskId,
    required String apiSecret,
  }) async {
    if (_configService == null || _connectedDevice == null) {
      _setState(BleConfigState.error, 'Not connected to a kiosk');
      return false;
    }

    try {
      _setState(BleConfigState.sending, 'Sending WiFi SSID...');
      await _writeCharacteristic(BleUuids.charSsid, ssid);

      _setState(BleConfigState.sending, 'Sending WiFi Password...');
      await _writeCharacteristic(BleUuids.charPass, password);

      _setState(BleConfigState.sending, 'Sending Kiosk ID...');
      await _writeCharacteristic(BleUuids.charKiosk, kioskId);

      _setState(BleConfigState.sending, 'Sending API Secret...');
      await _writeCharacteristic(BleUuids.charSecret, apiSecret);

      _setState(BleConfigState.success, 'Configuration sent successfully!');
      AppLogger.info('BLE config sent to ${_connectedDevice!.platformName}');
      return true;
    } catch (e) {
      AppLogger.error('BLE send error: $e');
      _setState(BleConfigState.error, 'Send failed: $e');
      return false;
    }
  }

  Future<void> _writeCharacteristic(Guid charUuid, String value) async {
    final characteristic = _configService!.characteristics.firstWhere(
      (c) => c.uuid == charUuid,
      orElse: () => throw Exception('Characteristic not found: $charUuid'),
    );
    await characteristic.write(utf8.encode(value), withoutResponse: false);
  }

  // ===========================================================================
  // READ CURRENT CONFIG
  // ===========================================================================
  Future<Map<String, String>> readCurrentConfig() async {
    if (_configService == null) return {};

    try {
      final result = <String, String>{};

      for (final c in _configService!.characteristics) {
        final value = await c.read();
        final decoded = utf8.decode(value);
        if (c.uuid == BleUuids.charSsid) result['ssid'] = decoded;
        if (c.uuid == BleUuids.charKiosk) result['kioskId'] = decoded;
        // Pass and Secret are masked on the ESP32 side
      }

      return result;
    } catch (e) {
      AppLogger.error('BLE read error: $e');
      return {};
    }
  }

  // ===========================================================================
  // DISCONNECT
  // ===========================================================================
  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (e) {
      AppLogger.error('BLE disconnect error: $e');
    }
    _connectedDevice = null;
    _configService = null;
    _setState(BleConfigState.idle, 'Disconnected');
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }
}
