<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId = Auth::requireAuth();
    $db     = Database::getInstance();

    $cards      = $db->execute("SELECT * FROM credit_cards WHERE user_id = ? AND is_active = 1 ORDER BY display_order ASC", [$userId])->fetchAll();
    $loans      = $db->execute("SELECT * FROM loans WHERE user_id = ? AND is_active = 1 ORDER BY created_at ASC", [$userId])->fetchAll();
    $payables   = $db->execute("SELECT * FROM personal_payables WHERE user_id = ? AND is_settled = 0 ORDER BY created_at ASC", [$userId])->fetchAll();
    $recoveries = $db->execute("SELECT * FROM recoveries WHERE user_id = ? ORDER BY is_settled ASC, total_pending DESC", [$userId])->fetchAll();
    $payments   = $db->execute("SELECT * FROM recovery_payments WHERE user_id = ? ORDER BY payment_date DESC", [$userId])->fetchAll();
    $bullion    = $db->execute("SELECT * FROM bullion_transactions WHERE user_id = ? ORDER BY purchase_date DESC", [$userId])->fetchAll();
    $settings   = $db->execute("SELECT * FROM user_settings WHERE user_id = ?", [$userId])->fetch() ?: null;
    $activity   = $db->execute("SELECT * FROM activity_log WHERE user_id = ? ORDER BY created_at DESC LIMIT 200", [$userId])->fetchAll();

    // Nest recovery payments directly inside each recovery record to match Flutter RecoveryModel.fromJson
    $paymentsByRec = [];
    foreach ($payments as $pay) {
        $paymentsByRec[$pay['recovery_id']][] = $pay;
    }
    foreach ($recoveries as &$rec) {
        $rec['payments'] = $paymentsByRec[$rec['id']] ?? [];
    }
    unset($rec);

    // Ensure boolean/int types match Flutter models cleanly
    foreach ($activity as &$act) {
        $act['is_reversed'] = ((int)($act['is_reversed'] ?? 0)) === 1;
    }
    unset($act);

    $snapshot = [
        'schema_version'       => '1.0.0',
        'last_updated'         => date('c'),
        'exported_at'          => date('c'),
        'credit_cards'         => $cards,
        'loans'                => $loans,
        'personal_payables'    => $payables,
        'recoveries'           => $recoveries,
        'bullion_transactions' => $bullion,
        'user_settings'        => $settings,
        'activity_log'         => $activity,
    ];

    Response::success($snapshot);
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Backup export failed');
}
