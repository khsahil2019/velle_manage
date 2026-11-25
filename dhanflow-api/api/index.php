<?php
declare(strict_types=1);
require_once __DIR__ . '/../src/Core/bootstrap.php';

$config = Database::inspectConfiguration();
$jwtRaw = $_ENV['JWT_SECRET'] ?? $_SERVER['JWT_SECRET'] ?? getenv('JWT_SECRET');
$jwtConfigured = is_string($jwtRaw) && trim($jwtRaw) !== '';

$dbConnected = false;
$schemaReady = false;
$dbError = null;

if ($config['database_configured']) {
    try {
        $db = Database::getInstance(); // Auto-creates full 11-table schema if missing
        $db->execute("SELECT 1 FROM users LIMIT 1");
        $db->execute("SELECT 1 FROM personal_assets LIMIT 1");
        $dbConnected = true;
        $schemaReady = true;
    } catch (\Throwable $e) {
        $dbError = $e->getMessage();
    }
}

$statusText = !$config['database_configured']
    ? 'database_not_configured'
    : ($dbConnected ? 'healthy' : 'database_connection_error');

$msgText = !$config['database_configured']
    ? 'API reachable, but Vercel database env vars are not set yet'
    : ($dbConnected
        ? 'OK'
        : ('Database env vars found, but connection failed: ' . ($dbError ?? 'unknown error')));

Response::success([
    'service'               => 'Trustvly PHP API',
    'version'               => '1.0.0',
    'runtime'               => 'PHP ' . PHP_VERSION,
    'status'                => $statusText,
    'database_configured'   => $config['database_configured'],
    'database_connected'    => $dbConnected,
    'schema_ready'          => $schemaReady,
    'database_driver'       => $config['database_driver'],
    'config_source'         => $config['config_source'],
    'jwt_configured'        => $jwtConfigured,
    'database_error'        => $dbError,
    'extensions'            => $config['extensions'],
    'time'                  => date('c'),
], $msgText);
