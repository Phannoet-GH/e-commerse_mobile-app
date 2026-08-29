<?php

return new class {
    public function up(PDO $pdo, string $driver): void {
        if ($driver === 'mysql') {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS wishlists (
                    id VARCHAR(60) PRIMARY KEY,
                    user_id VARCHAR(60) DEFAULT NULL,
                    name VARCHAR(150) NOT NULL,
                    description TEXT DEFAULT NULL,
                    icon VARCHAR(20) DEFAULT '✨',
                    is_default TINYINT(1) DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_wishlist_user (user_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

                CREATE TABLE IF NOT EXISTS wishlist_items (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    wishlist_id VARCHAR(60) NOT NULL,
                    product_id INT NOT NULL,
                    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_wishlist_items (wishlist_id),
                    CONSTRAINT fk_wishlist_items_wishlist FOREIGN KEY (wishlist_id) REFERENCES wishlists (id) ON DELETE CASCADE,
                    CONSTRAINT fk_wishlist_items_product FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ");
        } else {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS wishlists (
                    id TEXT PRIMARY KEY,
                    user_id TEXT,
                    name TEXT NOT NULL,
                    description TEXT,
                    icon TEXT DEFAULT '✨',
                    is_default INTEGER DEFAULT 0,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                );

                CREATE TABLE IF NOT EXISTS wishlist_items (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    wishlist_id TEXT NOT NULL,
                    product_id INTEGER NOT NULL,
                    added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (wishlist_id) REFERENCES wishlists (id) ON DELETE CASCADE,
                    FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
                );
            ");
        }
    }

    public function down(PDO $pdo, string $driver): void {
        $pdo->exec("DROP TABLE IF EXISTS wishlist_items;");
        $pdo->exec("DROP TABLE IF EXISTS wishlists;");
    }
};
