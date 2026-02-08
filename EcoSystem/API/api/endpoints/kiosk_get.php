<?php
// =============================================================================
// Get Kiosk Information
// =============================================================================
// GET /api/kiosk/{kioskId}
// =============================================================================

try {
    $kiosk = getFirestoreDoc('kiosks', $kioskId);

    if (!$kiosk) {
        http_response_code(404);
        response(['error' => 'Kiosk not found']);
    }

    response([
        'success' => true,
        'kiosk' => [
            'id' => $kioskId,
            'name' => $kiosk['name'] ?? '',
            'address' => $kiosk['address'] ?? '',
            'status' => $kiosk['status'] ?? 'offline',
            'plasticCount' => $kiosk['plasticCount'] ?? 0,
            'metalCount' => $kiosk['metalCount'] ?? 0,
            'lastUpdated' => $kiosk['lastUpdated'] ?? null
        ]
    ]);
} catch (Exception $e) {
    http_response_code(500);
    response(['error' => $e->getMessage()]);
}
