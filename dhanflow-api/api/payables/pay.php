<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    if (!$request->isPost()) Response::error('Method not allowed', 405);

    $id = $request->routeParam('payables');
    if (!$id) Response::error('Payable ID required', 400);

    $request
        ->requireFields(['amount_paise'])
        ->requirePositiveInt('amount_paise')
        ->validate();

    $payable = $db->findOrFail('personal_payables', $id, $userId);
    $amt     = (int)$request->input('amount_paise');
    $current = (int)$payable['amount'];

    if ($amt > $current) {
        Response::error('Payment exceeds remaining payable balance', 422);
    }

    $newAmount = max(0, $current - $amt);
    $isSettled = $newAmount === 0 ? 1 : 0;
    $now       = $db->now();

    $db->beginTransaction();
    try {
        $db->update('personal_payables', $id, $userId, [
            'amount'     => $newAmount,
            'is_settled' => $isSettled,
        ]);

        $db->insert('activity_log', [
            'user_id'             => $userId,
            'event_type'          => 'PAYABLE_PAID',
            'description'         => "{$payable['name']}: Paid ₹" . number_format($amt / 100, 2) . ". Remaining: ₹" . number_format($newAmount / 100, 2),
            'delta_paise'         => -$amt,
            'related_entity_type' => 'payable',
            'related_entity_id'   => $id,
            'related_entity_name' => $payable['name'],
            'created_at'          => $now,
        ]);

        $db->commit();
        Response::success([
            'payable_id'     => $id,
            'paid_paise'     => $amt,
            'remaining_paise'=> $newAmount,
            'is_settled'     => (bool)$isSettled,
        ]);
    } catch (\Throwable $e) {
        $db->rollBack();
        throw $e;
    }
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Payable payment failed');
}
