<?php
// =============================================================================
// Debug User Endpoint
// =============================================================================
// GET /api/debug-user.php?userId=XYZ
// =============================================================================

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/firebase.php';

header('Content-Type: application/json');

$userId = $_GET['userId'] ?? null;

if (!$userId) {
    echo json_encode(['error' => 'Missing userId parameter']);
    exit;
}

try {
    echo json_encode([
        'message' => 'Fetching user...',
        'userId' => $userId,
        // Raw Firestore fetch (bypassing helper if needed to see raw response)
        'raw_check' => getFirestoreDoc('users', $userId)
    ], JSON_PRETTY_PRINT);

} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
