# REward API

PHP API for the REward recycling app. Handles push notifications and ESP32 kiosk communication.

## Setup on Hostinger

1. **Upload files** to `public_html/api/` directory
2. **Edit `config.php`** with your credentials:
   - `FCM_SERVER_KEY` - Get from Firebase Console → Project Settings → Cloud Messaging
   - `FIREBASE_PROJECT_ID` - Your Firebase project ID
   - `API_SECRET_KEY` - Generate a random string for ESP32 authentication

## API Endpoints

### Notifications

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/notify/topic` | POST | Send push to all users |
| `/api/notify/user` | POST | Send push to specific user |

### Kiosk (ESP32)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/kiosk/{id}/status` | POST | Update kiosk status |
| `/api/kiosk/transaction` | POST | Submit recycling transaction |
| `/api/kiosk/{id}` | GET | Get kiosk info |

### User

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/user/{id}` | GET | Get user info |

## Authentication

ESP32 endpoints require `X-API-Key` header with your `API_SECRET_KEY`.

## Testing with Postman

1. Import `REward_API.postman_collection.json`
2. Set variables:
   - `baseUrl`: Your API URL (e.g., `https://yourdomain.com/api`)
   - `apiKey`: Your API secret key
   - `testUserId`: A user ID from Firestore
   - `testKioskId`: A kiosk ID from Firestore

## FCM Server Key

To get your FCM Server Key:
1. Firebase Console → Project Settings
2. Cloud Messaging tab
3. Copy "Server key" (NOT the Sender ID)

> **Note:** Firebase is deprecating the legacy API. For production, consider migrating to FCM v1 HTTP API.
