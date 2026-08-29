<?php

echo "===================================================\n";
echo "      LuxeCart - Full System Endpoints Diagnostic\n";
echo "===================================================\n\n";

$tests = [
    ['Health Check', 'GET', '/api/health', null],
    ['CSRF Token', 'GET', '/api/csrf-token', null],
    ['Get Categories', 'GET', '/api/categories', null],
    ['Get Products (All)', 'GET', '/api/products', null],
    ['Filter Products (Apparel)', 'GET', '/api/products?category=Apparel', null],
    ['Search Products (Hoodie)', 'GET', '/api/products?search=hoodie', null],
    ['Get Product Detail (#1)', 'GET', '/api/products?id=1', null],
    ['Validate Coupon (LUXE20)', 'POST', '/api/coupons/validate', ['code' => 'LUXE20', 'subtotal' => 100.0]],
    ['Validate Coupon (SAVE10)', 'POST', '/api/coupons/validate', ['code' => 'SAVE10', 'subtotal' => 60.0]],
    ['Get Reviews for Product #1', 'GET', '/api/reviews?product_id=1', null],
];

$passCount = 0;
foreach ($tests as [$name, $method, $uri, $body]) {
    $script = __DIR__ . '/test_single_endpoint.php';
    $payloadArg = $body !== null ? base64_encode(json_encode($body)) : '';
    
    $cmd = sprintf('php "%s" "%s" "%s" "%s"', $script, $method, $uri, $payloadArg);
    $output = shell_exec($cmd);
    
    $json = json_decode($output ?: '', true);
    $isSuccess = is_array($json) && ($json['success'] ?? false) === true;

    if ($isSuccess) {
        $passCount++;
        echo "✅ [PASS] $name ($method $uri)\n";
    } else {
        echo "❌ [FAIL] $name ($method $uri)\n";
        echo "   Output: " . substr($output ?: 'No output', 0, 150) . "\n";
    }
}

echo "\n---------------------------------------------------\n";
echo "API Endpoints Summary: $passCount / " . count($tests) . " endpoints passed.\n";
echo "===================================================\n";

