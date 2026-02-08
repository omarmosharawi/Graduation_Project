<?php
// =============================================================================
// Get User Information
// =============================================================================
// GET /api/user/{userId}
// =============================================================================

try {
    $user = getFirestoreDoc('users', $userId);

    if (!$user) {
        http_response_code(404);
        response(['error' => 'User not found']);
    }

    // Don't expose sensitive data
    response([
        'success' => true,
        'user' => [
            'id' => $userId,
            'name' => $user['name'] ?? '',
            'currentPoints' => $user['currentPoints'] ?? 0,
            'totalPoints' => $user['totalPoints'] ?? 0,
            'recycledCount' => $user['recycledCount'] ?? 0,
            'rank' => $user['rank'] ?? 'Bronze',
            'hasFcmToken' => !empty($user['fcmToken'])
        ]
    ]);
} catch (Exception $e) {
    http_response_code(500);
    response(['error' => $e->getMessage()]);
}
