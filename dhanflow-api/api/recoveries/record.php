<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();
    $service = new RecoveryService($db);

    if (!$request->isPost()) Response::error('Method not allowed', 405);

    $recoveryId = $request->routeParam('recoveries');
    if (!$recoveryId) Response::error('Recovery ID required', 400);

    $request
        ->requireFields(['amount_paise'])
        ->requirePositiveInt('amount_paise')
        ->validate();

    $result = $service->recordPayment(
        recoveryId:   $recoveryId,
        amountPaise:  (int)$request->input('amount_paise'),
        note:         (string)($request->input('note') ?? ''),
        linkedCardId: $request->input('linked_card_id'),
        userId:       $userId
    );

    Response::success($result, $result['is_settled']
        ? "Recovery fully settled!"
        : "Recovery payment recorded");
} catch (\InvalidArgumentException $e) {
    Response::error($e->getMessage(), 422);
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Recovery recording failed');
}
