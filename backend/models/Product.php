<?php

namespace App\Models;

use App\Config\Database;
use PDO;

class Product {
    public static function getAll(?string $category = null, ?string $search = null, int $limit = 50, int $offset = 0): array {
        $pdo = Database::getConnection();

        $query = "SELECT * FROM products WHERE 1=1";
        $params = [];

        if ($category !== null && $category !== '' && strtolower($category) !== 'all') {
            $query .= " AND LOWER(category) = LOWER(:category)";
            $params[':category'] = $category;
        }

        if ($search !== null && $search !== '') {
            $query .= " AND (LOWER(name) LIKE :s1 OR LOWER(brand) LIKE :s2 OR LOWER(description) LIKE :s3 OR LOWER(category) LIKE :s4)";
            $term = '%' . strtolower($search) . '%';
            $params[':s1'] = $term;
            $params[':s2'] = $term;
            $params[':s3'] = $term;
            $params[':s4'] = $term;
        }

        $query .= " ORDER BY id ASC LIMIT :limit OFFSET :offset";

        $stmt = $pdo->prepare($query);
        foreach ($params as $key => $val) {
            $stmt->bindValue($key, $val);
        }
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
        $stmt->execute();

        $rows = $stmt->fetchAll();
        return array_map([self::class, 'formatProduct'], $rows);
    }

    public static function getById(int $id): ?array {
        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("SELECT * FROM products WHERE id = :id LIMIT 1");
        $stmt->execute([':id' => $id]);
        $row = $stmt->fetch();

        if (!$row) return null;

        $product = self::formatProduct($row);

        // Fetch customer reviews for this product
        $reviewStmt = $pdo->prepare("SELECT * FROM reviews WHERE product_id = :product_id ORDER BY id DESC");
        $reviewStmt->execute([':product_id' => $id]);
        $product['customer_reviews'] = $reviewStmt->fetchAll();

        return $product;
    }

    public static function formatProduct(array $row): array {
        return [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'brand' => $row['brand'],
            'price' => (float)$row['price'],
            'original_price' => isset($row['original_price']) && $row['original_price'] !== null ? (float)$row['original_price'] : null,
            'category' => $row['category'],
            'image' => $row['image_url'],
            'image_url' => $row['image_url'],
            'rating' => (float)$row['rating'],
            'reviews' => (int)$row['reviews_count'],
            'reviews_count' => (int)$row['reviews_count'],
            'description' => $row['description'] ?? '',
            'sizes' => !empty($row['sizes']) ? json_decode($row['sizes'], true) : [],
            'colors' => !empty($row['colors']) ? json_decode($row['colors'], true) : [],
            'specs' => !empty($row['specs']) ? json_decode($row['specs'], true) : [],
            'badge' => $row['badge'] ?: null,
            'in_stock' => (bool)$row['in_stock'],
        ];
    }
}

