<?php

return new class {
    public function up(PDO $pdo, string $driver): void {
        if ($driver === 'mysql') {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS password_resets (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    email VARCHAR(191) NOT NULL,
                    otp_code VARCHAR(10) NOT NULL,
                    expires_at TIMESTAMP NOT NULL,
                    is_used TINYINT(1) DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_pw_reset_email (email),
                    INDEX idx_pw_reset_otp (otp_code)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ");
        } else {
            $pdo->exec("
                CREATE TABLE IF NOT EXISTS password_resets (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    email TEXT NOT NULL,
                    otp_code TEXT NOT NULL,
                    expires_at DATETIME NOT NULL,
                    is_used INTEGER DEFAULT 0,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                );
            ");
        }
    }

    public function down(PDO $pdo, string $driver): void {
        $pdo->exec("DROP TABLE IF EXISTS password_resets;");
    }
};

