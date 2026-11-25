<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId = Auth::requireAuth();
    $db     = Database::getInstance();
    $kpi    = new KPIService($db);

    $txns = $db->execute(
        "SELECT * FROM bullion_transactions WHERE user_id = ? ORDER BY purchase_date DESC",
        [$userId]
    )->fetchAll();

    $settings = $db->execute(
        "SELECT * FROM user_settings WHERE user_id = ?",
        [$userId]
    )->fetch() ?: [];

    Response::success([
        'gold_stats'   => $kpi->computeBullionStats($txns, 'gold', $settings),
        'silver_stats' => $kpi->computeBullionStats($txns, 'silver', $settings),
        'transactions' => $txns,
    ]);
} catch (\Throwable $e) {
    error_log('[DHANFLOW] Bullion index error: ' . $e->getMessage());
    Response::serverError();
}
