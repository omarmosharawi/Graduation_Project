<?php
// =============================================================================
// Submit Recycling Transaction (from ESP32)
// =============================================================================
// POST /api/kiosk/transaction
// Headers: X-API-Key: your-secret-key
// Body: {
//   "kioskId": "kiosk123",
//   "userId": "user123",
//   "plasticCount": 3,
//   "metalCount": 2
// }
// =============================================================================

// Verify API key for ESP32 authentication
verifyApiKey();

validateRequired($body, ['kioskId', 'userId', 'plasticCount', 'metalCount']);

$kioskId = $body['kioskId'];
$userId = $body['userId'];
$plasticCount = (int) $body['plasticCount'];
$metalCount = (int) $body['metalCount'];

// Calculate points
$totalItems = $plasticCount + $metalCount;
$points = ($plasticCount * POINTS_PER_PLASTIC) + ($metalCount * POINTS_PER_METAL);

if ($totalItems <= 0) {
    http_response_code(400);
    response(['error' => 'Must recycle at least one item']);
}

try {
    // Get user to verify exists and get FCM token
    $user = getFirestoreDoc('users', $userId);
    if (!$user) {
        http_response_code(404);
        response(['error' => 'User not found']);
    }

    // Create transaction record
    $transaction = [
        'kioskId' => $kioskId,
        'userId' => $userId,
        'plasticCount' => $plasticCount,
        'metalCount' => $metalCount,
        'points' => $points,
        'timestamp' => date('c')
    ];

    createFirestoreDoc('transactions', $transaction);

    // Update user points (note: this is a simplified version)
    // In production, use Firestore transactions for atomic updates
    $newPoints = ($user['currentPoints'] ?? 0) + $points;
    $newTotal = ($user['totalPoints'] ?? 0) + $points;
    $newRecycled = ($user['recycledCount'] ?? 0) + $totalItems;

    updateFirestoreDoc('users', $userId, [
        'currentPoints' => $newPoints,
        'totalPoints' => $newTotal,
        'recycledCount' => $newRecycled
    ]);

    // Create notification for user
    createFirestoreDoc("users/$userId/notifications", [
        'type' => 'points_earned',
        'title' => 'Points Earned!',
        'message' => "You earned $points points for recycling $totalItems items.",
        'timestamp' => date('c'),
        'isRead' => false
    ]);

    // Update kiosk counts
    $kiosk = getFirestoreDoc('kiosks', $kioskId);
    if ($kiosk) {
        updateFirestoreDoc('kiosks', $kioskId, [
            'plasticCount' => ($kiosk['plasticCount'] ?? 0) + $plasticCount,
            'metalCount' => ($kiosk['metalCount'] ?? 0) + $metalCount,
            'lastUpdated' => date('c')
        ]);
    }

    // Send push notification to user
    $fcmToken = $user['fcmToken'] ?? null;
    $pushResult = null;
    if ($fcmToken) {
        $pushResult = sendToDevice(
            $fcmToken,
            'Points Earned! 🎉',
            "You earned $points points for recycling $totalItems items!",
            ['type' => 'points_earned', 'points' => (string) $points]
        );
    }

    response([
        'success' => true,
        'transaction' => [
            'userId' => $userId,
            'kioskId' => $kioskId,
            'plasticCount' => $plasticCount,
            'metalCount' => $metalCount,
            'totalItems' => $totalItems,
            'pointsEarned' => $points,
            'newBalance' => $newPoints
        ],
        'pushNotification' => $pushResult ? $pushResult['success'] : false
    ]);

} catch (Exception $e) {
    http_response_code(500);
    response(['error' => $e->getMessage()]);
}
