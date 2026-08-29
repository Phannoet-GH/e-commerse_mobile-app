<?php

return new class {
    public function up(PDO $pdo, string $driver): void {
        if ($driver === 'mysql') {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS addresses (
                    id VARCHAR(60) PRIMARY KEY,
                    user_id VARCHAR(60) DEFAULT NULL,
                    recipient_name VARCHAR(150) NOT NULL,
                    street VARCHAR(255) NOT NULL,
                    city VARCHAR(100) NOT NULL,
                    state VARCHAR(50) NOT NULL,
                    zip_code VARCHAR(30) NOT NULL,
                    country VARCHAR(100) DEFAULT 'United States',
                    phone VARCHAR(50) DEFAULT NULL,
                    is_default TINYINT(1) DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_user_id (user_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ");
        } else {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS addresses (
                    id TEXT PRIMARY KEY,
                    user_id TEXT,
                    recipient_name TEXT NOT NULL,
                    street TEXT NOT NULL,
                    city TEXT NOT NULL,
                    state TEXT NOT NULL,
                    zip_code TEXT NOT NULL,
                    country TEXT DEFAULT 'United States',
                    phone TEXT,
                    is_default INTEGER DEFAULT 0,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                );
            ");
        }
    }

    public function down(PDO $pdo, string $driver): void {
        $pdo->exec("DROP TABLE IF EXISTS addresses;");
    }
};
