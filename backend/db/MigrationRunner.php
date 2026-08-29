<?php

namespace App\Db;

require_once __DIR__ . '/../config/Database.php';

use App\Config\Database;
use PDO;

class MigrationRunner {
    private PDO $pdo;
    private string $driver;
    private string $migrationsDir;

    public function __construct() {
        $this->pdo = Database::getConnection();
        $this->driver = Database::getActiveDriver();
        $this->migrationsDir = __DIR__ . '/migrations';
        $this->ensureMigrationsTable();
    }

    private function ensureMigrationsTable(): void {
        if ($this->driver === 'mysql') {
            $this->pdo->exec("
                CREATE TABLE IF NOT EXISTS migrations (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    migration VARCHAR(255) NOT NULL UNIQUE,
                    batch INT NOT NULL,
                    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ");
        } else {
            $this->pdo->exec("
                CREATE TABLE IF NOT EXISTS migrations (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    migration TEXT NOT NULL UNIQUE,
                    batch INTEGER NOT NULL,
                    executed_at DATETIME DEFAULT CURRENT_TIMESTAMP
                );
            ");
        }
    }

    public function getExecutedMigrations(): array {
        $stmt = $this->pdo->query("SELECT migration FROM migrations ORDER BY id ASC");
        return $stmt->fetchAll(PDO::FETCH_COLUMN) ?: [];
    }

    public function getAllMigrationFiles(): array {
        if (!is_dir($this->migrationsDir)) {
            return [];
        }
        $files = scandir($this->migrationsDir);
        $migrations = [];
        foreach ($files as $file) {
            if (str_ends_with($file, '.php')) {
                $migrations[] = $file;
            }
        }
        sort($migrations);
        return $migrations;
    }

    public function getNextBatchNumber(): int {
        $stmt = $this->pdo->query("SELECT MAX(batch) as max_batch FROM migrations");
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return ($row['max_batch'] ?? 0) + 1;
    }

    public function up(): int {
        $all = $this->getAllMigrationFiles();
        $executed = $this->getExecutedMigrations();
        $pending = array_diff($all, $executed);

        if (empty($pending)) {
            echo "✨ Nothing to migrate. Database is already up to date.\n";
            return 0;
        }

        $batch = $this->getNextBatchNumber();
        $count = 0;

        echo "🚀 Running " . count($pending) . " pending migration(s) [Batch {$batch}]...\n";

        foreach ($pending as $file) {
            $filePath = $this->migrationsDir . '/' . $file;
            $migration = require $filePath;

            $start = microtime(true);
            echo "  ⏵ Migrating: {$file}... ";

            try {
                $migration->up($this->pdo, $this->driver);
                $stmt = $this->pdo->prepare("INSERT INTO migrations (migration, batch) VALUES (:migration, :batch)");
                $stmt->execute(['migration' => $file, 'batch' => $batch]);
                $time = round((microtime(true) - $start) * 1000, 2);
                echo "✅ DONE ({$time}ms)\n";
                $count++;
            } catch (\Throwable $e) {
                echo "❌ FAILED: " . $e->getMessage() . "\n";
                throw $e;
            }
        }

        echo "🎉 Migrations completed successfully ({$count} applied).\n";
        return $count;
    }

    public function rollback(): int {
        $stmt = $this->pdo->query("SELECT MAX(batch) as max_batch FROM migrations");
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        $lastBatch = $row['max_batch'] ?? null;

        if (!$lastBatch) {
            echo "ℹ️ No migrations found to rollback.\n";
            return 0;
        }

        $stmt = $this->pdo->prepare("SELECT migration FROM migrations WHERE batch = :batch ORDER BY id DESC");
        $stmt->execute(['batch' => $lastBatch]);
        $migrations = $stmt->fetchAll(PDO::FETCH_COLUMN);

        echo "⏪ Rolling back Batch {$lastBatch} (" . count($migrations) . " migrations)...\n";
        $count = 0;

        foreach ($migrations as $file) {
            $filePath = $this->migrationsDir . '/' . $file;
            if (!file_exists($filePath)) {
                echo "  ⚠️ Migration file {$file} missing, skipping down() execution.\n";
            } else {
                $migration = require $filePath;
                echo "  ⏵ Rolling back: {$file}... ";
                $migration->down($this->pdo, $this->driver);
                echo "✅ ROLLED BACK\n";
            }

            $delStmt = $this->pdo->prepare("DELETE FROM migrations WHERE migration = :migration");
            $delStmt->execute(['migration' => $file]);
            $count++;
        }

        echo "✨ Batch {$lastBatch} rolled back successfully ({$count} migrations removed).\n";
        return $count;
    }

    public function status(): void {
        $all = $this->getAllMigrationFiles();
        $stmt = $this->pdo->query("SELECT migration, batch, executed_at FROM migrations ORDER BY id ASC");
        $executedMap = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $executedMap[$row['migration']] = $row;
        }

        echo "\n=================================================================\n";
        echo "                    Database Migration Status\n";
        echo "=================================================================\n";
        echo sprintf("%-45s | %-8s | %-10s | %s\n", "Migration File", "Status", "Batch", "Executed At");
        echo str_repeat("-", 80) . "\n";

        foreach ($all as $file) {
            if (isset($executedMap[$file])) {
                $info = $executedMap[$file];
                echo sprintf("%-45s | \033[32m%-8s\033[0m | %-10s | %s\n", $file, "Ran", "#" . $info['batch'], $info['executed_at']);
            } else {
                echo sprintf("%-45s | \033[33m%-8s\033[0m | %-10s | %s\n", $file, "Pending", "-", "-");
            }
        }
        echo "=================================================================\n\n";
    }

    public function fresh(bool $seed = false): void {
        echo "🔥 Dropping all tables and resetting database...\n";

        if ($this->driver === 'mysql') {
            $this->pdo->exec("SET FOREIGN_KEY_CHECKS = 0;");
            $tables = ['wishlist_items', 'wishlists', 'reviews', 'order_items', 'orders', 'addresses', 'users', 'products', 'categories', 'coupons', 'migrations'];
            foreach ($tables as $table) {
                $this->pdo->exec("DROP TABLE IF EXISTS `{$table}`;");
            }
            $this->pdo->exec("SET FOREIGN_KEY_CHECKS = 1;");
        } else {
            $tables = ['wishlist_items', 'wishlists', 'reviews', 'order_items', 'orders', 'addresses', 'users', 'products', 'categories', 'coupons', 'migrations'];
            foreach ($tables as $table) {
                $this->pdo->exec("DROP TABLE IF EXISTS `{$table}`;");
            }
        }

        $this->ensureMigrationsTable();
        $this->up();

        if ($seed) {
            echo "🌱 Seeding database with fresh test data...\n";
            require_once __DIR__ . '/seed.php';
            seedDatabase();
        }
    }
}
