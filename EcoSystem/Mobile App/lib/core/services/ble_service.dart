// =============================================================================
// BLE SERVICE - Bluetooth Low Energy for ESP32 Communication
// =============================================================================
// This service manages Bluetooth communication with the ESP32 recycling kiosk.
//
// Communication Protocol:
// - Scan for nearby ESP32 devices
// - Connect to selected kiosk
// - Receive keypad input (phone number)
// - Send LCD display updates
// - Receive recycling item counts
// - Calculate and send points updates
//
// BLE Characteristics:
// - User Identification (phone number / QR code)
// - Item Counter (bottles/cans deposited)
// - Points Calculator
// - LCD Display Control
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/logger.dart';

/// -----------------------------------------------------------------------------
/// Connection State Enum
/// -----------------------------------------------------------------------------
/// Represents the current state of the Bluetooth connection.

enum BleConnectionState {
  disconnected,  // No connection
  scanning,      // Scanning for devices
  connecting,    // Attempting to connect
  connected,     // Successfully connected
  error,         // Connection error
}

/// -----------------------------------------------------------------------------
/// Kiosk Device Model
/// -----------------------------------------------------------------------------
/// Represents a discovered ESP32 kiosk device.

class KioskDevice {
  final String id;           // Device MAC address
  final String name;         // Device advertised name
  final int rssi;            // Signal strength
  final BluetoothDevice device;

  const KioskDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.device,
  });
}

/// -----------------------------------------------------------------------------
/// Recycling Session Data
/// -----------------------------------------------------------------------------
/// Holds data for an active recycling session.

class RecyclingSession {
  final String kioskId;
  final DateTime startTime;
  int plasticBottles;
  int aluminumCans;
  int pointsEarned;
  bool isComplete;

  RecyclingSession({
    required this.kioskId,
    required this.startTime,
    this.plasticBottles = 0,
    this.aluminumCans = 0,
    this.pointsEarned = 0,
    this.isComplete = false,
  });

  /// Calculate total points based on items
  /// Points: 1 point per plastic bottle, 2 points per aluminum can
  int calculatePoints() {
    return plasticBottles + (aluminumCans * 2);
  }
}

/// -----------------------------------------------------------------------------
/// BLE Service
/// -----------------------------------------------------------------------------
/// ChangeNotifier that manages BLE communication with ESP32 kiosks.

