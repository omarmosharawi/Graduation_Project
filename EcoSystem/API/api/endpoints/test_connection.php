<?php
// =============================================================================
// Connection Test Endpoint
// =============================================================================
// GET /api/test-connection
// =============================================================================

require_once __DIR__ . '/../config.php';

$results = [
    'timestamp' => date('Y-m-d H:i:s'),
    'server_ip' => $_SERVER['SERVER_ADDR'] ?? 'unknown',
    'tests' => []
];

// Test 1: DNS Resolution for firestore.googleapis.com
$host = 'firestore.googleapis.com';
$ip = gethostbyname($host);
$results['tests']['dns_resolution'] = [
    'host' => $host,
    'resolved_ip' => $ip,
    'success' => ($ip !== $host)
];

// Test 2: cURL Connection to Google
$ch = curl_init('https://www.google.com');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

$results['tests']['google_connectivity'] = [
    'url' => 'https://www.google.com',
    'http_code' => $httpCode,
    'curl_error' => $curlError,
    'success' => ($httpCode >= 200 && $httpCode < 400)
];

// Test 3: cURL Connection to Firestore API
$ch = curl_init('https://firestore.googleapis.com/v1/projects/' . FIREBASE_PROJECT_ID);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

$results['tests']['firestore_connectivity'] = [
    'url' => 'https://firestore.googleapis.com',
    'http_code' => $httpCode,
    'curl_error' => $curlError,
    'success' => ($httpCode > 0) // We expect 401 or 403 because no token, but > 0 means reached
];

header('Content-Type: application/json');
echo json_encode($results, JSON_PRETTY_PRINT);
exit();
