<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    if (!$request->isPost()) Response::error('Method not allowed', 405);

    $cardId = $request->routeParam('cards');
    if (!$cardId) Response::error('Card ID required', 400);

    $request
        ->requireFields(['available_limit'])
        ->requireNonNegativeInt('available_limit')
        ->validate();

    $card       = $db->findOrFail('credit_cards', $cardId, $userId);
    $totalLimit = (int)$card['total_limit'];
    $oldAvl     = (int)$card['available_limit'];
    $newAvl     = (int)$request->input('available_limit');

    if ($newAvl > $totalLimit) {
        Response::error('Available limit cannot exceed total limit of ₹' . number_format($totalLimit / 100, 2), 422);
    }

    $oldOutstanding = max(0, $totalLimit - $oldAvl);
    $newOutstanding = max(0, $totalLimit - $newAvl);
    $delta          = $newOutstanding - $oldOutstanding;
    $now            = $db->now();

    $db->beginTransaction();
    try {
        $db->execute(
            "UPDATE credit_cards SET available_limit = ?, updated_at = ? WHERE id = ? AND user_id = ?",
            [$newAvl, $now, $cardId, $userId]
        );

        $db->insert('card_transactions', [
            'card_id'    => $cardId,
            'user_id'    => $userId,
            'type'       => 'AVL_UPDATE',
            'amount'     => abs($delta),
            'note'       => "Available limit updated from ₹" . number_format($oldAvl / 100, 2) . " to ₹" . number_format($newAvl / 100, 2),
            'txn_date'   => $now,
            'created_at' => $now,
        ]);

        $db->insert('activity_log', [
            'user_id'             => $userId,
            'event_type'          => 'CC_UPDATE',
            'description'         => "{$card['name']}: Avl limit updated → ₹" . number_format($newAvl / 100, 2) . " (outstanding: ₹" . number_format($newOutstanding / 100, 2) . ")",
            'delta_paise'         => $delta,
            'related_entity_type' => 'credit_card',
            'related_entity_id'   => $cardId,
            'related_entity_name' => $card['name'],
            'metadata_json'       => json_encode(['old_avl' => $oldAvl, 'new_avl' => $newAvl]),
            'created_at'          => $now,
        ]);

        $db->commit();
    } catch (\Throwable $e) {
        $db->rollBack();
        throw $e;
    }

    Response::success([
        'card_id'         => $cardId,
        'new_available'   => $newAvl,
        'new_outstanding' => $newOutstanding,
        'utilization_pct' => $totalLimit > 0 ? round(($newOutstanding / $totalLimit) * 100, 2) : 0.0,
    ]);
} catch (\RuntimeException $e) {
    if ($e->getCode() === 404) Response::notFound($e->getMessage());
    error_log('[DHANFLOW] AVL update error: ' . $e->getMessage());
    Response::serverError();
} catch (\Throwable $e) {
    error_log('[DHANFLOW] Unexpected: ' . $e->getMessage());
    Response::serverError();
}
