<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/firebase.php';

echo "Recalculating Global Recycling Statistics...\n";

// 1. Fetch all transactions from root collection
$accessToken = getAccessToken();
$url = FIRESTORE_BASE_URL . "/transactions?pageSize=1000";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Authorization: Bearer ' . $accessToken]);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($httpCode !== 200) {
    die("Failed to fetch transactions. HTTP Code: $httpCode\nResponse: $response\n");
}

$data = json_decode($response, true);

if (!isset($data['documents']) || empty($data['documents'])) {
    die("No transactions found to aggregate.\n");
}

$totalBottles = 0;
$totalCans = 0;
$totalWeightKg = 0.0;

// 2. Aggregate counts from all transactions
foreach ($data['documents'] as $doc) {
    if (!isset($doc['fields']))
        continue;

    $fields = $doc['fields'];
    $plastic = (int) ($fields['plasticCount']['integerValue'] ?? 0);
    $metal = (int) ($fields['metalCount']['integerValue'] ?? 0);

    $totalBottles += $plastic;
    $totalCans += $metal;
    $totalWeightKg += ($plastic * WEIGHT_PER_PLASTIC) + ($metal * WEIGHT_PER_METAL);
}

echo "Aggregation Complete:\n";
echo " - Total Bottles: $totalBottles\n";
echo " - Total Cans: $totalCans\n";
echo " - Total Weight: " . number_format($totalWeightKg, 3) . " kg\n";

// 3. Update statistics/global in Firestore
$success = updateFirestoreDoc('statistics', 'global', [
    'totalBottles' => $totalBottles,
    'totalCans' => $totalCans,
    'totalWeightKg' => $totalWeightKg,
    'lastUpdated' => date('c')
]);

if ($success) {
    echo "Successfully updated statistics/global.\n";
} else {
    // If update fails, try creating (in case document doesn't exist)
    $createSuccess = createFirestoreDoc('statistics', [
        'totalBottles' => $totalBottles,
        'totalCans' => $totalCans,
        'totalWeightKg' => $totalWeightKg,
        'lastUpdated' => date('c')
    ], 'global');
    echo $createSuccess ? "Successfully created statistics/global.\n" : "FAILED to update statistics/global.\n";
}

echo "Global stats migration finished.\n";
