<?php
declare(strict_types=1);

/**
 * DHANFLOW Vercel Root PHP Front Controller
 * Routes all /api/* requests to dhanflow-api/api/* cleanly under 1 serverless function.
 */

date_default_timezone_set('Asia/Kolkata');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Authorization, Content-Type, X-Requested-With');
    exit;
}

// Resolve route path cleanly from ?__route=... (Vercel rewrite) or REQUEST_URI
$route = '';
if (isset($_GET['__route'])) {
    $route = trim((string)$_GET['__route'], '/');
    $_SERVER['REQUEST_URI'] = '/api/' . $route;
} else {
    $uriPath = (string)(parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?? '/');
    $route   = preg_replace('#^/?api/?#', '', $uriPath) ?? '';
    $route   = trim($route, '/');
}

$apiRoot = __DIR__ . '/../dhanflow-api/api';

$target = match (true) {
    $route === '' || $route === 'index' || $route === 'index.php' || $route === 'health' => $apiRoot . '/index.php',

    // Auth
    $route === 'auth/register' => $apiRoot . '/auth/register.php',
    $route === 'auth/login'    => $apiRoot . '/auth/login.php',
    $route === 'auth/refresh'  => $apiRoot . '/auth/refresh.php',
    $route === 'auth/me'       => $apiRoot . '/auth/me.php',
    $route === 'auth/logout'   => $apiRoot . '/auth/logout.php',

    // Dashboard & Debt Engine
    $route === 'dashboard/kpis'   => $apiRoot . '/dashboard/kpis.php',
    $route === 'debt-engine/plan' => $apiRoot . '/debt-engine/plan.php',

    // Credit Cards
    (bool)preg_match('#^cards/[^/]+/avl-update$#', $route)   => $apiRoot . '/cards/avl-update.php',
    (bool)preg_match('#^cards/[^/]+/transactions$#', $route) => $apiRoot . '/cards/transactions.php',
    (bool)preg_match('#^cards/[^/]+$#', $route)              => $apiRoot . '/cards/id.php',
    $route === 'cards'                                       => $apiRoot . '/cards/index.php',

    // Loans
    (bool)preg_match('#^loans/[^/]+/emi-paid$#', $route) => $apiRoot . '/loans/emi-paid.php',
    (bool)preg_match('#^loans/[^/]+$#', $route)          => $apiRoot . '/loans/id.php',
    $route === 'loans'                                   => $apiRoot . '/loans/index.php',

    // Payables
    (bool)preg_match('#^payables/[^/]+/pay$#', $route) => $apiRoot . '/payables/pay.php',
    (bool)preg_match('#^payables/[^/]+$#', $route)     => $apiRoot . '/payables/id.php',
    $route === 'payables'                              => $apiRoot . '/payables/index.php',

    // Recoveries
    (bool)preg_match('#^recoveries/[^/]+/record$#', $route) => $apiRoot . '/recoveries/record.php',
    (bool)preg_match('#^recoveries/[^/]+$#', $route)        => $apiRoot . '/recoveries/id.php',
    $route === 'recoveries'                                 => $apiRoot . '/recoveries/index.php',

    // Bullion
    $route === 'bullion/summary'                               => $apiRoot . '/bullion/summary.php',
    (bool)preg_match('#^bullion/transactions(/[^/]+)?$#', $route) => $apiRoot . '/bullion/transactions.php',
    $route === 'bullion'                                       => $apiRoot . '/bullion/index.php',

    // Activity & Backup
    $route === 'activity'          => $apiRoot . '/activity/index.php',
    $route === 'backup/export'     => $apiRoot . '/backup/export.php',
    $route === 'backup/import'     => $apiRoot . '/backup/import.php',
    $route === 'backup/reset-seed' => $apiRoot . '/backup/reset-seed.php',

    default => null,
};

if ($target === null || !is_file($target)) {
    http_response_code(404);
    header('Content-Type: application/json; charset=utf-8');
    header('Access-Control-Allow-Origin: *');
    echo json_encode([
        'success' => false,
        'message' => 'API endpoint not found: /api/' . $route,
    ]);
    exit;
}

require $target;
