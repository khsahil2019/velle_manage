<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    $cardId = $request->routeParam('cards');
    if (!$cardId) Response::error('Card ID required', 400);

    $card = $db->findOrFail('credit_cards', $cardId, $userId);

    if ($request->isGet()) {
        $txns = $db->execute(
            "SELECT * FROM card_transactions WHERE card_id = ? AND user_id = ? ORDER BY txn_date DESC LIMIT 100",
            [$cardId, $userId]
        )->fetchAll();
        Response::success($txns);
    }

    if ($request->isPost()) {
        $request
            ->requireFields(['type', 'amount_paise'])
            ->requirePositiveInt('amount_paise')
            ->validate();

        $type        = strtoupper(trim((string)$request->input('type')));
        $amountPaise = (int)$request->input('amount_paise');
        $note        = trim((string)($request->input('note') ?? ''));

        if (!in_array($type, ['PAYMENT', 'SPEND'], true)) {
            Response::error('type must be PAYMENT or SPEND', 422);
        }

        $totalLimit  = (int)$card['total_limit'];
        $avlLimit    = (int)$card['available_limit'];
        $outstanding = max(0, $totalLimit - $avlLimit);
        $now         = $db->now();

        if ($type === 'PAYMENT') {
            $newOutstanding = max(0, $outstanding - $amountPaise);
            $newAvl         = $totalLimit - $newOutstanding;
            $eventType      = 'CC_PAYMENT';
            $delta          = -$amountPaise;
            $desc           = "{$card['name']}: Payment of ₹" . number_format($amountPaise / 100, 2) . ($note ? " — {$note}" : "");
        } else {
            if ($amountPaise > $avlLimit) {
                Response::error('Spend exceeds available limit of ₹' . number_format($avlLimit / 100, 2), 422);
            }
            $newAvl         = max(0, $avlLimit - $amountPaise);
            $newOutstanding = $totalLimit - $newAvl;
            $eventType      = 'CC_SPEND';
            $delta          = $amountPaise;
            $desc           = "{$card['name']}: Spend of ₹" . number_format($amountPaise / 100, 2) . ($note ? " — {$note}" : "");
        }

        $db->beginTransaction();
        try {
            $db->execute(
                "UPDATE credit_cards SET available_limit = ?, updated_at = ? WHERE id = ? AND user_id = ?",
                [$newAvl, $now, $cardId, $userId]
            );

            $txnId = $db->insert('card_transactions', [
                'card_id'    => $cardId,
                'user_id'    => $userId,
                'type'       => $type,
                'amount'     => $amountPaise,
                'note'       => $note,
                'txn_date'   => $now,
                'created_at' => $now,
            ]);

            $db->insert('activity_log', [
                'user_id'             => $userId,
                'event_type'          => $eventType,
                'description'         => $desc,
                'delta_paise'         => $delta,
                'related_entity_type' => 'credit_card',
                'related_entity_id'   => $cardId,
                'related_entity_name' => $card['name'],
                'metadata_json'       => json_encode(['txn_id' => $txnId, 'type' => $type]),
                'created_at'          => $now,
            ]);

            $db->commit();
            Response::success([
                'transaction_id'  => $txnId,
                'card_id'         => $cardId,
                'new_available'   => $newAvl,
                'new_outstanding' => $newOutstanding,
                'utilization_pct' => $totalLimit > 0 ? round(($newOutstanding / $totalLimit) * 100, 2) : 0.0,
            ], 'Transaction recorded', 201);
        } catch (\Throwable $e) {
            $db->rollBack();
            throw $e;
        }
    }

    Response::error('Method not allowed', 405);
} catch (\RuntimeException $e) {
    if ($e->getCode() === 404) Response::notFound($e->getMessage());
    error_log('[DHANFLOW] Card txns error: ' . $e->getMessage());
    Response::serverError();
} catch (\Throwable $e) {
    error_log('[DHANFLOW] Card txns error: ' . $e->getMessage());
    Response::serverError();
}
