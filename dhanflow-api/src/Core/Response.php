<?php
declare(strict_types=1);

/**
 * JSON Response Builder
 * All API responses follow the same envelope format.
 */
class Response {
    public static function json(mixed $data, int $status = 200): never {
        self::setHeaders($status);
        echo json_encode([
            'success' => $status < 400,
            'data'    => $data,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    public static function success(mixed $data, string $message = 'OK', int $status = 200): never {
        self::setHeaders($status);
        echo json_encode([
            'success' => true,
            'message' => $message,
            'data'    => $data,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    public static function error(string $message, int $status = 400, mixed $errors = null): never {
        self::setHeaders($status);
        $body = ['success' => false, 'message' => $message];
        if ($errors !== null) $body['errors'] = $errors;
        echo json_encode($body, JSON_UNESCAPED_UNICODE);
        exit;
    }

    public static function unauthorized(string $message = 'Unauthorized'): never {
        self::error($message, 401);
    }

    public static function notFound(string $message = 'Not found'): never {
        self::error($message, 404);
    }

    public static function serverError(string $message = 'Internal server error'): never {
        self::error($message, 500);
    }

    private static function setHeaders(int $status): void {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Authorization, Content-Type, X-Requested-With');
        
        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            exit;
        }
    }
}

/**
 * Request helper — input validation and sanitization.
 */
class Request {
    private array $body;
    private array $query;
    private array $errors = [];

    public function __construct() {
        $this->query = $_GET ?? [];
        $raw = file_get_contents('php://input');
        $this->body = json_decode($raw ?: '{}', true) ?? [];
    }

    public function input(string $key, mixed $default = null): mixed {
        return $this->body[$key] ?? $default;
    }

    public function query(string $key, mixed $default = null): mixed {
        return $this->query[$key] ?? $default;
    }

    public function segment(int $index): ?string {
        $path = parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH);
        $parts = array_values(array_filter(explode('/', $path)));
        return $parts[$index] ?? null;
    }

    /** Get route parameter from the URL path. E.g., /api/cards/UUID */
    public function routeParam(string $after): ?string {
        $path = parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH);
        $parts = explode("/{$after}/", $path);
        if (count($parts) < 2) return null;
        return strtok($parts[1], '/') ?: null;
    }

    public function method(): string {
        return strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
    }

    public function isPost(): bool   { return $this->method() === 'POST'; }
    public function isGet(): bool    { return $this->method() === 'GET'; }
    public function isPut(): bool    { return $this->method() === 'PUT'; }
    public function isDelete(): bool { return $this->method() === 'DELETE'; }

    // ── Validation ─────────────────────────────────────────────

    public function requireFields(array $fields): self {
        foreach ($fields as $field) {
            if (!isset($this->body[$field]) || $this->body[$field] === '' || $this->body[$field] === null) {
                $this->errors[] = "{$field} is required";
            }
        }
        return $this;
    }

    public function requirePositiveInt(string $field): self {
        $val = $this->body[$field] ?? null;
        if (!is_int($val) || $val <= 0) {
            $this->errors[] = "{$field} must be a positive integer";
        }
        return $this;
    }

    public function requireNonNegativeInt(string $field): self {
        $val = $this->body[$field] ?? null;
        if (!is_int($val) || $val < 0) {
            $this->errors[] = "{$field} must be a non-negative integer";
        }
        return $this;
    }

    public function validate(): void {
        if (!empty($this->errors)) {
            Response::error('Validation failed', 422, $this->errors);
        }
    }

    public function hasErrors(): bool { return !empty($this->errors); }
    public function errors(): array   { return $this->errors; }
}
