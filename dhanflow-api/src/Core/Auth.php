<?php
declare(strict_types=1);

/**
 * JWT Authentication Middleware & Token Service
 */
class Auth {
    private const ALGORITHM = 'HS256';
    private static string $secret;

    public static function init(): void {
        self::$secret = $_ENV['JWT_SECRET'] ?? getenv('JWT_SECRET') ?: 'dhanflow_dev_secret_change_in_prod';
    }

    public static function requireAuth(): string {
        self::init();
        $header = self::extractAuthHeader();

        if (!str_starts_with($header, 'Bearer ')) {
            Response::unauthorized('No bearer token provided');
        }

        $token = trim(substr($header, 7));

        try {
            $payload = self::decodeJWT($token);
        } catch (\Throwable $e) {
            Response::unauthorized('Invalid or expired token: ' . $e->getMessage());
        }

        if (!isset($payload['sub'])) {
            Response::unauthorized('Token missing subject claim');
        }
        if (($payload['type'] ?? 'access') !== 'access') {
            Response::unauthorized('Invalid token type');
        }
        if (isset($payload['exp']) && $payload['exp'] < time()) {
            Response::unauthorized('Token has expired');
        }

        return (string)$payload['sub'];
    }

    public static function validateRefreshToken(string $token): string {
        self::init();
        $payload = self::decodeJWT($token);

        if (!isset($payload['sub']) || ($payload['type'] ?? '') !== 'refresh') {
            throw new \InvalidArgumentException('Invalid refresh token');
        }
        if (isset($payload['exp']) && $payload['exp'] < time()) {
            throw new \InvalidArgumentException('Refresh token expired');
        }
        return (string)$payload['sub'];
    }

    public static function generateTokenPair(string $userId): array {
        self::init();
        return [
            'access_token'  => self::encodeJWT(['sub' => $userId, 'exp' => time() + 900, 'type' => 'access']),
            'refresh_token' => self::encodeJWT(['sub' => $userId, 'exp' => time() + 2592000, 'type' => 'refresh']),
            'expires_in'    => 900,
        ];
    }

    private static function extractAuthHeader(): string {
        if (!empty($_SERVER['HTTP_AUTHORIZATION'])) {
            return (string)$_SERVER['HTTP_AUTHORIZATION'];
        }
        if (!empty($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
            return (string)$_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        }
        if (function_exists('getallheaders')) {
            foreach (getallheaders() as $key => $val) {
                if (strtolower((string)$key) === 'authorization') {
                    return (string)$val;
                }
            }
        }
        return '';
    }

    private static function encodeJWT(array $payload): string {
        $header  = self::base64url(json_encode(['alg' => self::ALGORITHM, 'typ' => 'JWT']));
        $payload = self::base64url(json_encode($payload));
        $sig     = self::base64url(hash_hmac('sha256', "{$header}.{$payload}", self::$secret, true));
        return "{$header}.{$payload}.{$sig}";
    }

    private static function decodeJWT(string $token): array {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            throw new \InvalidArgumentException('Malformed token');
        }

        [$header, $payload, $sig] = $parts;
        $expectedSig = self::base64url(hash_hmac('sha256', "{$header}.{$payload}", self::$secret, true));

        if (!hash_equals($expectedSig, $sig)) {
            throw new \InvalidArgumentException('Invalid signature');
        }

        $decoded = json_decode(self::base64urlDecode($payload), true);
        if (!is_array($decoded)) {
            throw new \InvalidArgumentException('Invalid payload');
        }
        return $decoded;
    }

    private static function base64url(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function base64urlDecode(string $data): string {
        return base64_decode(strtr($data, '-_', '+/') . str_repeat('=', (4 - strlen($data) % 4) % 4));
    }
}
