<?php
// =============================================================================
// Firebase Helper Functions - FCM v1 API
// =============================================================================
// Uses the new FCM v1 HTTP API with OAuth2 authentication
// =============================================================================

/**
 * Get OAuth2 access token from service account
 */
function getAccessToken()
{
    $serviceAccount = json_decode(file_get_contents(__DIR__ . '/service-account.json'), true);

    if (!$serviceAccount) {
        throw new Exception('Service account file not found. Download from Firebase Console.');
    }

    // Create JWT
    $now = time();
    $header = base64_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
    $payload = base64_encode(json_encode([
        'iss' => $serviceAccount['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/identitytoolkit https://www.googleapis.com/auth/cloud-platform',
        'aud' => 'https://oauth2.googleapis.com/token',
        'iat' => $now,
        'exp' => $now + 3600
    ]));

    // Sign with private key
    $privateKey = openssl_pkey_get_private($serviceAccount['private_key']);
    openssl_sign("$header.$payload", $signature, $privateKey, OPENSSL_ALGO_SHA256);
    $jwt = "$header.$payload." . base64_encode($signature);

    // Exchange JWT for access token
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

    $response = json_decode(curl_exec($ch), true);
    curl_close($ch);

    if (isset($response['access_token'])) {
        return $response['access_token'];
    }

    throw new Exception('Failed to get access token: ' . json_encode($response));
}

/**
 * Send FCM v1 push notification
 */
function sendFCMv1($message)
{
    $accessToken = getAccessToken();
    $projectId = FIREBASE_PROJECT_ID;

    $url = "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";

    $headers = [
        'Authorization: Bearer ' . $accessToken,
        'Content-Type: application/json'
    ];

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['message' => $message]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);

    if ($error) {
        throw new Exception("FCM Error: $error");
    }

    return [
        'success' => $httpCode === 200,
        'response' => json_decode($response, true),
        'httpCode' => $httpCode
    ];
}

/**
 * Send push to a topic (FCM v1)
 */
function sendToTopic($topic, $title, $body, $data = [])
{
    $message = [
        'topic' => $topic,
        'notification' => [
            'title' => $title,
            'body' => $body
        ],
        'android' => [
            'priority' => 'high',
            'notification' => [
                'sound' => 'default',
                'channel_id' => 'reward_notifications'
            ]
        ],
        'apns' => [
            'payload' => [
                'aps' => [
                    'sound' => 'default'
                ]
            ]
        ]
    ];

    if (!empty($data)) {
        $message['data'] = array_map('strval', $data);
    }

    return sendFCMv1($message);
}

/**
 * Send push to a specific device token (FCM v1)
 */
function sendToDevice($fcmToken, $title, $body, $data = [])
{
    $message = [
        'token' => $fcmToken,
        'notification' => [
            'title' => $title,
            'body' => $body
        ],
        'android' => [
            'priority' => 'high',
            'notification' => [
                'sound' => 'default',
                'channel_id' => 'reward_notifications'
            ]
        ],
        'apns' => [
            'payload' => [
                'aps' => [
                    'sound' => 'default'
                ]
            ]
        ]
    ];

    if (!empty($data)) {
        $message['data'] = array_map('strval', $data);
    }

    return sendFCMv1($message);
}

/**
 * Get Firestore document
 */
function getFirestoreDoc($collection, $docId)
{
    $url = FIRESTORE_BASE_URL . "/$collection/$docId";
    $accessToken = getAccessToken();

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Authorization: Bearer ' . $accessToken]);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode !== 200) {
        return null;
    }

    return parseFirestoreDoc(json_decode($response, true));
}

/**
 * Get all documents in a Firestore collection
 */
