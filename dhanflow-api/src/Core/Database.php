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
        $spec = self::resolveConnectionSpec();
        if (!$spec['configured']) {
            throw new \RuntimeException(
                'Database not configured: set DATABASE_URL (PostgreSQL/MySQL) or DB_HOST, DB_NAME, DB_USER, DB_PASS, JWT_SECRET in Vercel Environment Variables.',
                503
            );
        }

        $this->driver = $spec['driver'];
        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ];

        if ($this->driver === 'sqlite') {
            $this->pdo = new PDO($spec['dsn'], null, null, $options);
            $this->pdo->exec('PRAGMA foreign_keys = ON;');
            $this->ensureSchemaInitialized();
            return;
        }

        if ($this->driver === 'mysql' && defined('PDO::MYSQL_ATTR_INIT_COMMAND')) {
            $options[PDO::MYSQL_ATTR_INIT_COMMAND] = "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci";
        }

        $this->pdo = new PDO($spec['dsn'], $spec['user'], $spec['pass'], $options);
        $this->ensureSchemaInitialized();
    }

    private static function readEnv(string $key): string {
        $val = $_ENV[$key] ?? $_SERVER[$key] ?? getenv($key);
        return is_string($val) ? trim($val) : '';
    }

    private static function firstEnv(array $keys): array {
        foreach ($keys as $key) {
            $val = self::readEnv($key);
            if ($val !== '') {
                return [$val, $key];
            }
        }
        return ['', ''];
    }

    public static function inspectConfiguration(): array {
        $spec = self::resolveConnectionSpec();
        return [
            'database_configured' => $spec['configured'],
            'database_driver'     => $spec['configured'] ? $spec['driver'] : null,
            'config_source'       => $spec['source'],
            'extensions'          => [
                'pdo'        => extension_loaded('pdo'),
                'pdo_pgsql'  => extension_loaded('pdo_pgsql'),
                'pdo_mysql'  => extension_loaded('pdo_mysql'),
                'pdo_sqlite' => extension_loaded('pdo_sqlite'),
                'bcmath'     => extension_loaded('bcmath'),
                'openssl'    => extension_loaded('openssl'),
            ],
        ];
    }

    private static function resolveConnectionSpec(): array {
        $explicitDriver = strtolower(self::readEnv('DB_DRIVER'));

        if ($explicitDriver === 'sqlite') {
            $path = self::readEnv('DB_PATH') ?: ':memory:';
            return [
                'configured' => true,
                'driver'     => 'sqlite',
                'dsn'        => "sqlite:{$path}",
                'user'       => null,
                'pass'       => null,
                'source'     => 'DB_DRIVER=sqlite',
            ];
        }

        [$url, $urlKey] = self::firstEnv([
            'DATABASE_URL',
            'POSTGRES_URL',
            'POSTGRES_PRISMA_URL',
            'POSTGRES_URL_NON_POOLING',
            'STORAGE_POSTGRES_URL',
            'NEON_DATABASE_URL',
            'SUPABASE_DB_URL',
            'MYSQL_URL',
            'DB_URL',
        ]);

        if ($url !== '') {
            $parts = parse_url($url);
            $scheme = strtolower((string)($parts['scheme'] ?? ''));
            if (in_array($scheme, ['postgres', 'postgresql', 'pgsql'], true)) {
                $host = $parts['host'] ?? '127.0.0.1';
                $port = (string)($parts['port'] ?? 5432);
                $db   = ltrim((string)($parts['path'] ?? '/postgres'), '/');
                $user = urldecode((string)($parts['user'] ?? ''));
                $pass = urldecode((string)($parts['pass'] ?? ''));
                parse_str((string)($parts['query'] ?? ''), $q);
                $ssl  = $q['sslmode'] ?? (self::readEnv('DB_SSLMODE') ?: 'require');
                return [
                    'configured' => $host !== '' && $db !== '' && $user !== '',
                    'driver'     => 'pgsql',
                    'dsn'        => "pgsql:host={$host};port={$port};dbname={$db};sslmode={$ssl}",
                    'user'       => $user,
                    'pass'       => $pass,
                    'source'     => $urlKey,
                ];
            }
            if ($scheme === 'mysql') {
                $host = $parts['host'] ?? '127.0.0.1';
                $port = (string)($parts['port'] ?? '3306');
                $db   = ltrim((string)($parts['path'] ?? '/dhanflow'), '/');
                $user = urldecode((string)($parts['user'] ?? ''));
                $pass = urldecode((string)($parts['pass'] ?? ''));
                return [
                    'configured' => $host !== '' && $db !== '' && $user !== '',
                    'driver'     => 'mysql',
                    'dsn'        => "mysql:host={$host};port={$port};dbname={$db};charset=utf8mb4",
                    'user'       => $user,
                    'pass'       => $pass,
                    'source'     => $urlKey,
                ];
            }
        }

        [$host, $hostKey] = self::firstEnv(['DB_HOST', 'PGHOST', 'MYSQLHOST']);
        [$name]            = self::firstEnv(['DB_NAME', 'PGDATABASE', 'MYSQLDATABASE']);
        [$user]            = self::firstEnv(['DB_USER', 'PGUSER', 'MYSQLUSER']);
        [$pass]            = self::firstEnv(['DB_PASS', 'PGPASSWORD', 'MYSQLPASSWORD', 'DB_PASSWORD']);

        $isPg = $explicitDriver === 'pgsql' || $hostKey === 'PGHOST';
        $driver = $isPg ? 'pgsql' : 'mysql';
        [$port] = self::firstEnv(['DB_PORT', 'PGPORT', 'MYSQLPORT']);
        if ($port === '') {
            $port = $driver === 'pgsql' ? '5432' : '3306';
        }

        if ($host === '' || $name === '' || $user === '') {
            return [
                'configured' => false,
                'driver'     => null,
                'dsn'        => '',
                'user'       => null,
                'pass'       => null,
                'source'     => 'none',
            ];
        }

        if ($driver === 'pgsql') {
            $ssl = self::readEnv('DB_SSLMODE') ?: 'require';
            $dsn = "pgsql:host={$host};port={$port};dbname={$name};sslmode={$ssl}";
        } else {
            $dsn = "mysql:host={$host};port={$port};dbname={$name};charset=utf8mb4";
        }

        return [
            'configured' => true,
            'driver'     => $driver,
            'dsn'        => $dsn,
            'user'       => $user,
            'pass'       => $pass,
            'source'     => $hostKey ?: 'DB_HOST',
        ];
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

    public function normalizeDateTime(?string $iso): string {
        if ($iso === null || trim($iso) === '') {
            return $this->now();
        }
        $ts = strtotime($iso);
        if ($ts === false) {
            return $this->now();
        }
        return date('Y-m-d H:i:s', $ts);
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
        $usersReady = false;
        $assetsReady = false;
        try {
            $this->pdo->query("SELECT 1 FROM users LIMIT 1");
            $usersReady = true;
        } catch (\Throwable) {
        }
        try {
            $this->pdo->query("SELECT 1 FROM personal_assets LIMIT 1");
            $assetsReady = true;
        } catch (\Throwable) {
        }
        if ($usersReady && $assetsReady) {
            return;
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
                metal VARCHAR(32) NOT NULL,
                grams_x10000 BIGINT NOT NULL,
                buy_rate_paise BIGINT NOT NULL,
                pre_gst_paise BIGINT NOT NULL,
                gst_paise BIGINT NOT NULL,
                total_paid_paise BIGINT NOT NULL,
                purchase_date {$dtType} NOT NULL,
                platform VARCHAR(50) NOT NULL DEFAULT 'Vault',
                created_at {$dtType} NOT NULL
            )",
            "CREATE TABLE IF NOT EXISTS personal_assets (
                id {$str36} PRIMARY KEY,
                user_id {$str36} NOT NULL,
                title VARCHAR(120) NOT NULL,
                category VARCHAR(32) NOT NULL DEFAULT 'other',
                quantity_label VARCHAR(80) NOT NULL DEFAULT '1 Unit',
                purchase_value_paise BIGINT NOT NULL DEFAULT 0,
                current_value_paise BIGINT NOT NULL DEFAULT 0,
                note VARCHAR(255) NULL,
                acquired_date {$dtType} NOT NULL,
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

        // Create helpful indexes safely across PostgreSQL & SQLite (ignore on MySQL variants without IF NOT EXISTS)
        $indexes = [
            "CREATE INDEX IF NOT EXISTS idx_cards_user ON credit_cards (user_id, display_order)",
            "CREATE INDEX IF NOT EXISTS idx_loans_user ON loans (user_id)",
            "CREATE INDEX IF NOT EXISTS idx_payables_user ON personal_payables (user_id)",
            "CREATE INDEX IF NOT EXISTS idx_recoveries_user ON recoveries (user_id)",
            "CREATE INDEX IF NOT EXISTS idx_bullion_user ON bullion_transactions (user_id, purchase_date)",
            "CREATE INDEX IF NOT EXISTS idx_assets_user ON personal_assets (user_id, acquired_date)",
            "CREATE INDEX IF NOT EXISTS idx_activity_user ON activity_log (user_id, created_at)",
        ];
        foreach ($indexes as $idxSql) {
            try {
                $this->pdo->exec($idxSql);
            } catch (\Throwable) {
            }
        }
    }
}
