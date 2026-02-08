# REward ♻️

A Flutter-based recycling rewards application with ESP32-powered kiosk integration.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange?logo=firebase)
![PHP](https://img.shields.io/badge/API-PHP-purple?logo=php)
![ESP32](https://img.shields.io/badge/Hardware-ESP32-green)

## 📱 Overview

REward incentivizes recycling by rewarding users with points for recycling plastic and metal items at smart kiosks. Points can be redeemed for exclusive offers from partner businesses.

### Features

- 🔐 **Authentication** - Email/password & Google Sign-In
- ♻️ **Smart Kiosks** - Real-time kiosk status and recycling tracking
- 🏆 **Leaderboard** - Weekly and all-time rankings
- 🎁 **Rewards** - Redeem points for partner offers
- 📍 **Kiosk Map** - Find nearby recycling kiosks with distance
- 🔔 **Push Notifications** - Points earned, new offers, announcements
- 🛡️ **Admin Dashboard** - Manage offers, kiosks, announcements

---

## 🏗️ Project Structure

```
REward/
├── reward_app/          # Flutter mobile application
│   ├── lib/
│   │   ├── app/         # Theme, routes, constants
│   │   ├── core/        # Services, widgets, utilities
│   │   └── features/    # Feature-based modules
│   └── pubspec.yaml
│
├── api/                 # PHP REST API (Hostinger)
│   ├── endpoints/       # API endpoint handlers
│   ├── config.php       # Configuration (credentials)
│   ├── firebase.php     # FCM & Firestore helpers
│   └── index.php        # Main router
│
└── docs/                # Documentation & wiki
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.x
- Android Studio / VS Code
- Firebase project
- Hostinger hosting (for API)

### Flutter App Setup

```bash
# Clone repository
git clone https://github.com/yourusername/reward.git
cd reward/reward_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Firebase Setup

1. Create Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Authentication (Email/Password, Google)
3. Create Firestore database
4. Download `google-services.json` → `reward_app/android/app/`
5. Update Firestore security rules (see [Wiki](docs/FIRESTORE_RULES.md))

### API Setup (Hostinger)

1. Upload `api/` folder to `public_html/api/`
2. Edit `config.php` with your credentials
3. Get FCM Server Key from Firebase Console
4. See [API Documentation](api/README.md)

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [App Architecture](docs/APP_ARCHITECTURE.md) | Flutter app structure |
| [API Reference](docs/API_REFERENCE.md) | REST API endpoints |
| [Firestore Schema](docs/FIRESTORE_SCHEMA.md) | Database structure |
| [ESP32 Integration](docs/ESP32_INTEGRATION.md) | Hardware setup |
| [Firestore Rules](docs/FIRESTORE_RULES.md) | Security rules |

---

## 🔧 Tech Stack

### Mobile App
- **Framework:** Flutter 3.x
- **State Management:** Provider
- **Navigation:** GoRouter
- **Backend:** Firebase (Auth, Firestore)
- **Maps:** Google Maps Flutter
- **Notifications:** Firebase Cloud Messaging

### API
- **Language:** PHP 8.x
- **Hosting:** Hostinger
- **Integration:** Firestore REST API, FCM HTTP API

### Hardware
- **Microcontroller:** ESP32-S
- **Camera:** ESP32-CAM (OV2640)
- **Sensors:** Inductive (metal), IR (plastic)
- **Display:** OLED 1.14" RGB
- **Actuator:** MG995 Servo

---

## 🔐 Environment Variables

### Flutter App
Firebase configuration is stored in `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).

### API (`config.php`)
```php
FCM_SERVER_KEY     # Firebase Cloud Messaging server key
FIREBASE_PROJECT_ID # Your Firebase project ID
API_SECRET_KEY     # Secret key for ESP32 authentication
```

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/` | Health check |
| POST | `/api/notify/topic` | Send push to topic |
| POST | `/api/notify/user` | Send push to user |
| POST | `/api/kiosk/{id}/status` | Update kiosk status |
| POST | `/api/kiosk/transaction` | Submit recycling transaction |
| GET | `/api/kiosk/{id}` | Get kiosk info |
| GET | `/api/user/{id}` | Get user info |

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

---

## 👥 Team

Built with ❤️ for the environment by the REward Team.
