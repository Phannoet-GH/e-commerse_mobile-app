<?php

namespace App\Security;

class Csrf {
    private const SESSION_KEY = 'csrf_token';
    private const SECRET_KEY = 'luxecart_ecommerce_csrf_secret_salt';

    /**
     * Generate a cryptographically secure CSRF token
     */
    public static function generateToken(?string $userId = null): string {
        $salt = bin2hex(random_bytes(16));
        $timestamp = time();
        $identity = $userId ?: 'guest_session';
        $payload = "$identity|$timestamp|$salt";
        $signature = hash_hmac('sha256', $payload, self::SECRET_KEY);

        return base64_encode("$payload|$signature");
    }

    /**
     * Validate a given CSRF token against identity and signature
     * Checks HMAC signature, expiration (valid for 24 hours), and uses hash_equals to prevent timing attacks.
     */
    public static function validateToken(?string $token, ?string $userId = null, int $maxAgeSeconds = 86400): bool {
        if (empty($token)) {
            return false;
        }

        $decoded = base64_decode($token, true);
        if (!$decoded) {
            return false;
        }

        $parts = explode('|', $decoded);
        if (count($parts) !== 4) {
            return false;
        }

        [$identity, $timestamp, $salt, $providedSignature] = $parts;

        // 1. Verify timestamp expiration
        $tokenTime = (int)$timestamp;
        if ((time() - $tokenTime) > $maxAgeSeconds) {
            return false; // Token expired
        }

        // 2. Verify identity match if provided
        if ($userId !== null && $identity !== $userId && $identity !== 'guest_session') {
            return false;
        }

        // 3. Verify HMAC signature using timing-safe hash_equals
        $payload = "$identity|$timestamp|$salt";
        $expectedSignature = hash_hmac('sha256', $payload, self::SECRET_KEY);

        return hash_equals($expectedSignature, $providedSignature);
    }

    /**
     * Extract CSRF token from HTTP headers or request payload
     */
    public static function extractTokenFromRequest(): ?string {
        // 1. Check HTTP header X-CSRF-Token or X-XSRF-Token
        $headers = getallheaders() ?: [];
        foreach ($headers as $key => $val) {
            if (strtolower($key) === 'x-csrf-token' || strtolower($key) === 'x-xsrf-token') {
                return $val;
            }
        }

        // 2. Check $_SERVER['HTTP_X_CSRF_TOKEN']
        if (!empty($_SERVER['HTTP_X_CSRF_TOKEN'])) {
            return $_SERVER['HTTP_X_CSRF_TOKEN'];
        }

        return null;
    }
}

