<?php

namespace App\Models;

use App\Config\Database;

class Category {
    public static function getAll(): array {
        $pdo = Database::getConnection();
        $stmt = $pdo->query("SELECT * FROM categories ORDER BY id ASC");
        return $stmt->fetchAll();
    }
}

