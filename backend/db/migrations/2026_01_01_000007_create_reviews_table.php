<?php

return new class {
    public function up(PDO $pdo, string $driver): void {
        if ($driver === 'mysql') {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS reviews (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    product_id INT NOT NULL,
                    user_name VARCHAR(150) NOT NULL,
                    rating DECIMAL(2, 1) NOT NULL,
                    comment TEXT NOT NULL,
                    date VARCHAR(50) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_product_reviews (product_id),
                    CONSTRAINT fk_reviews_product FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ");
        } else {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS reviews (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    product_id INTEGER NOT NULL,
                    user_name TEXT NOT NULL,
                    rating REAL NOT NULL,
                    comment TEXT NOT NULL,
                    date TEXT,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
                );
            ");
        }
    }

    public function down(PDO $pdo, string $driver): void {
        $pdo->exec("DROP TABLE IF EXISTS reviews;");
    }
};
