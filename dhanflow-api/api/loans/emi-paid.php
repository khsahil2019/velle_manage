<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();
    $service = new RecoveryService($db);

    if (!$request->isPost()) Response::error('Method not allowed', 405);

    $loanId = $request->routeParam('loans');
    if (!$loanId) Response::error('Loan ID required', 400);

    $result = $service->markEMIPaid($loanId, $userId);

    Response::success($result, $result['is_cleared']
        ? "Loan fully cleared!"
        : "EMI marked as paid. {$result['new_remaining_emis']} remaining.");
} catch (\InvalidArgumentException $e) {
    Response::error($e->getMessage(), 422);
} catch (\RuntimeException $e) {
    if ($e->getCode() === 404) Response::notFound($e->getMessage());
    error_log('[DHANFLOW] EMI error: ' . $e->getMessage());
    Response::serverError('EMI update failed');
} catch (\Throwable $e) {
    error_log('[DHANFLOW] Unexpected: ' . $e->getMessage());
    Response::serverError();
}
