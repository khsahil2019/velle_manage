<?php
declare(strict_types=1);
require_once __DIR__ . '/../src/Core/bootstrap.php';

Response::success([
    'service' => 'DHANFLOW PHP API',
    'version' => '1.0.0',
    'runtime' => 'PHP ' . PHP_VERSION,
    'status'  => 'healthy',
    'time'    => date('c'),
]);
