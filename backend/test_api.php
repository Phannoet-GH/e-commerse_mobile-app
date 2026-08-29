<?php
// Quick CLI test for PHP API endpoints
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['REQUEST_URI'] = '/api/products?category=Apparel';

ob_start();
require __DIR__ . '/index.php';
$output = ob_get_clean();

echo "Response:\n$output\n";

