<?php

return new class {
    public function up(PDO $pdo, string $driver): void {
        if ($driver === 'mysql') {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS orders (
                    id VARCHAR(60) PRIMARY KEY,
                    order_number VARCHAR(50) NOT NULL UNIQUE,
                    user_id VARCHAR(60) DEFAULT 'guest',
                    total_amount DECIMAL(10, 2) NOT NULL,
                    subtotal DECIMAL(10, 2) NOT NULL,
                    shipping_fee DECIMAL(10, 2) DEFAULT 0.00,
                    discount_amount DECIMAL(10, 2) DEFAULT 0.00,
                    promo_code VARCHAR(50) DEFAULT NULL,
                    shipping_address TEXT NOT NULL,
                    payment_method VARCHAR(100) NOT NULL,
                    status VARCHAR(50) DEFAULT 'Processing',
                    tracking_number VARCHAR(60) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_user_orders (user_id),
                    INDEX idx_tracking (tracking_number)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ");
        } else {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS orders (
                    id TEXT PRIMARY KEY,
                    order_number TEXT NOT NULL UNIQUE,
                    user_id TEXT DEFAULT 'guest',
                    total_amount REAL NOT NULL,
                    subtotal REAL NOT NULL,
                    shipping_fee REAL DEFAULT 0.00,
                    discount_amount REAL DEFAULT 0.00,
                    promo_code TEXT,
                    shipping_address TEXT NOT NULL,
                    payment_method TEXT NOT NULL,
                    status TEXT DEFAULT 'Processing',
                    tracking_number TEXT,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                );
            ");
        }
    }

    public function down(PDO $pdo, string $driver): void {
        $pdo->exec("DROP TABLE IF EXISTS orders;");
    }
};
