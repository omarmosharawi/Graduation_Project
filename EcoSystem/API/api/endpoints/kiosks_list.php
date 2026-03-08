<?php
// =============================================================================
// List All Kiosks
// =============================================================================
// GET /api/kiosks
// =============================================================================

try {
    $kiosks = getFirestoreCollection('kiosks');

    $formattedKiosks = [];
    foreach ($kiosks as $kiosk) {
        $formattedKiosks[] = [
            'id' => $kiosk['id'],
            'name' => $kiosk['name'] ?? '',
            'address' => $kiosk['address'] ?? '',
            'latitude' => $kiosk['latitude'] ?? 0.0,
            'longitude' => $kiosk['longitude'] ?? 0.0,
            'status' => $kiosk['status'] ?? 'offline',
            'plasticCount' => $kiosk['plasticCount'] ?? 0,
            'metalCount' => $kiosk['metalCount'] ?? 0,
            'currentCapacity' => $kiosk['currentCapacity'] ?? 0,
            'maxCapacity' => $kiosk['maxCapacity'] ?? 100,
            'lastUpdated' => $kiosk['lastUpdated'] ?? null
        ];
    }

    response([
        'success' => true,
        'count' => count($formattedKiosks),
        'kiosks' => $formattedKiosks
    ]);
} catch (Exception $e) {
    http_response_code(500);
    response(['error' => $e->getMessage()]);
}
