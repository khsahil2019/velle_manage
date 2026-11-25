<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    if ($request->isGet()) {
        $recoveries = $db->execute(
            "SELECT * FROM recoveries WHERE user_id = ? ORDER BY is_settled ASC, total_pending DESC",
            [$userId]
        )->fetchAll();

        foreach ($recoveries as &$r) {
            $r['payments'] = $db->execute(
                "SELECT * FROM recovery_payments WHERE recovery_id = ? AND user_id = ? ORDER BY payment_date DESC",
                [$r['id'], $userId]
            )->fetchAll();
        }
        unset($r);

        Response::success($recoveries);
    }

    if ($request->isPost()) {
        $request
            ->requireFields(['name', 'amount_paise'])
            ->requirePositiveInt('amount_paise')
            ->validate();

        $name   = trim((string)$request->input('name'));
        $amount = (int)$request->input('amount_paise');
        $note   = trim((string)($request->input('note') ?? ''));
        $now    = $db->now();

        $id = $db->insert('recoveries', [
            'user_id'        => $userId,
            'name'           => $name,
            'total_original' => $amount,
            'total_pending'  => $amount,
            'note'           => $note,
            'is_settled'     => 0,
            'created_at'     => $now,
            'updated_at'     => $now,
        ]);

        $db->insert('activity_log', [
            'user_id'             => $userId,
            'event_type'          => 'RECOVERY_RECEIVED',
            'description'         => "Borrower added: {$name} — ₹" . number_format($amount / 100, 2) . " pending",
            'delta_paise'         => $amount,
            'related_entity_type' => 'recovery',
            'related_entity_id'   => $id,
            'related_entity_name' => $name,
            'created_at'          => $now,
        ]);

        $rec = $db->findOrFail('recoveries', $id, $userId);
        $rec['payments'] = [];
        Response::success($rec, 'Borrower added', 201);
    }

    Response::error('Method not allowed', 405);
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Recoveries operation failed');
}