class BleService extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // BLE UUIDs (These should match your ESP32 firmware)
  // ---------------------------------------------------------------------------
  
  /// Service UUID for the recycling kiosk
  static const String kioskServiceUuid = '12345678-1234-1234-1234-123456789abc';
  
  /// Characteristic for user identification (write)
  static const String userIdCharUuid = '12345678-1234-1234-1234-123456789001';
  
  /// Characteristic for item counter (notify)
  static const String itemCounterCharUuid = '12345678-1234-1234-1234-123456789002';
  
  /// Characteristic for LCD display (write)
  static const String lcdDisplayCharUuid = '12345678-1234-1234-1234-123456789003';
  
  /// Characteristic for session control (read/write)
  static const String sessionControlCharUuid = '12345678-1234-1234-1234-123456789004';

  // ---------------------------------------------------------------------------
  // State Variables
  // ---------------------------------------------------------------------------

  BleConnectionState _connectionState = BleConnectionState.disconnected;
  List<KioskDevice> _discoveredDevices = [];
  KioskDevice? _connectedDevice;
  RecyclingSession? _currentSession;
  String? _error;
  bool _isBluetoothOn = false;

  // BLE subscriptions
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _itemCounterSubscription;

  // Connected device characteristics
  BluetoothCharacteristic? _userIdChar;
  BluetoothCharacteristic? _itemCounterChar;
  BluetoothCharacteristic? _lcdDisplayChar;
  BluetoothCharacteristic? _sessionControlChar;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// Current connection state
  BleConnectionState get connectionState => _connectionState;

  /// List of discovered kiosk devices
  List<KioskDevice> get discoveredDevices => _discoveredDevices;

  /// Currently connected device
  KioskDevice? get connectedDevice => _connectedDevice;

  /// Current recycling session
  RecyclingSession? get currentSession => _currentSession;

  /// Last error message
  String? get error => _error;

  /// Whether Bluetooth is enabled on the device
  bool get isBluetoothOn => _isBluetoothOn;

  /// Whether currently connected to a kiosk
  bool get isConnected => _connectionState == BleConnectionState.connected;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize the BLE service and check Bluetooth status
  Future<void> initialize() async {
    try {
      // Check if Bluetooth is available
      if (!await FlutterBluePlus.isSupported) {
        _error = 'Bluetooth is not supported on this device';
        AppLogger.error(_error!);
        notifyListeners();
        return;
      }

      // Listen to Bluetooth adapter state changes
      FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
        _isBluetoothOn = state == BluetoothAdapterState.on;
        
        if (!_isBluetoothOn && _connectionState == BleConnectionState.connected) {
          _handleDisconnection();
        }
        
        notifyListeners();
      });

      // Check initial state
      _isBluetoothOn = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      notifyListeners();

      AppLogger.info('BLE Service initialized, Bluetooth is ${_isBluetoothOn ? "ON" : "OFF"}');
    } catch (e) {
      AppLogger.error('Failed to initialize BLE service', e);
      _error = 'Failed to initialize Bluetooth';
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Scanning Methods
  // ---------------------------------------------------------------------------

  /// Start scanning for nearby ESP32 kiosk devices
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (!_isBluetoothOn) {
      _error = 'Please enable Bluetooth';
      notifyListeners();
      return;
    }

    if (_connectionState == BleConnectionState.scanning) {
      return; // Already scanning
    }

    try {
      _connectionState = BleConnectionState.scanning;
      _discoveredDevices = [];
      _error = null;
      notifyListeners();

      AppLogger.info('Starting BLE scan...');

      // Stop any existing scan
      await FlutterBluePlus.stopScan();

      // Start new scan
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _discoveredDevices = results
            .where((r) => r.device.platformName.isNotEmpty)
            .map((r) => KioskDevice(
                  id: r.device.remoteId.str,
                  name: r.device.platformName,
                  rssi: r.rssi,
                  device: r.device,
                ))
            .toList();
        notifyListeners();
      });

      // Start scanning with timeout
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );

      // Update state after scan completes
      _connectionState = BleConnectionState.disconnected;
      notifyListeners();

      AppLogger.info('BLE scan complete, found ${_discoveredDevices.length} devices');
    } catch (e) {
      AppLogger.error('Scan failed', e);
      _error = 'Failed to scan for devices';
      _connectionState = BleConnectionState.error;
      notifyListeners();
    }
  }

  /// Stop the current scan
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _connectionState = BleConnectionState.disconnected;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Connection Methods
  // ---------------------------------------------------------------------------

  /// Connect to a kiosk device
  Future<bool> connect(KioskDevice device) async {
    try {
      _connectionState = BleConnectionState.connecting;
      _error = null;
      notifyListeners();

      AppLogger.info('Connecting to ${device.name}...');

      // Connect to the device
      await device.device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      // Listen to connection state
      _connectionSubscription = device.device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Discover services and characteristics
      await _discoverServices(device.device);

      _connectedDevice = device;
      _connectionState = BleConnectionState.connected;
      notifyListeners();

      AppLogger.info('Connected to ${device.name}');
      return true;
    } catch (e) {
      AppLogger.error('Connection failed', e);
      _error = 'Failed to connect to kiosk';
      _connectionState = BleConnectionState.error;
      notifyListeners();
      return false;
    }
  }

  /// Discover BLE services and characteristics
  Future<void> _discoverServices(BluetoothDevice device) async {
    AppLogger.info('Discovering services...');

    final services = await device.discoverServices();

    for (final service in services) {
      if (service.uuid.toString().toLowerCase() == kioskServiceUuid.toLowerCase()) {
        AppLogger.info('Found kiosk service');

        for (final char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();

          if (uuid == userIdCharUuid.toLowerCase()) {
            _userIdChar = char;
            AppLogger.info('Found user ID characteristic');
          } else if (uuid == itemCounterCharUuid.toLowerCase()) {
            _itemCounterChar = char;
            AppLogger.info('Found item counter characteristic');
            // Subscribe to notifications
            await _subscribeToItemCounter();
          } else if (uuid == lcdDisplayCharUuid.toLowerCase()) {
            _lcdDisplayChar = char;
            AppLogger.info('Found LCD display characteristic');
          } else if (uuid == sessionControlCharUuid.toLowerCase()) {
            _sessionControlChar = char;
            AppLogger.info('Found session control characteristic');
          }
        }
      }
    }
  }

  /// Subscribe to item counter notifications
  Future<void> _subscribeToItemCounter() async {
    if (_itemCounterChar == null) return;

    try {
      await _itemCounterChar!.setNotifyValue(true);
      
      _itemCounterSubscription = _itemCounterChar!.value.listen((value) {
        if (value.isNotEmpty && _currentSession != null) {
          _handleItemCountUpdate(value);
        }
      });
    } catch (e) {
      AppLogger.error('Failed to subscribe to item counter', e);
    }
  }

  /// Handle item count updates from ESP32
  void _handleItemCountUpdate(List<int> data) {
    if (_currentSession == null) return;

    try {
      // Expected format: [plasticCount, aluminumCount]
      if (data.length >= 2) {
        _currentSession!.plasticBottles = data[0];
        _currentSession!.aluminumCans = data[1];
        _currentSession!.pointsEarned = _currentSession!.calculatePoints();
        notifyListeners();

        AppLogger.info('Item count updated: ${data[0]} bottles, ${data[1]} cans');
      }
    } catch (e) {
      AppLogger.error('Failed to parse item count', e);
    }
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    try {
      await _itemCounterSubscription?.cancel();
      await _connectionSubscription?.cancel();
      await _connectedDevice?.device.disconnect();
      _handleDisconnection();
    } catch (e) {
      AppLogger.error('Disconnect failed', e);
    }
  }

  /// Handle disconnection cleanup
  void _handleDisconnection() {
    _connectedDevice = null;
    _userIdChar = null;
    _itemCounterChar = null;
    _lcdDisplayChar = null;
    _sessionControlChar = null;
    _currentSession = null;
    _connectionState = BleConnectionState.disconnected;
    notifyListeners();

    AppLogger.info('Disconnected from kiosk');
  }

  // ---------------------------------------------------------------------------
  // Session Methods
  // ---------------------------------------------------------------------------

  /// Start a new recycling session
  Future<bool> startSession(String userId) async {
    if (!isConnected || _connectedDevice == null) {
      _error = 'Not connected to a kiosk';
      notifyListeners();
      return false;
    }

    try {
      // Send user ID to kiosk
      if (_userIdChar != null) {
        await _userIdChar!.write(utf8.encode(userId));
      }

      // Create new session
      _currentSession = RecyclingSession(
        kioskId: _connectedDevice!.id,
        startTime: DateTime.now(),
      );

      // Update LCD display
      await sendLcdMessage('Welcome! Start recycling');

      notifyListeners();
      AppLogger.info('Recycling session started for user: $userId');
      return true;
    } catch (e) {
      AppLogger.error('Failed to start session', e);
      _error = 'Failed to start session';
      notifyListeners();
      return false;
    }
  }

  /// End the current recycling session
  Future<RecyclingSession?> endSession() async {
    if (_currentSession == null) return null;

    try {
      _currentSession!.isComplete = true;

      // Send session end command
      if (_sessionControlChar != null) {
        await _sessionControlChar!.write([0x00]); // End session command
      }

      await sendLcdMessage('Thank you! +${_currentSession!.pointsEarned} pts');

      final session = _currentSession;
      _currentSession = null;
      notifyListeners();

      AppLogger.info('Session ended: ${session!.pointsEarned} points earned');
      return session;
    } catch (e) {
      AppLogger.error('Failed to end session', e);
      _error = 'Failed to end session';
      notifyListeners();
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // LCD Display Methods
  // ---------------------------------------------------------------------------

  /// Send a message to the kiosk LCD display
  Future<void> sendLcdMessage(String message) async {
    if (_lcdDisplayChar == null) return;

    try {
      // Truncate message to LCD size (typically 16-20 chars per line)
      final truncated = message.length > 32 ? message.substring(0, 32) : message;
      await _lcdDisplayChar!.write(utf8.encode(truncated));
      AppLogger.info('LCD message sent: $message');
    } catch (e) {
      AppLogger.error('Failed to send LCD message', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Keypad Input Methods
  // ---------------------------------------------------------------------------

  /// Verify a phone number entered via kiosk keypad
  /// This would typically be called when the kiosk sends a verification request
  Future<bool> verifyPhoneNumber(String phoneNumber) async {
    // TODO: Verify phone number with backend
    // For now, just validate format
    final phoneRegex = RegExp(r'^\+?[\d]{10,15}$');
    return phoneRegex.hasMatch(phoneNumber.replaceAll(RegExp(r'[\s-]'), ''));
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  /// Dispose of resources
  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _itemCounterSubscription?.cancel();
    disconnect();
    super.dispose();
  }

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
