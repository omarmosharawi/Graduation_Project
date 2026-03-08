<?php
require_once __DIR__ . '/config.php';

$email = $argv[1] ?? '';
if (!$email)
    die("Usage: php verify_user.php email@example.com\n");

$apiKey = 'AIzaSyCYxBmm6AtRgwDPFT4j0qtkMJ10Rl50TRc';
$url = "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$apiKey";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['email' => [$email]]));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

$response = curl_exec($ch);
echo "Response: " . $response . "\n";
curl_close($ch);
