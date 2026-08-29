<?php

namespace App\Models;

use App\Config\Database;
use PDO;

class User {
    public static function findByEmail(string $email): ?array {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT * FROM users WHERE LOWER(email) = LOWER(:email) LIMIT 1");
        $stmt->execute([':email' => trim($email)]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    public static function register(string $name, string $email, string $password, ?string $phone = null): array {
        $email = trim($email);
        $name = trim($name);
        $password = (string)$password;

        // 1. Empty Field Check
        if (empty($email) || empty($password)) {
            throw new \Exception("Email and password cannot be empty.");
        }

        // 2. Email Validation (@ symbol and valid domain structure)
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new \Exception("Please provide a valid email address (e.g., user@domain.com).");
        }

        // 3. Password Validation (At least 8 characters)
        if (strlen($password) < 8) {
            throw new \Exception("Password must be at least 8 characters long.");
        }

        // 4. Check Existing User
        $existing = self::findByEmail($email);
        if ($existing) {
            throw new \Exception("Email is already in use.");
        }

        if (empty($name)) {
            $name = explode('@', $email)[0];
        }

        $pdo = Database::getConnection();
        $id = 'usr_' . time() . '_' . bin2hex(random_bytes(4));
        
        // 5. Hash Password using Bcrypt
        $hash = password_hash($password, PASSWORD_BCRYPT);

        // 6. Save to Database
        $stmt = $pdo->prepare("
            INSERT INTO users (id, name, email, password_hash, phone, role)
            VALUES (:id, :name, :email, :hash, :phone, 'customer')
        ");

        $stmt->execute([
            ':id' => $id,
            ':name' => $name,
            ':email' => $email,
            ':hash' => $hash,
            ':phone' => $phone ? trim($phone) : null,
        ]);

        // 7. Token Generation & Response
        return [
            'id' => $id,
            'name' => $name,
            'email' => $email,
            'phone' => $phone ? trim($phone) : '+1 (555) 234-5678',
            'role' => 'customer',
            'token' => 'jwt_' . bin2hex(random_bytes(24)),
        ];
    }

    public static function login(string $email, string $password): array {
        $email = trim($email);
        $password = (string)$password;

        // 1. Empty Field Check
        if (empty($email) || empty($password)) {
            throw new \Exception("Email and password cannot be empty.");
        }

        // 2. Query Database for existing user
        $user = self::findByEmail($email);
        if (!$user) {
            throw new \Exception("Invalid email or password.");
        }

        // 3. Verify Password using bcrypt (password_verify)
        if (!password_verify($password, $user['password_hash'])) {
            throw new \Exception("Invalid email or password.");
        }

        // 4. Session / Token Generation & Response
        return [
            'id' => $user['id'],
            'name' => $user['name'],
            'email' => $user['email'],
            'phone' => $user['phone'] ?? '+1 (555) 234-5678',
            'role' => $user['role'] ?? 'customer',
            'token' => 'jwt_' . bin2hex(random_bytes(24)),
        ];
    }

    public static function requestPasswordResetOTP(string $email): array {
        $email = trim($email);

        // 1. Email validation
        if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new \Exception("Please provide a valid email address.");
        }

        // 2. Query user existence
        $user = self::findByEmail($email);
        if (!$user) {
            throw new \Exception("No account found with this email address.");
        }

        // 3. Generate 6-digit OTP code & 10-minute expiry
        $otp = (string)random_int(100000, 999999);
        $expiresAt = time() + (10 * 60);

        return [
            'success' => true,
            'email' => $email,
            'otp' => $otp,
            'expires_in_seconds' => 600,
            'message' => "OTP recovery code generated successfully.",
        ];
    }

    public static function resetPassword(string $email, string $newPassword): array {
        $email = trim($email);
        $newPassword = (string)$newPassword;

        if (strlen($newPassword) < 8) {
            throw new \Exception("Password must be at least 8 characters long.");
        }

        $user = self::findByEmail($email);
        if (!$user) {
            throw new \Exception("User not found.");
        }

        $pdo = Database::getConnection();
        $hash = password_hash($newPassword, PASSWORD_BCRYPT);
        $stmt = $pdo->prepare("UPDATE users SET password_hash = :hash WHERE id = :id");
        $stmt->execute([
            ':hash' => $hash,
            ':id' => $user['id'],
        ]);

        return [
            'success' => true,
            'message' => "Password has been reset successfully.",
        ];
    }
}

