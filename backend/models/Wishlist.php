<?php

namespace App\Models;

use App\Config\Database;
use PDO;

class Wishlist {
    public static function getByUserId(string $userId): array {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT * FROM wishlists WHERE user_id = :user_id OR user_id = 'default' ORDER BY is_default DESC, created_at ASC");
        $stmt->execute([':user_id' => $userId]);
        $rows = $stmt->fetchAll();

        $result = [];
        foreach ($rows as $row) {
            $itemsStmt = $pdo->prepare("SELECT product_id FROM wishlist_items WHERE wishlist_id = :wishlist_id ORDER BY added_at ASC");
            $itemsStmt->execute([':wishlist_id' => $row['id']]);
            $itemRows = $itemsStmt->fetchAll(PDO::FETCH_COLUMN);

            $result[] = [
                'id' => (string)$row['id'],
                'user_id' => $row['user_id'],
                'name' => $row['name'],
                'description' => $row['description'] ?? '',
                'icon' => $row['icon'] ?? '✨',
                'is_default' => (bool)$row['is_default'],
                'created_at' => $row['created_at'] ?? null,
                'product_ids' => array_map('intval', $itemRows),
            ];
        }

        return $result;
    }

    public static function create(array $data): array {
        $pdo = Database::getConnection();
        $id = $data['id'] ?? ('wish_' . time() . '_' . bin2hex(random_bytes(3)));
        $userId = $data['user_id'] ?? 'guest';

        $stmt = $pdo->prepare("
            INSERT INTO wishlists (id, user_id, name, description, icon, is_default)
            VALUES (:id, :user_id, :name, :description, :icon, :is_default)
        ");

        $stmt->execute([
            ':id' => $id,
            ':user_id' => $userId,
            ':name' => $data['name'] ?? 'My Wishlist',
            ':description' => $data['description'] ?? '',
            ':icon' => $data['icon'] ?? '✨',
            ':is_default' => !empty($data['is_default']) ? 1 : 0,
        ]);

        if (!empty($data['product_ids']) && is_array($data['product_ids'])) {
            $itemStmt = $pdo->prepare("INSERT INTO wishlist_items (wishlist_id, product_id) VALUES (:wishlist_id, :product_id)");
            foreach ($data['product_ids'] as $pid) {
                $itemStmt->execute([':wishlist_id' => $id, ':product_id' => (int)$pid]);
            }
        }

        return self::getById($id);
    }

    public static function getById(string $id): ?array {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT * FROM wishlists WHERE id = :id LIMIT 1");
        $stmt->execute([':id' => $id]);
        $row = $stmt->fetch();
        if (!$row) return null;

        $itemsStmt = $pdo->prepare("SELECT product_id FROM wishlist_items WHERE wishlist_id = :wishlist_id ORDER BY added_at ASC");
        $itemsStmt->execute([':wishlist_id' => $id]);
        $itemRows = $itemsStmt->fetchAll(PDO::FETCH_COLUMN);

        return [
            'id' => (string)$row['id'],
            'user_id' => $row['user_id'],
            'name' => $row['name'],
            'description' => $row['description'] ?? '',
            'icon' => $row['icon'] ?? '✨',
            'is_default' => (bool)$row['is_default'],
            'created_at' => $row['created_at'] ?? null,
            'product_ids' => array_map('intval', $itemRows),
        ];
    }

    public static function addItem(string $wishlistId, int $productId): bool {
        $pdo = Database::getConnection();
        $check = $pdo->prepare("SELECT id FROM wishlist_items WHERE wishlist_id = :wishlist_id AND product_id = :product_id");
        $check->execute([':wishlist_id' => $wishlistId, ':product_id' => $productId]);
        if ($check->fetch()) return true;

        $stmt = $pdo->prepare("INSERT INTO wishlist_items (wishlist_id, product_id) VALUES (:wishlist_id, :product_id)");
        return $stmt->execute([':wishlist_id' => $wishlistId, ':product_id' => $productId]);
    }

    public static function removeItem(string $wishlistId, int $productId): bool {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("DELETE FROM wishlist_items WHERE wishlist_id = :wishlist_id AND product_id = :product_id");
        return $stmt->execute([':wishlist_id' => $wishlistId, ':product_id' => $productId]);
    }

    public static function delete(string $id, ?string $userId = null): bool {
        $pdo = Database::getConnection();
        if ($userId) {
            $stmt = $pdo->prepare("DELETE FROM wishlists WHERE id = :id AND user_id = :user_id");
            return $stmt->execute([':id' => $id, ':user_id' => $userId]);
        } else {
            $stmt = $pdo->prepare("DELETE FROM wishlists WHERE id = :id");
            return $stmt->execute([':id' => $id]);
        }
    }
}