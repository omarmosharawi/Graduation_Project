<?php
// =============================================================================
// Update Kiosk Status (from ESP32)
// =============================================================================
// POST /api/kiosk/{kioskId}/status
// Headers: X-API-Key: your-secret-key
// Body: { "status": "available" | "maintenance" | "offline" }
// =============================================================================

// Verify API key for ESP32 authentication
verifyApiKey();

validateRequired($body, ['status']);

$status = $body['status'];
$validStatuses = ['available', 'maintenance', 'offline'];

if (!in_array($status, $validStatuses)) {
    http_response_code(400);
    response([
        'error' => 'Invalid status',
        'validStatuses' => $validStatuses
    ]);
}

try {
    $success = updateFirestoreDoc('kiosks', $kioskId, [
        'status' => $status,
        'lastUpdated' => date('c') // ISO 8601 format
    ]);

    if ($success) {
        response([
            'success' => true,
            'kioskId' => $kioskId,
            'status' => $status,
            'updatedAt' => date('c')
        ]);
    } else {
        http_response_code(500);
        response(['error' => 'Failed to update kiosk status']);
    }
} catch (Exception $e) {
    http_response_code(500);
    response(['error' => $e->getMessage()]);
}
