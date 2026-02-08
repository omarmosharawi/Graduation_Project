<?php
// =============================================================================
// Send OTP Email (Called by Mobile App)
// =============================================================================
// POST /api/send-otp-email
// Headers: X-API-Key: your-secret-key
// Body: {
//   "email": "user@example.com",
//   "otp": "123456"
// }
// =============================================================================

// Verify API key for authentication
verifyApiKey();

validateRequired($body, ['email', 'otp']);

$email = $body['email'];
$otp = $body['otp'];

// Email Subject
$subject = "Your REward App Verification Code";

// Email Body
$message = "
<html>
<head>
  <title>Your OTP Code</title>
</head>
<body>
  <h2>Verification Code</h2>
  <p>Your OTP code is: <strong>$otp</strong></p>
  <p>This code is valid for 30 seconds.</p>
  <p>If you did not request this code, please ignore this email.</p>
  <br>
  <p>The REward Team</p>
</body>
</html>
";

// Headers
$headers = "MIME-Version: 1.0" . "\r\n";
$headers .= "Content-type:text/html;charset=UTF-8" . "\r\n";
$headers .= "From: REward App <no-reply@" . $_SERVER['SERVER_NAME'] . ">" . "\r\n";

// Send Email
if(mail($email, $subject, $message, $headers)) {
    response(['success' => true, 'message' => 'OTP sent successfully']);
} else {
    http_response_code(500);
    response(['error' => 'Failed to send email. Check SMTP or server mail settings.']);
}
