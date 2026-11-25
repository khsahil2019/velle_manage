<?php
declare(strict_types=1);

/**
 * DHANFLOW API — Vercel PHP Serverless Backend
 * Multi-Driver Database Singleton:
 *  - MySQL 8+ (DB_HOST / MYSQL_URL / DATABASE_URL mysql://)
 *  - PostgreSQL (Neon / Supabase / Vercel Postgres via POSTGRES_URL / DATABASE_URL postgres://)
 *  - SQLite (DB_DRIVER=sqlite for local testing)
 *
 * All identifiers are unquoted lowercase so queries run identically on MySQL, PostgreSQL, and SQLite.
 */
class Database {
    private static ?Database $instance = null;
    private PDO $pdo;
    private string $driver;

    private function __construct() {
        $url = (string)($_ENV['DATABASE_URL'] ?? getenv('DATABASE_URL')
            ?: ($_ENV['POSTGRES_URL'] ?? getenv('POSTGRES_URL')
            ?: ($_ENV['MYSQL_URL'] ?? getenv('MYSQL_URL') ?: '')));

        $explicitDriver = strtolower((string)($_ENV['DB_DRIVER'] ?? getenv('DB_DRIVER') ?: ''));

        if ($explicitDriver === 'sqlite') {
            $this->driver = 'sqlite';
            $path = (string)($_ENV['DB_PATH'] ?? getenv('DB_PATH') ?: ':memory:');
            $this->pdo = new PDO("sqlite:{$path}", null, null, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]);
            $this->pdo->exec('PRAGMA foreign_keys = ON;');
            $this->ensureSchemaInitialized();
            return;
        }