function getFirestoreCollection($collection)
{
    $url = FIRESTORE_BASE_URL . "/$collection";
    $accessToken = getAccessToken();

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Authorization: Bearer ' . $accessToken]);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode !== 200) {
        return [];
    }

    $data = json_decode($response, true);
    $documents = [];

    if (isset($data['documents'])) {
        foreach ($data['documents'] as $doc) {
            $parsed = parseFirestoreDoc($doc);
            if ($parsed) {
                // Extract ID from name (e.g., "projects/id/databases/(default)/documents/collection/docId")
                $nameParts = explode('/', $doc['name']);
                $parsed['id'] = end($nameParts);
                $documents[] = $parsed;
            }
        }
    }

    return $documents;
}

/**
 * Update Firestore document
 */
function updateFirestoreDoc($collection, $docId, $fields)
{
    $url = FIRESTORE_BASE_URL . "/$collection/$docId";
    $accessToken = getAccessToken();

    // Convert to Firestore format
    $firestoreFields = [];
    foreach ($fields as $key => $value) {
        $firestoreFields[$key] = formatFirestoreValue($value);
    }

    $payload = ['fields' => $firestoreFields];

    // Build update mask
    $updateMask = implode('&', array_map(function ($k) {
        return "updateMask.fieldPaths=$k";
    }, array_keys($fields)));
    $url .= "?$updateMask";

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PATCH');
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: Bearer ' . $accessToken
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return $httpCode === 200;
}

/**
 * Create Firestore document
 */
function createFirestoreDoc($collection, $fields, $docId = null)
{
    $url = FIRESTORE_BASE_URL . "/$collection";
    $accessToken = getAccessToken();

    if ($docId) {
        $url .= "?documentId=$docId";
    }

    // Convert to Firestore format
    $firestoreFields = [];
    foreach ($fields as $key => $value) {
        $firestoreFields[$key] = formatFirestoreValue($value);
    }

    $payload = ['fields' => $firestoreFields];

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: Bearer ' . $accessToken
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return $httpCode === 200;
}

function formatFirestoreValue($value)
{
    if (is_array($value) && isset($value['__firestore_timestamp'])) {
        return ['timestampValue' => $value['__firestore_timestamp']];
    }

    if (is_string($value)) {
        return ['stringValue' => $value];
    } elseif (is_int($value)) {
        return ['integerValue' => (string) $value];
    } elseif (is_float($value)) {
        return ['doubleValue' => $value];
    } elseif (is_bool($value)) {
        return ['booleanValue' => $value];
    } elseif (is_null($value)) {
        return ['nullValue' => null];
    } elseif (is_array($value)) {
        return ['arrayValue' => ['values' => array_map('formatFirestoreValue', $value)]];
    }
    return ['stringValue' => (string) $value];
}
/**
 * Parse Firestore document to regular PHP array
 */
function parseFirestoreDoc($doc)
{
    if (!isset($doc['fields']))
        return null;

    $result = [];
    foreach ($doc['fields'] as $key => $value) {
        $result[$key] = parseFirestoreValue($value);
    }
    return $result;
}

/**
 * Parse Firestore value to PHP value
 */
function parseFirestoreValue($value)
{
    if (isset($value['stringValue']))
        return $value['stringValue'];
    if (isset($value['integerValue']))
        return (int) $value['integerValue'];
    if (isset($value['doubleValue']))
        return (float) $value['doubleValue'];
    if (isset($value['booleanValue']))
        return $value['booleanValue'];
    if (isset($value['nullValue']))
        return null;
    if (isset($value['timestampValue']))
        return $value['timestampValue'];
    if (isset($value['arrayValue'])) {
        return array_map('parseFirestoreValue', $value['arrayValue']['values'] ?? []);
    }
    return null;
}

/**
 * Verify API key for ESP32 requests
 */
function verifyApiKey()
{
    $headers = getallheaders();
    $apiKey = $headers['X-API-Key'] ?? $headers['x-api-key'] ?? null;

    if ($apiKey !== API_SECRET_KEY) {
        http_response_code(401);
        response(['error' => 'Invalid API key']);
    }
}
