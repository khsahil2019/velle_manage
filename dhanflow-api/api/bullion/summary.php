<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();
    $kpi     = new KPIService($db);

    if ($request->isPost() || $request->isPut()) {
        // Save manual current sell price for P/L simulator
        $goldSell   = $request->input('gold_current_sell_paise');
        $silverSell = $request->input('silver_current_sell_paise');

        $existing = $db->execute("SELECT user_id FROM user_settings WHERE user_id = ?", [$userId])->fetch();
        $now      = $db->now();

        if (!$existing) {
            $db->insert('user_settings', [
                'user_id'                   => $userId,
                'gold_current_sell_paise'   => $goldSell !== null ? (int)$goldSell : null,
                'silver_current_sell_paise' => $silverSell !== null ? (int)$silverSell : null,
                'updated_at'                => $now,
            ], false);
        } else {
            $sets   = ['updated_at = ?'];
            $params = [$now];
            if ($request->input('gold_current_sell_paise') !== null || array_key_exists('gold_current_sell_paise', json_decode(file_get_contents('php://input') ?: '{}', true) ?? [])) {
                $sets[]   = 'gold_current_sell_paise = ?';
                $params[] = $goldSell !== null ? (int)$goldSell : null;
            }
            if ($request->input('silver_current_sell_paise') !== null || array_key_exists('silver_current_sell_paise', json_decode(file_get_contents('php://input') ?: '{}', true) ?? [])) {
                $sets[]   = 'silver_current_sell_paise = ?';
                $params[] = $silverSell !== null ? (int)$silverSell : null;
            }
            $params[] = $userId;
            $db->execute("UPDATE user_settings SET " . implode(', ', $sets) . " WHERE user_id = ?", $params);
        }
    }

    $txns = $db->execute(
        "SELECT * FROM bullion_transactions WHERE user_id = ? ORDER BY purchase_date DESC",
        [$userId]
    )->fetchAll();
    $settings = $db->execute("SELECT * FROM user_settings WHERE user_id = ?", [$userId])->fetch() ?: [];

    Response::success([
        'gold_stats'   => $kpi->computeBullionStats($txns, 'gold', $settings),
        'silver_stats' => $kpi->computeBullionStats($txns, 'silver', $settings),
    ]);
} catch (\Throwable $e) {
    error_log('[DHANFLOW] Bullion summary error: ' . $e->getMessage());
    Response::serverError();
}
