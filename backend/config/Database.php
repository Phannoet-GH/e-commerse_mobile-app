<?php

namespace App\Config;

require_once __DIR__ . '/config.php';

use PDO;
use PDOException;

class Database {
    private static ?PDO $instance = null;
    private static string $activeDriver = 'unknown';

    public static function getConnection(): PDO {
        if (self::$instance === null) {
            Config::load();
            $dbType = strtolower(Config::get('DB_TYPE', 'mysql'));

            if ($dbType === 'mysql') {
                try {
                    self::$instance = self::createMysqlConnection();
                    self::$activeDriver = 'mysql';
                } catch (PDOException $e) {
                    error_log("MySQL connection failed: " . $e->getMessage() . " -> Falling back to SQLite.");
                    self::$instance = self::createSqliteConnection();
                    self::$activeDriver = 'sqlite';
                }
            } else {
                self::$instance = self::createSqliteConnection();
                self::$activeDriver = 'sqlite';
            }

            self::initializeTables(self::$instance, self::$activeDriver);
        }

        return self::$instance;
    }

    public static function getActiveDriver(): string {
        return self::$activeDriver;
    }

    private static function createMysqlConnection(): PDO {
        $host = Config::get('DB_HOST', '127.0.0.1');
        $port = Config::get('DB_PORT', '3306');
        $db   = Config::get('DB_DATABASE', 'se_shop_db');
        $user = Config::get('DB_USERNAME', 'root');
        $pass = Config::get('DB_PASSWORD', '');
        $charset = 'utf8mb4';

        // 1. Connect without database name first to create the database if it doesn't exist
        $serverDsn = "mysql:host=$host;port=$port;charset=$charset";
        $serverPdo = new PDO($serverDsn, $user, $pass, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        ]);
        $serverPdo->exec("CREATE DATABASE IF NOT EXISTS `$db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;");

        // 2. Connect to the actual database
        $dsn = "mysql:host=$host;port=$port;dbname=$db;charset=$charset";
        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ];

        return new PDO($dsn, $user, $pass, $options);
    }

    private static function createSqliteConnection(): PDO {
        $dbDir = __DIR__ . '/../data';
        if (!is_dir($dbDir)) {
            mkdir($dbDir, 0777, true);
        }

        $dbPath = $dbDir . '/ecommerce.db';
        $pdo = new PDO("sqlite:" . $dbPath);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        $pdo->exec("PRAGMA journal_mode = WAL;");
        return $pdo;
    }

    private static function initializeTables(PDO $pdo, string $driver): void {
        if ($driver === 'mysql') {
            $schemaFile = __DIR__ . '/../db/schema.sql';
            if (file_exists($schemaFile)) {
                $sql = file_get_contents($schemaFile);
                $pdo->exec($sql);
            }
        } else {
            $sqliteSchema = "
            CREATE TABLE IF NOT EXISTS categories (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                icon TEXT,
                description TEXT,
                accent_color TEXT,
                badge TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );

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

            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                phone TEXT,
                avatar_url TEXT,
                role TEXT DEFAULT 'customer',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );

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

            CREATE TABLE IF NOT EXISTS orders (
                id TEXT PRIMARY KEY,
                order_number TEXT UNIQUE NOT NULL,
                user_id TEXT,
                total_amount REAL NOT NULL,
                subtotal REAL NOT NULL,
                shipping_fee REAL DEFAULT 0.0,
                discount_amount REAL DEFAULT 0.0,
                promo_code TEXT,
                shipping_address TEXT NOT NULL,
                payment_method TEXT NOT NULL,
                status TEXT DEFAULT 'Processing',
                tracking_number TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS order_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                order_id TEXT NOT NULL,
                product_id INTEGER NOT NULL,
                product_name TEXT NOT NULL,
                product_image TEXT,
                quantity INTEGER NOT NULL,
                price REAL NOT NULL,
                selected_size TEXT,
                selected_color TEXT,
                FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS reviews (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                product_id INTEGER NOT NULL,
                user_name TEXT NOT NULL,
                rating REAL NOT NULL,
                comment TEXT NOT NULL,
                date TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS coupons (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                code TEXT UNIQUE NOT NULL,
                discount_type TEXT NOT NULL,
                discount_value REAL NOT NULL,
                min_order_amount REAL DEFAULT 0.0,
                is_active INTEGER DEFAULT 1
            );
            ";

            $pdo->exec($sqliteSchema);
        }
    }
}
