<?php

return new class {
    public function up(PDO $pdo, string $driver): void {
        if ($driver === 'mysql') {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS order_items (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    order_id VARCHAR(60) NOT NULL,
                    product_id INT NOT NULL,
                    product_name VARCHAR(255) NOT NULL,
                    product_image TEXT DEFAULT NULL,
                    quantity INT NOT NULL DEFAULT 1,
                    price DECIMAL(10, 2) NOT NULL,
                    selected_size VARCHAR(50) DEFAULT NULL,
                    selected_color VARCHAR(50) DEFAULT NULL,
                    INDEX idx_order_items (order_id),
                    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ");
        } else {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS order_items (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    order_id TEXT NOT NULL,
                    product_id INTEGER NOT NULL,
                    product_name TEXT NOT NULL,
                    product_image TEXT,
                    quantity INTEGER NOT NULL DEFAULT 1,
                    price REAL NOT NULL,
                    selected_size TEXT,
                    selected_color TEXT,
                    FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
                );
            ");
        }
    }

    public function down(PDO $pdo, string $driver): void {
        $pdo->exec("DROP TABLE IF EXISTS order_items;");
    }
};
