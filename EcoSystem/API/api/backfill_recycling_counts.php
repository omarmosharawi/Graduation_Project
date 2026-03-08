<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/firebase.php';

echo "Recalculating recycling stats for all users...\n";

// 1. Fetch all transactions from root collection
$url = FIRESTORE_BASE_URL . "/transactions";
$accessToken = getAccessToken();

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Authorization: Bearer ' . $accessToken]);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

$response = curl_exec($ch);
curl_close($ch);

$data = json_decode($response, true);

if (!isset($data['documents'])) {
    die("No transactions found to migrate.\n");
}

$userStats = [];

// 2. Aggregate counts per user
foreach ($data['documents'] as $doc) {
    if (!isset($doc['fields']))
        continue;

    $fields = $doc['fields'];
    $userId = $fields['userId']['stringValue'] ?? null;

    if (!$userId)
        continue;

    $plastic = (int) ($fields['plasticCount']['integerValue'] ?? 0);
    $metal = (int) ($fields['metalCount']['integerValue'] ?? 0);

    if (!isset($userStats[$userId])) {
        $userStats[$userId] = ['plastic' => 0, 'metal' => 0];
    }

    $userStats[$userId]['plastic'] += $plastic;
    $userStats[$userId]['metal'] += $metal;
}

// 3. Update each user in Firestore
foreach ($userStats as $userId => $stats) {
    echo "Updating User: $userId | Plastic: {$stats['plastic']} | Metal: {$stats['metal']}\n";

    $success = updateFirestoreDoc('users', $userId, [
        'totalPlastic' => $stats['plastic'],
        'totalMetal' => $stats['metal']
    ]);

    echo $success ? " - OK\n" : " - FAILED\n";
}

echo "Migration complete.\n";
