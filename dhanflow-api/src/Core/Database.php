<?php
declare(strict_types=1);

/**
 * DHANFLOW API — Vercel PHP Serverless Backend
 * Database singleton with PDO (MySQL production / SQLite local dev & tests)
 *
 * CRITICAL: All monetary values stored and computed in PAISE (integer).
 * Never use floating-point for financial calculations.
 */
class Database {
    private static ?Database $instance = null;
    private PDO $pdo;
    private string $driver;

    private function __construct() {
        $this->driver = strtolower((string)($_ENV['DB_DRIVER'] ?? getenv('DB_DRIVER') ?: 'mysql'));

        if ($this->driver === 'sqlite') {
            $path = $_ENV['DB_PATH'] ?? getenv('DB_PATH') ?: ':memory:';
            $this->pdo = new PDO("sqlite:{$path}", null, null, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]);
            $this->pdo->exec('PRAGMA foreign_keys = ON;');
        } else {
            $host = $_ENV['DB_HOST'] ?? getenv('DB_HOST') ?: '127.0.0.1';
            $name = $_ENV['DB_NAME'] ?? getenv('DB_NAME') ?: 'dhanflow';
            $user = $_ENV['DB_USER'] ?? getenv('DB_USER') ?: 'root';
            $pass = $_ENV['DB_PASS'] ?? getenv('DB_PASS') ?: '';
            $port = $_ENV['DB_PORT'] ?? getenv('DB_PORT') ?: '3306';

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
            "SELECT * FROM `{$table}` WHERE user_id = ? AND is_active = 1 ORDER BY {$orderBy}",
            [$userId]
        )->fetchAll();
    }

    public function findOrFail(string $table, string $id, string $userId): array {
        $row = $this->execute(
            "SELECT * FROM `{$table}` WHERE id = ? AND user_id = ?",
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
        $cols   = implode(', ', array_map(fn($k) => "`{$k}`", array_keys($data)));
        $places = implode(', ', array_fill(0, count($data), '?'));
        $this->execute("INSERT INTO `{$table}` ({$cols}) VALUES ({$places})", array_values($data));
        return (string)($data['id'] ?? $data['user_id'] ?? '');
    }

    public function update(string $table, string $id, string $userId, array $data): bool {
        $data['updated_at'] = $this->now();
        $sets = implode(', ', array_map(fn($k) => "`{$k}` = ?", array_keys($data)));
        $this->execute(
            "UPDATE `{$table}` SET {$sets} WHERE id = ? AND user_id = ?",
            [...array_values($data), $id, $userId]
        );
        return true;
    }

    public function softDelete(string $table, string $id, string $userId): bool {
        $this->execute(
            "UPDATE `{$table}` SET is_active = 0, updated_at = ? WHERE id = ? AND user_id = ?",
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
}