        if ($url !== '' && (str_starts_with($url, 'postgres://') || str_starts_with($url, 'postgresql://'))) {
            $this->driver = 'pgsql';
            $parts = parse_url($url);
            $host  = $parts['host'] ?? '127.0.0.1';
            $port  = $parts['port'] ?? 5432;
            $db    = ltrim((string)($parts['path'] ?? '/postgres'), '/');
            $user  = urldecode((string)($parts['user'] ?? ''));
            $pass  = urldecode((string)($parts['pass'] ?? ''));
            parse_str((string)($parts['query'] ?? ''), $q);
            $ssl   = $q['sslmode'] ?? 'require';
            $dsn   = "pgsql:host={$host};port={$port};dbname={$db};sslmode={$ssl}";
            $this->pdo = new PDO($dsn, $user, $pass, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]);
            $this->ensureSchemaInitialized();
            return;
        }

        if ($url !== '' && str_starts_with($url, 'mysql://')) {
            $this->driver = 'mysql';
            $parts = parse_url($url);
            $host  = $parts['host'] ?? '127.0.0.1';
            $port  = (string)($parts['port'] ?? '3306');
            $name  = ltrim((string)($parts['path'] ?? '/dhanflow'), '/');
            $user  = urldecode((string)($parts['user'] ?? ''));
            $pass  = urldecode((string)($parts['pass'] ?? ''));
        } else {
            $this->driver = $explicitDriver === 'pgsql' ? 'pgsql' : 'mysql';
            $host = (string)($_ENV['DB_HOST'] ?? getenv('DB_HOST') ?: '');
            $name = (string)($_ENV['DB_NAME'] ?? getenv('DB_NAME') ?: '');
            $user = (string)($_ENV['DB_USER'] ?? getenv('DB_USER') ?: '');
            $pass = (string)($_ENV['DB_PASS'] ?? getenv('DB_PASS') ?: '');
            $port = (string)($_ENV['DB_PORT'] ?? getenv('DB_PORT') ?: ($this->driver === 'pgsql' ? '5432' : '3306'));
        }

        if ($host === '' || $name === '' || $user === '') {
            throw new \RuntimeException(
                'Database not configured: set DATABASE_URL (PostgreSQL/MySQL) or DB_HOST, DB_NAME, DB_USER, DB_PASS, JWT_SECRET in Vercel Environment Variables.',
                503
            );
        }

        if ($this->driver === 'pgsql') {
            $ssl = (string)($_ENV['DB_SSLMODE'] ?? getenv('DB_SSLMODE') ?: 'require');
            $dsn = "pgsql:host={$host};port={$port};dbname={$name};sslmode={$ssl}";
            $this->pdo = new PDO($dsn, $user, $pass, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]);
        } else {
            $dsn = "mysql:host={$host};port={$port};dbname={$name};charset=utf8mb4";
            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ];
            if (defined('PDO::MYSQL_ATTR_INIT_COMMAND')) {
                $options[PDO::MYSQL_ATTR_INIT_COMMAND] = "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci";
            }
            $this->pdo = new PDO($dsn, $user, $pass, $options);
        }

        $this->ensureSchemaInitialized();
    }

    public static function getInstance(): self {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public static function resetInstance(): void {
        self::$instance = null;
    }

    public function getPDO(): PDO {
        return $this->pdo;
    }

    public function getDriver(): string {
        return $this->driver;
    }

    public function now(): string {
        return date('Y-m-d H:i:s');
    }

    public function execute(string $sql, array $params = []): \PDOStatement {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt;
    }

    public function findAll(string $table, string $userId, string $orderBy = 'created_at DESC'): array {
        return $this->execute(
            "SELECT * FROM {$table} WHERE user_id = ? AND is_active = 1 ORDER BY {$orderBy}",
            [$userId]
        )->fetchAll();
    }

    public function findOrFail(string $table, string $id, string $userId): array {
        $row = $this->execute(
            "SELECT * FROM {$table} WHERE id = ? AND user_id = ?",
            [$id, $userId]
        )->fetch();

        if (!$row) {
            throw new \RuntimeException("Record not found in {$table}: {$id}", 404);
        }
        return $row;
    }

    public function insert(string $table, array $data, bool $autoId = true): string {
        if ($autoId && $table !== 'user_settings' && !isset($data['id'])) {
            $data['id'] = $this->generateUUID();
        }
        $cols   = implode(', ', array_keys($data));
        $places = implode(', ', array_fill(0, count($data), '?'));
        $this->execute("INSERT INTO {$table} ({$cols}) VALUES ({$places})", array_values($data));
        return (string)($data['id'] ?? $data['user_id'] ?? '');
    }

    public function update(string $table, string $id, string $userId, array $data): bool {
        $data['updated_at'] = $this->now();
        $sets = implode(', ', array_map(fn($k) => "{$k} = ?", array_keys($data)));
        $this->execute(
            "UPDATE {$table} SET {$sets} WHERE id = ? AND user_id = ?",
            [...array_values($data), $id, $userId]
        );
        return true;
    }

    public function softDelete(string $table, string $id, string $userId): bool {
        $this->execute(
            "UPDATE {$table} SET is_active = 0, updated_at = ? WHERE id = ? AND user_id = ?",
            [$this->now(), $id, $userId]
        );
        return true;
    }

    public function beginTransaction(): void { $this->pdo->beginTransaction(); }
    public function commit(): void           { $this->pdo->commit(); }
    public function rollBack(): void         { $this->pdo->rollBack(); }

    public function generateUUID(): string {
        return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            random_int(0, 0xffff), random_int(0, 0xffff),
            random_int(0, 0xffff),
            random_int(0, 0x0fff) | 0x4000,
            random_int(0, 0x3fff) | 0x8000,
            random_int(0, 0xffff), random_int(0, 0xffff), random_int(0, 0xffff)
        );
    }

    /**
     * Auto-initializes core tables if missing (zero-friction Vercel + Postgres/MySQL/SQLite setup).
     */
    private function ensureSchemaInitialized(): void {
        try {
            $this->pdo->query("SELECT 1 FROM users LIMIT 1");
            return;
        } catch (\Throwable) {
            // Table does not exist yet — create schema
        }

        $textType = $this->driver === 'mysql' ? 'TEXT' : 'TEXT';
        $jsonType = $this->driver === 'pgsql' ? 'TEXT' : ($this->driver === 'mysql' ? 'LONGTEXT' : 'TEXT');
        $str36    = $this->driver === 'mysql' ? 'CHAR(36)' : 'VARCHAR(36)';
        $dtType   = $this->driver === 'mysql' ? 'DATETIME' : ($this->driver === 'pgsql' ? 'TIMESTAMP' : 'TEXT');

        $stmts = [
            "CREATE TABLE IF NOT EXISTS users (
                id {$str36} PRIMARY KEY,
                email VARCHAR(255) UNIQUE NOT NULL,
                name VARCHAR(100) NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                plan VARCHAR(20) NOT NULL DEFAULT 'free',
                plan_expires_at {$dtType} NULL,
                created_at {$dtType} NOT NULL,
                updated_at {$dtType} NOT NULL
            )",
            "CREATE TABLE IF NOT EXISTS credit_cards (
                id {$str36} PRIMARY KEY,
                user_id {$str36} NOT NULL,
                name VARCHAR(100) NOT NULL,
                total_limit BIGINT NOT NULL,
                available_limit BIGINT NOT NULL,
                category_tag VARCHAR(100) NOT NULL DEFAULT 'Active Pocket Debt',
                display_order INTEGER NOT NULL DEFAULT 0,
                is_active SMALLINT NOT NULL DEFAULT 1,
                apr_bps INTEGER NOT NULL DEFAULT 3600,
                created_at {$dtType} NOT NULL,
                updated_at {$dtType} NOT NULL
            )",
            "CREATE TABLE IF NOT EXISTS card_transactions (
                id {$str36} PRIMARY KEY,
                card_id {$str36} NOT NULL,
                user_id {$str36} NOT NULL,
                type VARCHAR(32) NOT NULL,
                amount BIGINT NOT NULL,
                note VARCHAR(255) NULL,
                txn_date {$dtType} NOT NULL,
                created_at {$dtType} NOT NULL
            )",
            "CREATE TABLE IF NOT EXISTS loans (
                id {$str36} PRIMARY KEY,
                user_id {$str36} NOT NULL,
                name VARCHAR(100) NOT NULL,
                emi_amount BIGINT NOT NULL,
                remaining_emis INTEGER NOT NULL DEFAULT 0,
                original_emis INTEGER NOT NULL,
                total_remaining BIGINT NOT NULL,
                note VARCHAR(255) NULL,
                is_active SMALLINT NOT NULL DEFAULT 1,
                apr_bps INTEGER NOT NULL DEFAULT 1600,
                created_at {$dtType} NOT NULL,
                updated_at {$dtType} NOT NULL
            )",
            "CREATE TABLE IF NOT EXISTS personal_payables (
                id {$str36} PRIMARY KEY,
                user_id {$str36} NOT NULL,
                name VARCHAR(100) NOT NULL,
                amount BIGINT NOT NULL,
                note VARCHAR(255) NULL,
                is_settled SMALLINT NOT NULL DEFAULT 0,
                created_at {$dtType} NOT NULL,
                updated_at {$dtType} NOT NULL
            )",
            "CREATE TABLE IF NOT EXISTS recoveries (
                id {$str36} PRIMARY KEY,
                user_id {$str36} NOT NULL,
                name VARCHAR(100) NOT NULL,
                total_original BIGINT NOT NULL,
                total_pending BIGINT NOT NULL,
                note VARCHAR(500) NULL,
                is_settled SMALLINT NOT NULL DEFAULT 0,
                created_at {$dtType} NOT NULL,
                updated_at {$dtType} NOT NULL
            )",
            "CREATE TABLE IF NOT EXISTS recovery_payments (
                id {$str36} PRIMARY KEY,
                recovery_id {$str36} NOT NULL,
                user_id {$str36} NOT NULL,
                amount BIGINT NOT NULL,
                applied_to_card {$str36} NULL,
                note VARCHAR(255) NULL,
                payment_date {$dtType} NOT NULL,
                created_at {$dtType} NOT NULL
            )",
            "CREATE TABLE IF NOT EXISTS bullion_transactions (
                id {$str36} PRIMARY KEY,
                user_id {$str36} NOT NULL,
                metal VARCHAR(16) NOT NULL,
                grams_x10000 BIGINT NOT NULL,
                buy_rate_paise BIGINT NOT NULL,
                pre_gst_paise BIGINT NOT NULL,
                gst_paise BIGINT NOT NULL,
                total_paid_paise BIGINT NOT NULL,
                purchase_date {$dtType} NOT NULL,
                platform VARCHAR(50) NOT NULL DEFAULT 'Gullak',
                created_at {$dtType} NOT NULL
            )",
            "CREATE TABLE IF NOT EXISTS user_settings (
                user_id {$str36} PRIMARY KEY,
                gold_current_sell_paise BIGINT NULL,
                silver_current_sell_paise BIGINT NULL,
                debt_payoff_strategy VARCHAR(20) NOT NULL DEFAULT 'snowball',
                monthly_payment_capacity BIGINT NOT NULL DEFAULT 2500000,
                currency VARCHAR(8) NOT NULL DEFAULT 'INR',
                updated_at {$dtType} NOT NULL
            )",
            "CREATE TABLE IF NOT EXISTS activity_log (
                id {$str36} PRIMARY KEY,
                user_id {$str36} NOT NULL,
                event_type VARCHAR(40) NOT NULL,
                description {$textType} NOT NULL,
                delta_paise BIGINT NULL,
                related_entity_type VARCHAR(50) NULL,
                related_entity_id {$str36} NULL,
                related_entity_name VARCHAR(100) NULL,
                metadata_json {$jsonType} NULL,
                is_reversed SMALLINT NOT NULL DEFAULT 0,
                created_at {$dtType} NOT NULL
            )",
        ];

        foreach ($stmts as $sql) {
            $this->pdo->exec($sql);
        }
    }
}
