<?php

return new class {
    public function up(PDO $pdo, string $driver): void {
        if ($driver === 'mysql') {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS users (
                    id VARCHAR(60) PRIMARY KEY,
                    name VARCHAR(150) NOT NULL,
                    email VARCHAR(191) NOT NULL UNIQUE,
                    password_hash VARCHAR(255) NOT NULL,
                    phone VARCHAR(50) DEFAULT NULL,
                    avatar_url TEXT DEFAULT NULL,
                    role VARCHAR(50) DEFAULT 'customer',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_email (email)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ");
        } else {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    email TEXT NOT NULL UNIQUE,
                    password_hash TEXT NOT NULL,
                    phone TEXT,
                    avatar_url TEXT,
                    role TEXT DEFAULT 'customer',
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                );
            ");
        }
    }

    public function down(PDO $pdo, string $driver): void {
        $pdo->exec("DROP TABLE IF EXISTS users;");
    }
};
