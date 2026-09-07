<?php

namespace App\Models;

use App\Config\Database;
use PDO;

class Address {
    public static function getByUserId(string $userId): array {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT * FROM addresses WHERE user_id = :user_id ORDER BY is_default DESC, created_at DESC");
        $stmt->execute([':user_id' => $userId]);
        $rows = $stmt->fetchAll();

        return array_map([self::class, 'formatAddress'], $rows);
    }

    public static function create(array $data): array {
        $pdo = Database::getConnection();
        $id = $data['id'] ?? ('addr_' . time() . '_' . bin2hex(random_bytes(3)));
        $userId = $data['user_id'] ?? 'guest';
        $isDefault = !empty($data['is_default']) ? 1 : 0;

        if ($isDefault && $userId !== 'guest') {
            $resetStmt = $pdo->prepare("UPDATE addresses SET is_default = 0 WHERE user_id = :user_id");
            $resetStmt->execute([':user_id' => $userId]);
        }

        $stmt = $pdo->prepare("
            INSERT INTO addresses (
                id, user_id, recipient_name, street, city, state, zip_code, country, phone, is_default
            ) VALUES (
                :id, :user_id, :recipient_name, :street, :city, :state, :zip_code, :country, :phone, :is_default
            )
        ");

        $stmt->execute([
            ':id' => $id,
            ':user_id' => $userId,
            ':recipient_name' => $data['recipient_name'] ?? 'Emma Wills',
            ':street' => $data['street'] ?? '',
            ':city' => $data['city'] ?? '',
            ':state' => $data['state'] ?? '',
            ':zip_code' => $data['zip_code'] ?? '',
            ':country' => $data['country'] ?? 'United States',
            ':phone' => $data['phone'] ?? '+1 (555) 000-0000',
            ':is_default' => $isDefault,
        ]);

        return self::getById($id);
    }

    public static function getById(string $id): ?array {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT * FROM addresses WHERE id = :id LIMIT 1");
        $stmt->execute([':id' => $id]);
        $row = $stmt->fetch();
        return $row ? self::formatAddress($row) : null;
    }

    public static function delete(string $id, ?string $userId = null): bool {
        $pdo = Database::getConnection();
        if ($userId) {
            $stmt = $pdo->prepare("DELETE FROM addresses WHERE id = :id AND user_id = :user_id");
            return $stmt->execute([':id' => $id, ':user_id' => $userId]);
        } else {
            $stmt = $pdo->prepare("DELETE FROM addresses WHERE id = :id");
            return $stmt->execute([':id' => $id]);
        }
    }

    public static function setDefault(string $id, string $userId): bool {
        $pdo = Database::getConnection();
        $resetStmt = $pdo->prepare("UPDATE addresses SET is_default = 0 WHERE user_id = :user_id");
        $resetStmt->execute([':user_id' => $userId]);

        $stmt = $pdo->prepare("UPDATE addresses SET is_default = 1 WHERE id = :id AND user_id = :user_id");
        return $stmt->execute([':id' => $id, ':user_id' => $userId]);
    }

    private static function formatAddress(array $row): array {
        return [
            'id' => (string)$row['id'],
            'user_id' => $row['user_id'],
            'recipient_name' => $row['recipient_name'],
            'street' => $row['street'],
            'city' => $row['city'],
            'state' => $row['state'],
            'zip_code' => $row['zip_code'],
            'country' => $row['country'] ?? 'United States',
            'phone' => $row['phone'],
            'is_default' => (bool)$row['is_default'],
            'created_at' => $row['created_at'] ?? null,
        ];
    }
}