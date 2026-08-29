<?php

namespace App\Models;

use App\Config\Database;
use PDO;

class Review {
    public static function getByProductId(int $productId): array {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT * FROM reviews WHERE product_id = :id ORDER BY id DESC");
        $stmt->execute([':id' => $productId]);
        return $stmt->fetchAll();
    }

    public static function add(int $productId, string $userName, float $rating, string $comment): array {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("
            INSERT INTO reviews (product_id, user_name, rating, comment, date)
            VALUES (:product_id, :user_name, :rating, :comment, :date)
        ");

        $dateStr = date('M d, Y');
        $stmt->execute([
            ':product_id' => $productId,
            ':user_name' => trim($userName),
            ':rating' => $rating,
            ':comment' => trim($comment),
            ':date' => $dateStr,
        ]);

        // Update product average rating & review count
        $avgStmt = $pdo->prepare("SELECT AVG(rating) as avg_rating, COUNT(*) as count FROM reviews WHERE product_id = :pid");
        $avgStmt->execute([':pid' => $productId]);
        $stats = $avgStmt->fetch();

        $updateStmt = $pdo->prepare("UPDATE products SET rating = :rating, reviews_count = :count WHERE id = :id");
        $updateStmt->execute([
            ':rating' => round((float)$stats['avg_rating'], 1),
            ':count' => (int)$stats['count'],
            ':id' => $productId,
        ]);

        return [
            'id' => (int)$pdo->lastInsertId(),
            'product_id' => $productId,
            'user_name' => trim($userName),
            'rating' => $rating,
            'comment' => trim($comment),
            'date' => $dateStr,
        ];
    }
}

