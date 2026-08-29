<?php

namespace App\Helpers;

class Response {
    public static function json(mixed $data, int $statusCode = 200, array $meta = []): void {
        if (!headers_sent()) {
            http_response_code($statusCode);
            header('Content-Type: application/json; charset=UTF-8');
        }

        $payload = [
            'success' => $statusCode >= 200 && $statusCode < 300,
            'status' => $statusCode,
            'data' => $data,
        ];

        if (!empty($meta)) {
            $payload['meta'] = $meta;
        }

        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit();
    }

    public static function error(string $message, int $statusCode = 400, mixed $errors = null): void {
        if (!headers_sent()) {
            http_response_code($statusCode);
            header('Content-Type: application/json; charset=UTF-8');
        }

        $payload = [
            'success' => false,
            'status' => $statusCode,
            'error' => [
                'message' => $message,
            ],
        ];

        if ($errors !== null) {
            $payload['error']['details'] = $errors;
        }

        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit();
    }

    public static function getJsonInput(): array {
        if (!empty($GLOBALS['MOCK_PHP_INPUT'])) {
            $decoded = json_decode($GLOBALS['MOCK_PHP_INPUT'], true);
            return is_array($decoded) ? $decoded : [];
        }

        $raw = file_get_contents('php://input');
        if (empty($raw)) {
            return [];
        }

        $decoded = json_decode($raw, true);
        return is_array($decoded) ? $decoded : [];
    }
}
