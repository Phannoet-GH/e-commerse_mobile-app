<?php

require_once __DIR__ . '/MigrationRunner.php';

use App\Db\MigrationRunner;

$runner = new MigrationRunner();

$command = $argv[1] ?? 'up';
$hasSeed = in_array('--seed', $argv) || in_array('-s', $argv);

echo "\n⚡ LuxeCart Database Migration Tool\n";
echo "Active Driver: " . \App\Config\Database::getActiveDriver() . "\n\n";

switch (strtolower($command)) {
    case 'up':
    case 'migrate':
        $runner->up();
        break;

    case 'down':
    case 'rollback':
        $runner->rollback();
        break;

    case 'status':
        $runner->status();
        break;

    case 'fresh':
        $runner->fresh($hasSeed);
        break;

    case 'refresh':
        $runner->rollback();
        $runner->up();
        break;

    case 'help':
    default:
        echo "Usage: php backend/db/migrate.php [command] [options]\n\n";
        echo "Available Commands:\n";
        echo "  up              Run all pending migrations (default)\n";
        echo "  down / rollback Rollback the last migration batch\n";
        echo "  status          Show the status of each migration\n";
        echo "  fresh           Drop all tables and re-run all migrations\n";
        echo "  fresh --seed    Drop all tables, re-run migrations, and seed data\n";
        echo "  refresh         Rollback and re-run the latest batch\n";
        break;
}
