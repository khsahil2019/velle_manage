<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    if ($request->isGet()) {
        $cards = $db->findAll('credit_cards', $userId, 'display_order ASC, created_at ASC');
        $cards = array_map(function ($card) {
            $limit = (int)$card['total_limit'];
            $avl   = (int)$card['available_limit'];
            $out   = max(0, $limit - $avl);
            $card['total_limit']     = $limit;
            $card['available_limit'] = $avl;
            $card['outstanding']     = $out;
            $card['utilization_pct'] = $limit > 0 ? round(($out / $limit) * 100, 2) : 0.0;
            $card['is_cleared']      = $out === 0;
            return $card;
        }, $cards);
        Response::success($cards);
    }

    if ($request->isPost()) {
        $request
            ->requireFields(['name', 'total_limit', 'available_limit'])
            ->requirePositiveInt('total_limit')
            ->requireNonNegativeInt('available_limit')
            ->validate();

        $totalLimit     = (int)$request->input('total_limit');
        $availableLimit = (int)$request->input('available_limit');

        if ($availableLimit > $totalLimit) {
            Response::error('Available limit cannot exceed total limit', 422);
        }

        $cardCount = (int)$db->execute(
            "SELECT COUNT(*) FROM credit_cards WHERE user_id = ? AND is_active = 1",
            [$userId]
        )->fetchColumn();

        $now    = $db->now();
        $cardId = $db->insert('credit_cards', [
            'user_id'         => $userId,
            'name'            => trim((string)$request->input('name')),
            'total_limit'     => $totalLimit,
            'available_limit' => $availableLimit,
            'category_tag'    => trim((string)($request->input('category_tag') ?? 'Active Pocket Debt')),
            'display_order'   => $cardCount,
            'is_active'       => 1,
            'created_at'      => $now,
            'updated_at'      => $now,
        ]);

        $db->insert('activity_log', [
            'user_id'             => $userId,
            'event_type'          => 'CC_UPDATE',
            'description'         => "Card added: {$request->input('name')} (limit ₹" . number_format($totalLimit / 100, 2) . ")",
            'delta_paise'         => null,
            'related_entity_type' => 'credit_card',
            'related_entity_id'   => $cardId,
            'related_entity_name' => trim((string)$request->input('name')),
            'metadata_json'       => json_encode(['action' => 'add']),
            'created_at'          => $now,
        ]);

        $newCard = $db->findOrFail('credit_cards', $cardId, $userId);
        Response::success($newCard, 'Card added', 201);
    }

    Response::error('Method not allowed', 405);
} catch (\Throwable $e) {
    error_log('[DHANFLOW] Cards error: ' . $e->getMessage());
    Response::serverError();
}
