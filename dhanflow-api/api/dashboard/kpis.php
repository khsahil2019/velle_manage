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
    $code = $e->getCode();
    if ($code === 401) Response::unauthorized($e->getMessage());
    if ($code === 404) Response::notFound($e->getMessage());
    error_log('[DHANFLOW] KPI error: ' . $e->getMessage());
    Response::serverError('Failed to compute KPIs');
}
