<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId = Auth::requireAuth();
    $db     = Database::getInstance();
    $kpi    = new KPIService($db);

    $snapshot = $kpi->getFullSnapshot($userId);
    Response::success($snapshot);
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Failed to compute KPIs');
}
