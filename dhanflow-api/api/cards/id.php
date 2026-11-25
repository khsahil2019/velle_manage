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
        $limit = (int)$card['total_limit'];
        $avl   = (int)$card['available_limit'];
        $out   = max(0, $limit - $avl);
        $card['outstanding']     = $out;
        $card['utilization_pct'] = $limit > 0 ? round(($out / $limit) * 100, 2) : 0.0;
        Response::success($card);
    }

    if ($request->isPut()) {
        $oldLimit    = (int)$card['total_limit'];
        $oldAvl      = (int)$card['available_limit'];
        $outstanding = max(0, $oldLimit - $oldAvl);

        $newName = $request->input('name') !== null ? trim((string)$request->input('name')) : $card['name'];
        $newTag  = $request->input('category_tag') !== null ? trim((string)$request->input('category_tag')) : $card['category_tag'];
        $newLimit = $request->input('total_limit') !== null ? (int)$request->input('total_limit') : $oldLimit;

        if ($newLimit <= 0) {
            Response::error('total_limit must be positive', 422);
        }
        // Financial rule: limit decrease cannot go below outstanding
        if ($newLimit < $outstanding) {
            Response::error('New limit cannot be less than current outstanding (₹' . number_format($outstanding / 100, 2) . ')', 422);
        }

        // Outstanding remains unchanged on limit hike/decrease
        $newAvl = $newLimit - $outstanding;
        $now    = $db->now();

        $db->beginTransaction();
        try {
            $db->update('credit_cards', $cardId, $userId, [
                'name'            => $newName,
                'category_tag'    => $newTag,
                'total_limit'     => $newLimit,
                'available_limit' => $newAvl,
            ]);

            if ($newLimit !== $oldLimit) {
                $diff = $newLimit - $oldLimit;
                $type = $diff > 0 ? 'LIMIT_INCREASE' : 'LIMIT_DECREASE';
                $db->insert('card_transactions', [
                    'card_id'    => $cardId,
                    'user_id'    => $userId,
                    'type'       => $type,
                    'amount'     => abs($diff),
                    'note'       => "Limit updated from ₹" . number_format($oldLimit / 100, 2) . " to ₹" . number_format($newLimit / 100, 2),
                    'txn_date'   => $now,
                    'created_at' => $now,
                ]);
                $db->insert('activity_log', [
                    'user_id'             => $userId,
                    'event_type'          => 'CC_UPDATE',
                    'description'         => "{$newName}: Credit limit updated to ₹" . number_format($newLimit / 100, 2),
                    'delta_paise'         => $diff,
                    'related_entity_type' => 'credit_card',
                    'related_entity_id'   => $cardId,
                    'related_entity_name' => $newName,
                    'metadata_json'       => json_encode(['old_limit' => $oldLimit, 'new_limit' => $newLimit]),
                    'created_at'          => $now,
                ]);
            }

            $db->commit();
            $updated = $db->findOrFail('credit_cards', $cardId, $userId);
            Response::success($updated, 'Card updated');
        } catch (\Throwable $e) {
            $db->rollBack();
            throw $e;
        }
    }

    if ($request->isDelete()) {
        $db->softDelete('credit_cards', $cardId, $userId);
        $db->insert('activity_log', [
            'user_id'             => $userId,
            'event_type'          => 'CC_UPDATE',
            'description'         => "{$card['name']}: Card removed from tracker",
            'delta_paise'         => null,
            'related_entity_type' => 'credit_card',
            'related_entity_id'   => $cardId,
            'related_entity_name' => $card['name'],
            'metadata_json'       => json_encode(['action' => 'delete']),
            'created_at'          => $db->now(),
        ]);
        Response::success(['deleted' => true], 'Card removed');
    }

    Response::error('Method not allowed', 405);
} catch (\RuntimeException $e) {
    if ($e->getCode() === 404) Response::notFound($e->getMessage());
    error_log('[DHANFLOW] Card ID error: ' . $e->getMessage());
    Response::serverError();
} catch (\Throwable $e) {
    error_log('[DHANFLOW] Card ID error: ' . $e->getMessage());
    Response::serverError();
}
