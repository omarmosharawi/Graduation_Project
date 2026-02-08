<?php
// =============================================================================
// Send Push Notification to Specific User
// =============================================================================
// POST /api/notify/user
// Body: { "userId": "abc123", "title": "Hello", "body": "Message" }
// OR: { "fcmToken": "device_token", "title": "Hello", "body": "Message" }
// =============================================================================

validateRequired($body, ['title', 'body']);

$title = $body['title'];
$message = $body['body'];
$data = $body['data'] ?? [];

$fcmToken = $body['fcmToken'] ?? null;
$userId = $body['userId'] ?? null;

// If userId provided, get FCM token from Firestore
if (!$fcmToken && $userId) {
    $user = getFirestoreDoc('users', $userId);
    if (!$user) {
        http_response_code(404);
        response(['error' => 'User not found']);
    }
    $fcmToken = $user['fcmToken'] ?? null;
}

if (!$fcmToken) {
    http_response_code(400);
    response(['error' => 'No FCM token available for this user']);
}

try {
    $result = sendToDevice($fcmToken, $title, $message, $data);

    if ($result['success']) {
        response([
            'success' => true,
            'message' => 'Notification sent to user',
            'fcmResponse' => $result['response']
        ]);
    } else {
        http_response_code(500);
        response([
            'success' => false,
            'error' => 'Failed to send notification',
            'fcmResponse' => $result['response']
        ]);
    }
} catch (Exception $e) {
    http_response_code(500);
    response(['error' => $e->getMessage()]);
}
