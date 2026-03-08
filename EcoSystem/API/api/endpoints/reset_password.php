<?php
// =============================================================================
// Reset Password Endpoint (Admin Proxy)
// =============================================================================
// POST /api/reset-password
// Body: { "email": "user@example.com", "password": "newPassword" }
// =============================================================================

verifyApiKey();

validateRequired($body, ['email', 'password']);

$email = strtolower(trim($body['email']));
$newPassword = $body['password'];

try {
    $accessToken = getAccessToken();
    $projectId = FIREBASE_PROJECT_ID;

    // 1. Get UID from Email
    $lookupUrl = "https://identitytoolkit.googleapis.com/v1/accounts:lookup";

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $lookupUrl);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $accessToken,
        'Content-Type: application/json'
    ]);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['email' => [$email]]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

    $rawResult = curl_exec($ch);
    $curlError = curl_error($ch);
    $lookupResponse = json_decode($rawResult, true);
    $lookupHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if (empty($lookupResponse['users'])) {
        response([
            'error' => 'User not found',
            'details' => $lookupResponse['error']['message'] ?? 'No user record matching this email.',
            'raw_google_response' => $rawResult, // Raw body for debugging
            'curl_error' => $curlError,
            'debug_email' => $email,
            'http_code' => $lookupHttpCode
        ], 404);
    }

    $uid = $lookupResponse['users'][0]['localId'];

    // 2. Update Password
    // Use the project-agnostic update endpoint, similar to lookup
    $updateUrl = "https://identitytoolkit.googleapis.com/v1/accounts:update";

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $updateUrl);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $accessToken,
        'Content-Type: application/json'
    ]);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
        'localId' => $uid,
        'password' => $newPassword
    ]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

    $rawUpdateResult = curl_exec($ch);
    $updateResponse = json_decode($rawUpdateResult, true);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $updateCurlError = curl_error($ch);
    curl_close($ch);

    if ($httpCode === 200) {
        response(['success' => true, 'message' => 'Password updated successfully']);
    } else {
        response([
            'error' => 'Failed to update password',
            'details' => $updateResponse['error']['message'] ?? 'Unknown error',
            'raw_google_response' => $rawUpdateResult,
            'curl_error' => $updateCurlError,
            'uid' => $uid,
            'code' => $httpCode
        ], 500);
    }

} catch (Exception $e) {
    response(['error' => $e->getMessage()], 500);
}
