<?php
declare(strict_types=1);
require_once __DIR__ . '/../src/Core/bootstrap.php';

$config = Database::inspectConfiguration();
$jwtRaw = $_ENV['JWT_SECRET'] ?? $_SERVER['JWT_SECRET'] ?? getenv('JWT_SECRET');
$jwtConfigured = is_string($jwtRaw) && trim($jwtRaw) !== '';

Response::success([
    'service'               => 'Trustvly PHP API',
    'version'               => '1.0.0',
    'runtime'               => 'PHP ' . PHP_VERSION,
    'status'                => $config['database_configured'] ? 'healthy' : 'database_not_configured',
    'database_configured'   => $config['database_configured'],
    'database_driver'       => $config['database_driver'],
    'config_source'         => $config['config_source'],
    'jwt_configured'        => $jwtConfigured,
    'extensions'            => $config['extensions'],
    'time'                  => date('c'),
], $config['database_configured'] ? 'OK' : 'API reachable, but Vercel database env vars are not set yet');
