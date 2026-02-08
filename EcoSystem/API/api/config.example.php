<?php
// =============================================================================
// API Configuration - EXAMPLE FILE
// =============================================================================
// Copy this file to config.php and update with your actual credentials!
// DO NOT commit config.php to version control!
// =============================================================================

// Firebase Project ID
// Get from: Firebase Console → Project Settings → General
define('FIREBASE_PROJECT_ID', 'your-project-id');

// API Security Key (for authenticating ESP32 requests)
// Generate a random string: openssl rand -hex 32
define('API_SECRET_KEY', 'generate-a-secure-random-key-here');

// Points per item
define('POINTS_PER_PLASTIC', 10);
define('POINTS_PER_METAL', 10);

// Firestore REST API base URL (auto-generated from project ID)
define('FIRESTORE_BASE_URL', 'https://firestore.googleapis.com/v1/projects/' . FIREBASE_PROJECT_ID . '/databases/(default)/documents');

// =============================================================================
// NOTE: FCM v1 API uses service account (service-account.json file)
// 1. Download service-account.json from Firebase Console → Project Settings → Service Accounts
// 2. Place it in the 'api' folder (same directory as config.php)
// =============================================================================
