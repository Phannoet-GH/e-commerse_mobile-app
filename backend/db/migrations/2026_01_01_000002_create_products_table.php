<?php

return new class {
    public function up(PDO $pdo, string $driver): void {
        if ($driver === 'mysql') {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS products (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    brand VARCHAR(100) NOT NULL,
                    price DECIMAL(10, 2) NOT NULL,
                    original_price DECIMAL(10, 2) DEFAULT NULL,
                    category VARCHAR(100) NOT NULL,
                    image_url TEXT NOT NULL,
                    rating DECIMAL(3, 1) DEFAULT 5.0,
                    reviews_count INT DEFAULT 0,
                    description TEXT DEFAULT NULL,
                    sizes JSON DEFAULT NULL,
                    colors JSON DEFAULT NULL,
                    specs JSON DEFAULT NULL,
                    badge VARCHAR(50) DEFAULT NULL,
                    in_stock TINYINT(1) DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_category (category),
                    INDEX idx_name (name),
                    INDEX idx_price (price)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ");
        } else {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS products (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    brand TEXT NOT NULL,
                    price REAL NOT NULL,
                    original_price REAL,
                    category TEXT NOT NULL,
                    image_url TEXT NOT NULL,
                    rating REAL DEFAULT 5.0,
                    reviews_count INTEGER DEFAULT 0,
                    description TEXT,
                    sizes TEXT,
                    colors TEXT,
                    specs TEXT,
                    badge TEXT,
                    in_stock INTEGER DEFAULT 1,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                );
            ");
        }
    }

    public function down(PDO $pdo, string $driver): void {
        $pdo->exec("DROP TABLE IF EXISTS products;");
    }
};
