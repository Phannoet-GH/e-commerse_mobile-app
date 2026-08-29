<?php

$method = $argv[1] ?? 'GET';
$uri = $argv[2] ?? '/api/health';
$base64Body = $argv[3] ?? '';

$_SERVER['REQUEST_METHOD'] = $method;
$_SERVER['REQUEST_URI'] = $uri;

$parts = parse_url($uri);
if (!empty($parts['query'])) {
    parse_str($parts['query'], $_GET);
}

if (!empty($base64Body)) {
    $rawJson = base64_decode($base64Body);
    // Overwrite php://input simulation in getJsonInput()
    $GLOBALS['MOCK_PHP_INPUT'] = $rawJson;
}

require __DIR__ . '/index.php';

