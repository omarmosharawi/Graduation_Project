<?php
// =============================================================================
// REward API - Main Entry Point
// =============================================================================
// Upload this folder to your Hostinger public_html directory
// 
// API Base URL: https://yourdomain.com/api/
// =============================================================================

// Enable CORS for app access
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Load configuration
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/firebase.php';

// Get request path
$requestUri = $_SERVER['REQUEST_URI'];
$scriptName = $_SERVER['SCRIPT_NAME']; // /api/index.php
$dirName = dirname($scriptName); // /api

// Remove query string
$path = parse_url($requestUri, PHP_URL_PATH);

// Remove script name if present (for non-rewrite setups)
if (strpos($path, $scriptName) === 0) {
    $path = substr($path, strlen($scriptName));
}
// Remove directory name if present
elseif (strpos($path, $dirName) === 0) {
    $path = substr($path, strlen($dirName));
}

// Ensure leading slash
if (empty($path)) {
    $path = '/';
}
$path = '/' . ltrim($path, '/');

$method = $_SERVER['REQUEST_METHOD'];

// Get JSON body
$body = json_decode(file_get_contents('php://input'), true) ?? [];

// Simple router
try {
    switch (true) {
        // Health check
        case $path === '/' || $path === '':
            response(['status' => 'ok', 'message' => 'REward API v1.0']);
            break;

        // =================================================================
        // NOTIFICATION ENDPOINTS
        // =================================================================

        // Send push to topic (for announcements)
        case $path === '/notify/topic' && $method === 'POST':
            require_once __DIR__ . '/endpoints/notify_topic.php';
            break;

        // Send push to specific user
        case $path === '/notify/user' && $method === 'POST':
            require_once __DIR__ . '/endpoints/notify_user.php';
            break;

        // Send OTP via Email
        case $path === '/send-otp-email' && $method === 'POST':
            require_once __DIR__ . '/endpoints/send_otp_email.php';
            break;


        // =================================================================
        // KIOSK/MACHINE ENDPOINTS (for ESP32)
        // =================================================================

        // Update kiosk status
        case preg_match('/^\/kiosk\/([a-zA-Z0-9]+)\/status$/', $path, $matches) && $method === 'POST':
            $kioskId = $matches[1];
            require_once __DIR__ . '/endpoints/kiosk_status.php';
            break;

        // Submit recycling transaction
        case $path === '/kiosk/transaction' && $method === 'POST':
            require_once __DIR__ . '/endpoints/kiosk_transaction.php';
            break;

        // Get kiosk info
        case preg_match('/^\/kiosk\/([a-zA-Z0-9]+)$/', $path, $matches) && $method === 'GET':
            $kioskId = $matches[1];
            require_once __DIR__ . '/endpoints/kiosk_get.php';
            break;

        // =================================================================
        // USER ENDPOINTS
        // =================================================================

        // Get user by ID
        case preg_match('/^\/user\/([a-zA-Z0-9]+)$/', $path, $matches) && $method === 'GET':
            $userId = $matches[1];
            require_once __DIR__ . '/endpoints/user_get.php';
            break;

        // 404 Not Found
        default:
            http_response_code(404);
            response(['error' => 'Endpoint not found', 'path' => $path]);
    }
} catch (Exception $e) {
    http_response_code(500);
    response(['error' => $e->getMessage()]);
}

// Helper function to send JSON response
function response($data, $code = 200)
{
    http_response_code($code);
    echo json_encode($data, JSON_PRETTY_PRINT);
    exit();
}

// Helper to validate required fields
function validateRequired($body, $fields)
{
    $missing = [];
    foreach ($fields as $field) {
        if (!isset($body[$field]) || $body[$field] === '') {
            $missing[] = $field;
        }
    }
    if (!empty($missing)) {
        http_response_code(400);
        response(['error' => 'Missing required fields', 'fields' => $missing]);
    }
}
