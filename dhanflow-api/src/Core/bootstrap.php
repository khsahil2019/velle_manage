<?php
declare(strict_types=1);

date_default_timezone_set('Asia/Kolkata');

require_once __DIR__ . '/Database.php';
require_once __DIR__ . '/Response.php';
require_once __DIR__ . '/Auth.php';
require_once __DIR__ . '/../../src/Services/KPIService.php';
require_once __DIR__ . '/../../src/Services/RecoveryService.php';
require_once __DIR__ . '/../../src/Services/DebtEngineService.php';
require_once __DIR__ . '/../../src/Services/SeedService.php';

// Universal CORS preflight handling
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Authorization, Content-Type, X-Requested-With');
    exit;
}
