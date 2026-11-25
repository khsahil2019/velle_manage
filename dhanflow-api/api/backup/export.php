<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId = Auth::requireAuth();
    $db     = Database::getInstance();

    $snapshot = [
        'schema_version'       => '1.0.0',
        'exported_at'          => date('c'),
        'credit_cards'         => $db->execute("SELECT * FROM credit_cards WHERE user_id = ? AND is_active = 1 ORDER BY display_order ASC", [$userId])->fetchAll(),
        'card_transactions'    => $db->execute("SELECT * FROM card_transactions WHERE user_id = ? ORDER BY txn_date DESC", [$userId])->fetchAll(),
        'loans'                => $db->execute("SELECT * FROM loans WHERE user_id = ? AND is_active = 1", [$userId])->fetchAll(),
        'personal_payables'    => $db->execute("SELECT * FROM personal_payables WHERE user_id = ? AND is_settled = 0", [$userId])->fetchAll(),
        'recoveries'           => $db->execute("SELECT * FROM recoveries WHERE user_id = ?", [$userId])->fetchAll(),
        'recovery_payments'    => $db->execute("SELECT * FROM recovery_payments WHERE user_id = ?", [$userId])->fetchAll(),
        'bullion_transactions' => $db->execute("SELECT * FROM bullion_transactions WHERE user_id = ? ORDER BY purchase_date DESC", [$userId])->fetchAll(),
        'user_settings'        => $db->execute("SELECT * FROM user_settings WHERE user_id = ?", [$userId])->fetch() ?: null,
        'activity_log'         => $db->execute("SELECT * FROM activity_log WHERE user_id = ? ORDER BY created_at DESC LIMIT 200", [$userId])->fetchAll(),
    ];

    $db->insert('activity_log', [
        'user_id'     => $userId,
        'event_type'  => 'EXPORT',
        'description' => 'Exported JSON backup snapshot',
        'created_at'  => $db->now(),
    ]);

    Response::success($snapshot);
} catch (\Throwable $e) {
    error_log('[DHANFLOW] Export error: ' . $e->getMessage());
    Response::serverError();
}
