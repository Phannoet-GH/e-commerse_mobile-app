<?php

namespace App\Security;

class SecurityHeaders {
    public static function apply(): void {
        if (headers_sent()) return;

        // Prevent MIME type sniffing
        header('X-Content-Type-Options: nosniff');

        // Protect against Clickjacking attacks
        header('X-Frame-Options: DENY');

        // Enable browser XSS filtering
        header('X-XSS-Protection: 1; mode=block');

        // Control referrer information
        header('Referrer-Policy: strict-origin-when-cross-origin');

        // Restrict browser features
        header('Permissions-Policy: geolocation=(), camera=(), microphone=()');

        // Content Security Policy for API
        header("Content-Security-Policy: default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'self';");
    }
}
