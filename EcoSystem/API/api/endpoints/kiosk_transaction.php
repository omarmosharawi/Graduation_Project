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
        response(['error' => 'User not found in Firestore']);
    }

    // Calculate points
    $newPoints = ($user['currentPoints'] ?? 0) + $points;
    $newTotal = ($user['totalPoints'] ?? 0) + $points;
    $newRecycled = ($user['recycledCount'] ?? 0) + $totalItems;

    // Calculate new rank (tier)
    $newRank = 'Bronze';
    if ($newTotal >= 10000) {
        $newRank = 'Diamond';
    } elseif ($newTotal >= 5000) {
        $newRank = 'Platinum';
    } elseif ($newTotal >= 2000) {
        $newRank = 'Gold';
    } elseif ($newTotal >= 500) {
        $newRank = 'Silver';
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

    if (!createFirestoreDoc('transactions', $transaction)) {
        throw new Exception('Failed to create transaction record');
    }

    // Update user points and rank
    if (
        !updateFirestoreDoc('users', $userId, [
            'currentPoints' => $newPoints,
            'totalPoints' => $newTotal,
            'recycledCount' => $newRecycled,
            'totalPlastic' => ($user['totalPlastic'] ?? 0) + $plasticCount,
            'totalMetal' => ($user['totalMetal'] ?? 0) + $metalCount,
            'rank' => $newRank
        ])
    ) {
        throw new Exception('Failed to update user points');
    }

    // Add points history entry in subcollection (matches Flutter addPoints history)
    createFirestoreDoc("users/$userId/pointsHistory", [
        'points' => $points,
        'type' => 'earned',
        'description' => "Recycled $totalItems items at Kiosk: $kioskId",
        'timestamp' => ['__firestore_timestamp' => gmdate('Y-m-d\TH:i:s\Z')]
    ]);

    // Create notification in subcollection
    $notificationTime = gmdate('Y-m-d\TH:i:s\Z');
    createFirestoreDoc("users/$userId/notifications", [
        'type' => 'points_earned',
        'title' => 'Points Earned!',
        'message' => "You earned $points points for recycling $totalItems items.",
        'timestamp' => ['__firestore_timestamp' => $notificationTime],
        'isRead' => false
    ]);

    // Update kiosk counts and capacity
    $kiosk = getFirestoreDoc('kiosks', $kioskId);
    if ($kiosk) {
        $newPlastic = ($kiosk['plasticCount'] ?? 0) + $plasticCount;
        $newMetal = ($kiosk['metalCount'] ?? 0) + $metalCount;
        $newCapacity = ($kiosk['currentCapacity'] ?? 0) + $totalItems;
        $maxCapacity = ($kiosk['maxCapacity'] ?? 100);

        $kioskUpdates = [
            'plasticCount' => $newPlastic,
            'metalCount' => $newMetal,
            'currentCapacity' => $newCapacity,
            'lastUpdated' => date('c')
        ];

        // Auto-set status to full if capacity reached
        if ($newCapacity >= $maxCapacity) {
            $kioskUpdates['status'] = 'full';
        }

        updateFirestoreDoc('kiosks', $kioskId, $kioskUpdates);
    }

    // Update global statistics
    $globalStats = getFirestoreDoc('statistics', 'global');
    $addedWeight = ($plasticCount * WEIGHT_PER_PLASTIC) + ($metalCount * WEIGHT_PER_METAL);

    if (!$globalStats) {
        // Initialize if missing
        createFirestoreDoc('statistics', [
            'totalBottles' => $plasticCount,
            'totalCans' => $metalCount,
            'totalWeightKg' => $addedWeight,
            'lastUpdated' => date('c')
        ], 'global');
    } else {
        updateFirestoreDoc('statistics', 'global', [
            'totalBottles' => ($globalStats['totalBottles'] ?? 0) + $plasticCount,
            'totalCans' => ($globalStats['totalCans'] ?? 0) + $metalCount,
            'totalWeightKg' => ($globalStats['totalWeightKg'] ?? 0) + $addedWeight,
            'lastUpdated' => date('c')
        ]);
    }

    // Send push notification to user
    $fcmToken = $user['fcmToken'] ?? null;
    $pushResult = null;
    if ($fcmToken) {
        try {
            $pushResult = sendToDevice(
                $fcmToken,
                'Points Earned! 🎉',
                "You earned $points points for recycling $totalItems items!",
                [
                    'type' => 'points_earned',
                    'points' => (string) $points,
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
                ]
            );
        } catch (Exception $e) {
            $pushResult = ['success' => false, 'error' => $e->getMessage()];
        }
    } else {
        $pushResult = ['success' => false, 'error' => 'No FCM token found for user'];
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
        'pushNotification' => $pushResult
    ]);

} catch (Exception $e) {
    http_response_code(500);
    response([
        'error' => $e->getMessage(),
        'userId' => $userId,
        'kioskId' => $kioskId
    ]);
}
