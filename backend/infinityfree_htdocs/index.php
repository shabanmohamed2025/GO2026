<?php
// =========================================================================
// ملف الربط الخاص بـ shabango.com (InfinityFree) مع سيرفر المشروع Node.js
// الحساب: if0_42482237
// =========================================================================

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

$backendTarget = "https://angry-candles-try.loca.lt"; 

$requestUri = $_SERVER['REQUEST_URI'];
$targetUrl = rtrim($backendTarget, '/') . $requestUri;

$ch = curl_init($targetUrl);

$headers = array();
if (function_exists('getallheaders')) {
    foreach (getallheaders() as $key => $value) {
        if (strtolower($key) !== 'host') {
            $headers[] = "$key: $value";
        }
    }
}
$headers[] = "Bypass-Tunnel-Remainder: true";
$headers[] = "User-Agent: FlutterApp";

curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $_SERVER['REQUEST_METHOD']);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

if ($_SERVER['REQUEST_METHOD'] === 'POST' || $_SERVER['REQUEST_METHOD'] === 'PUT') {
    $postData = file_get_contents('php://input');
    curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
}

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

if (curl_errno($ch)) {
    http_response_code(500);
    echo json_encode(["error" => "Failed to connect to backend", "details" => curl_error($ch)]);
} else {
    http_response_code($httpCode ?: 200);
    header("Content-Type: application/json");
    echo $response;
}
curl_close($ch);
?>
