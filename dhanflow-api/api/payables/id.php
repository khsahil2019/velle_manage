<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    $id = $request->routeParam('payables');
    if (!$id) Response::error('Payable ID required', 400);

    $payable = $db->findOrFail('personal_payables', $id, $userId);

    if ($request->isGet()) Response::success($payable);

    if ($request->isPut()) {
        $data = [];
        if ($request->input('name') !== null) $data['name'] = trim((string)$request->input('name'));
        if ($request->input('note') !== null) $data['note'] = trim((string)$request->input('note'));
        if ($request->input('amount') !== null) {
            $amt = (int)$request->input('amount');
            if ($amt < 0) Response::error('amount cannot be negative', 422);
            $data['amount']     = $amt;
            $data['is_settled'] = $amt === 0 ? 1 : 0;
        }
        $db->update('personal_payables', $id, $userId, $data);
        Response::success($db->findOrFail('personal_payables', $id, $userId), 'Payable updated');
    }

    if ($request->isDelete()) {
        $db->execute("DELETE FROM personal_payables WHERE id = ? AND user_id = ?", [$id, $userId]);
        $db->insert('activity_log', [
            'user_id'             => $userId,
            'event_type'          => 'PAYABLE_PAID',
            'description'         => "Payable removed: {$payable['name']}",
            'related_entity_type' => 'payable',
            'related_entity_id'   => $id,
            'related_entity_name' => $payable['name'],
            'created_at'          => $db->now(),
        ]);
        Response::success(['deleted' => true], 'Payable removed');
    }

    Response::error('Method not allowed', 405);
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Payable operation failed');
}
