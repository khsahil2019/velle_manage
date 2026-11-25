<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    if ($request->isGet()) {
        $payables = $db->execute(
            "SELECT * FROM personal_payables WHERE user_id = ? AND is_settled = 0 ORDER BY created_at ASC",
            [$userId]
        )->fetchAll();
        Response::success($payables);
    }

    if ($request->isPost()) {
        $request
            ->requireFields(['name', 'amount'])
            ->requirePositiveInt('amount')
            ->validate();

        $name   = trim((string)$request->input('name'));
        $amount = (int)$request->input('amount');
        $note   = trim((string)($request->input('note') ?? ''));
        $now    = $db->now();

        $id = $db->insert('personal_payables', [
            'user_id'    => $userId,
            'name'       => $name,
            'amount'     => $amount,
            'note'       => $note,
            'is_settled' => 0,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $db->insert('activity_log', [
            'user_id'             => $userId,
            'event_type'          => 'PAYABLE_PAID',
            'description'         => "Payable added: {$name} — ₹" . number_format($amount / 100, 2),
            'delta_paise'         => $amount,
            'related_entity_type' => 'payable',
            'related_entity_id'   => $id,
            'related_entity_name' => $name,
            'created_at'          => $now,
        ]);

        Response::success($db->findOrFail('personal_payables', $id, $userId), 'Payable added', 201);
    }

    Response::error('Method not allowed', 405);
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Payables operation failed');
}
