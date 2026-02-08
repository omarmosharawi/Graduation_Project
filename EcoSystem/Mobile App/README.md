# REward Flutter App

<div align="center">
  <img src="assets/images/logo.png" alt="REward Logo" width="120"/>
  
  **A smart recycling vending machine app that rewards users for recycling bottles and cans**
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.6+-blue.svg)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)
  [![License](https://img.shields.io/badge/License-Private-red.svg)]()
</div>

---

## 📖 Overview

REward is a Flutter-based Android application that connects with ESP32-powered recycling kiosks to reward users for recycling plastic bottles and aluminum cans. Users earn points that can be redeemed for discounts at partner businesses.

### Key Features

- 🔐 **User Authentication** - Email/phone registration with secure login
- 📱 **QR Code Identification** - Unique QR codes for kiosk identification
- 🗺️ **Kiosk Locator** - Interactive map to find nearby recycling points
- ⭐ **Points System** - Earn and track recycling rewards
- 🏆 **Leaderboards** - Compete with other recyclers
- 🎁 **Rewards Catalog** - Browse and redeem discounts
- 📶 **ESP32 Communication** - Bluetooth Low Energy (BLE) connectivity

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.6+ |
| Language | Dart 3.0+ |
| State Management | Provider |
| Navigation | GoRouter |
| Bluetooth | flutter_blue_plus |
| QR Generation | qr_flutter |
| Maps | Google Maps Flutter |
| HTTP Client | Dio |
| Storage | Shared Preferences, Flutter Secure Storage |

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (v3.6.0 or higher)
   ```bash
   flutter --version
   ```

2. **Android Studio** (with Android SDK)
   - Android SDK API level 21 or higher
   - Android emulator or physical device

3. **Git** (for version control)
   ```bash
   git --version
   ```

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/reward-app.git
cd reward-app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Android Permissions

The app requires the following permissions (already configured in `AndroidManifest.xml`):

- `BLUETOOTH` - For ESP32 communication
- `BLUETOOTH_SCAN` - For scanning BLE devices
- `BLUETOOTH_CONNECT` - For connecting to BLE devices
- `ACCESS_FINE_LOCATION` - For kiosk locator map
- `INTERNET` - For API communication

### 4. (Optional) Configure Google Maps API Key

To enable the interactive map feature:

1. Get an API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY_HERE"/>
   ```

### 5. Run the App

```bash
# Run in debug mode
flutter run

# Run on a specific device
flutter run -d <device_id>

# List available devices
flutter devices
```

---

## 📁 Project Structure

```
reward_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app/
│   │   ├── routes.dart              # GoRouter configuration
│   │   └── theme.dart               # App theme (colors, typography)
│   ├── core/
│   │   ├── services/
│   │   │   ├── auth_service.dart    # Authentication logic
│   │   │   └── ble_service.dart     # ESP32 BLE communication
│   │   ├── utils/
│   │   │   └── logger.dart          # Logging utility
│   │   └── widgets/
│   │       └── main_scaffold.dart   # Bottom navigation container
│   └── features/
│       ├── auth/                    # Login, signup, forgot password
│       ├── onboarding/              # Splash, onboarding screens
│       ├── home/                    # Dashboard
│       ├── profile/                 # User profile, QR code
│       ├── map/                     # Kiosk locator
│       ├── rankings/                # Leaderboard
│       ├── rewards/                 # Rewards catalog
│       └── notifications/           # Notifications
├── assets/
│   ├── images/                      # App images
│   ├── icons/                       # Custom icons
│   └── animations/                  # Lottie animations
└── android/                         # Android-specific configuration
```

---

## 🎨 Theme Configuration

The app uses a custom theme based on the Figma design:

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | `#1E3A34` | Deep Forest Green - Main brand color |
| Secondary | `#4CAF50` | Light Mint Green - Accents |
| Background | `#F5F5F5` | Light Gray - Screen backgrounds |
| Surface | `#FFFFFF` | White - Cards and containers |

---

## 📶 ESP32 Communication

The app communicates with ESP32 recycling kiosks via Bluetooth Low Energy (BLE).

### BLE UUIDs (Configure in ESP32 firmware)

- **Service UUID**: `12345678-1234-1234-1234-123456789abc`
- **User ID Characteristic**: `12345678-1234-1234-1234-123456789001`
- **Item Counter Characteristic**: `12345678-1234-1234-1234-123456789002`
- **LCD Display Characteristic**: `12345678-1234-1234-1234-123456789003`
- **Session Control Characteristic**: `12345678-1234-1234-1234-123456789004`

### Communication Flow

1. User scans QR code at kiosk OR enters phone number on keypad
2. App connects to kiosk via BLE
3. Kiosk sends item count updates as user deposits recyclables
4. App calculates points and updates user balance
5. Session ends and points are confirmed

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/auth_service_test.dart
```

---

## 📦 Building for Release

```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

The release APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🤝 Contributing

1. Create a feature branch: `git checkout -b feature/new-feature`
2. Commit your changes: `git commit -m "Add new feature"`
3. Push to the branch: `git push origin feature/new-feature`
4. Open a Pull Request

---

## 📄 License

This project is private and proprietary. All rights reserved.

---

## 📞 Support

For questions or issues, please contact the development team.

---

<div align="center">
  <strong>REward - Recycle. Earn. Reward.</strong>
  <br/>
  Made with ❤️ for a greener future
</div>
