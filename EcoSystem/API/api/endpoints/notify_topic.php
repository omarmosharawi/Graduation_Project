<?php
// =============================================================================
// Send Push Notification to Topic
// =============================================================================
// POST /api/notify/topic
// Body: { "topic": "all_users", "title": "Hello", "body": "Message" }
// =============================================================================

validateRequired($body, ['topic', 'title', 'body']);

$topic = $body['topic'];
$title = $body['title'];
$message = $body['body'];
$data = $body['data'] ?? [];

try {
    $result = sendToTopic($topic, $title, $message, $data);

    if ($result['success']) {
        response([
            'success' => true,
            'message' => "Notification sent to topic: $topic",
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
