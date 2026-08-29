<?php

require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/Database.php';

use App\Config\Config;
use App\Config\Database;

Config::load();

echo "===================================================\n";
echo "       LuxeCart - MySQL Database Diagnostic\n";
echo "===================================================\n";
echo "Configured DB_TYPE:     " . Config::get('DB_TYPE') . "\n";
echo "Configured DB_HOST:     " . Config::get('DB_HOST') . "\n";
echo "Configured DB_PORT:     " . Config::get('DB_PORT') . "\n";
echo "Configured DB_DATABASE: " . Config::get('DB_DATABASE') . "\n";
echo "Configured DB_USERNAME: " . Config::get('DB_USERNAME') . "\n";
echo "---------------------------------------------------\n";

try {
    $pdo = Database::getConnection();
    $driver = Database::getActiveDriver();

    echo "✅ Connection Success!\n";
    echo "Active Driver:          " . strtoupper($driver) . "\n";

    if ($driver === 'mysql') {
        $version = $pdo->query('SELECT VERSION() as v')->fetch()['v'];
        echo "MySQL Server Version:   $version\n";

        $dbName = $pdo->query('SELECT DATABASE() as db')->fetch()['db'];
        echo "Current Database:       $dbName\n";

        echo "---------------------------------------------------\n";
        echo "Database Tables in '$dbName':\n";
        $tables = $pdo->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN);
        foreach ($tables as $table) {
            $count = $pdo->query("SELECT COUNT(*) as c FROM `$table`")->fetch()['c'];
            echo "  - $table ($count rows)\n";
        }
    } else {
        echo "Connected to SQLite fallback database.\n";
    }

    echo "===================================================\n";
} catch (Throwable $e) {
    echo "❌ Error connecting to Database:\n";
    echo $e->getMessage() . "\n";
}

