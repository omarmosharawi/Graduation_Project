<?php
// =============================================================================
// Get User by Kiosk Code
// =============================================================================
// GET /api/user/by-code/{kioskCode}
// Headers: X-API-Key: your-secret-key
// Returns: { success: true, user: { id, name } }
// =============================================================================

// Verify API key (ESP32 must authenticate)
verifyApiKey();

try {
    // $kioskCode is set by the router in index.php
    if (empty($kioskCode) || strlen($kioskCode) !== 8) {
        http_response_code(400);
        response(['error' => 'Invalid kiosk code format']);
    }

    // Query Firestore for user with this kioskCode
    // Using Firestore REST API structured query
    $projectId = FIREBASE_PROJECT_ID;
    $url = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents:runQuery";

    $query = [
        'structuredQuery' => [
            'from' => [['collectionId' => 'users']],
            'where' => [
                'fieldFilter' => [
                    'field' => ['fieldPath' => 'kioskCode'],
                    'op' => 'EQUAL',
                    'value' => ['stringValue' => $kioskCode]
                ]
            ],
            'limit' => 1
        ]
    ];

    // Get access token for Firestore authentication
    $accessToken = getAccessToken();

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($query));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: Bearer ' . $accessToken
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($curlError) {
        http_response_code(500);
        response([
            'success' => false,
            'error' => 'Connection to Google failed. The server might be blocked or have DNS issues.',
            'curl_error' => $curlError
        ]);
    }

    if ($httpCode !== 200) {
        $details = json_decode($response, true);
        http_response_code(500);
        response([
            'success' => false,
            'error' => 'Firestore query failed',
            'httpCode' => $httpCode,
            'details' => $details
        ]);
    }

    $result = json_decode($response, true);

    // Check if any document was returned
    if (empty($result) || !isset($result[0]['document'])) {
        http_response_code(404);
        response(['error' => 'User not found. Ensure you type the 8-digit code shown in the app.', 'success' => false]);
    }

    $doc = $result[0]['document'];
    $fields = $doc['fields'] ?? [];

    // Extract document ID from the name path
    $nameParts = explode('/', $doc['name']);
    $userId = end($nameParts);

    response([
        'success' => true,
        'user' => [
            'id' => $userId,
            'name' => $fields['name']['stringValue'] ?? '',
        ]
    ]);
} catch (Exception $e) {
    http_response_code(500);
    response(['error' => $e->getMessage()]);
}
