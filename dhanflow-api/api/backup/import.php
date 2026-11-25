<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId = Auth::requireAuth();
    $request = new Request();
    $db = Database::getInstance();

    if (!$request->isPost())
        Response::error('Method not allowed', 405);

    $cards = $request->input('credit_cards');
    $loans = $request->input('loans');
    $payables = $request->input('personal_payables');
    $recoveries = $request->input('recoveries');
    $bullion = $request->input('bullion_transactions');
    $personalAssets = $request->input('personal_assets');
    $settings = $request->input('user_settings');
    $activity = $request->input('activity_log');
    $silent = (bool) ($request->input('silent') ?? false);
    $version = (string) ($request->input('schema_version') ?? '');

    if ($version === '' || !is_array($cards) || !is_array($bullion)) {
        Response::error('Invalid Trustvly backup schema: missing schema_version, credit_cards, or bullion_transactions', 422);
    }

    $now = $db->now();
    $db->beginTransaction();
    try {
        $db->execute("DELETE FROM card_transactions WHERE user_id = ?", [$userId]);
        $db->execute("DELETE FROM recovery_payments WHERE user_id = ?", [$userId]);
        $db->execute("DELETE FROM credit_cards WHERE user_id = ?", [$userId]);
        $db->execute("DELETE FROM loans WHERE user_id = ?", [$userId]);
        $db->execute("DELETE FROM personal_payables WHERE user_id = ?", [$userId]);
        $db->execute("DELETE FROM recoveries WHERE user_id = ?", [$userId]);
        $db->execute("DELETE FROM bullion_transactions WHERE user_id = ?", [$userId]);
        $db->execute("DELETE FROM personal_assets WHERE user_id = ?", [$userId]);

        foreach ($cards as $idx => $c) {
            $db->insert('credit_cards', [
                'id' => $c['id'] ?? $db->generateUUID(),
                'user_id' => $userId,
                'name' => (string) $c['name'],
                'total_limit' => (int) $c['total_limit'],
                'available_limit' => (int) $c['available_limit'],
                'category_tag' => (string) ($c['category_tag'] ?? 'Active Pocket Debt'),
                'display_order' => (int) ($c['display_order'] ?? $idx),
                'is_active' => (int) ($c['is_active'] ?? 1),
                'apr_bps' => (int) ($c['apr_bps'] ?? 3600),
                'created_at' => $db->normalizeDateTime($c['created_at'] ?? null),
                'updated_at' => $now,
            ]);
        }

        foreach ((array) $loans as $l) {
            $db->insert('loans', [
                'id' => $l['id'] ?? $db->generateUUID(),
                'user_id' => $userId,
                'name' => (string) $l['name'],
                'emi_amount' => (int) $l['emi_amount'],
                'remaining_emis' => (int) $l['remaining_emis'],
                'original_emis' => (int) ($l['original_emis'] ?? $l['remaining_emis']),
                'total_remaining' => (int) $l['total_remaining'],
                'note' => (string) ($l['note'] ?? ''),
                'is_active' => (int) ($l['is_active'] ?? 1),
                'apr_bps' => (int) ($l['apr_bps'] ?? 1600),
                'created_at' => $db->normalizeDateTime($l['created_at'] ?? null),
                'updated_at' => $now,
            ]);
        }

        foreach ((array) $payables as $p) {
            $db->insert('personal_payables', [
                'id' => $p['id'] ?? $db->generateUUID(),
                'user_id' => $userId,
                'name' => (string) $p['name'],
                'amount' => (int) $p['amount'],
                'note' => (string) ($p['note'] ?? ''),
                'is_settled' => (int) ($p['is_settled'] ?? 0),
                'created_at' => $db->normalizeDateTime($p['created_at'] ?? null),
                'updated_at' => $now,
            ]);
        }

        foreach ((array) $recoveries as $r) {
            $recId = $db->insert('recoveries', [
                'id' => $r['id'] ?? $db->generateUUID(),
                'user_id' => $userId,
                'name' => (string) $r['name'],
                'total_original' => (int) ($r['total_original'] ?? $r['total_pending']),
                'total_pending' => (int) $r['total_pending'],
                'note' => (string) ($r['note'] ?? ''),
                'is_settled' => (int) ($r['is_settled'] ?? 0),
                'created_at' => $db->normalizeDateTime($r['created_at'] ?? null),
                'updated_at' => $now,
            ]);
            foreach ((array) ($r['payments'] ?? []) as $pay) {
                $db->insert('recovery_payments', [
                    'id' => $pay['id'] ?? $db->generateUUID(),
                    'recovery_id' => $recId,
                    'user_id' => $userId,
                    'amount' => (int) $pay['amount'],
                    'applied_to_card' => $pay['applied_to_card'] ?? null,
                    'note' => (string) ($pay['note'] ?? ''),
                    'payment_date' => $db->normalizeDateTime($pay['payment_date'] ?? null),
                    'created_at' => $db->normalizeDateTime($pay['created_at'] ?? null),
                ]);
            }
        }

        foreach ($bullion as $b) {
            $db->insert('bullion_transactions', [
                'id' => $b['id'] ?? $db->generateUUID(),
                'user_id' => $userId,
                'metal' => (string) $b['metal'],
                'grams_x10000' => (int) $b['grams_x10000'],
                'buy_rate_paise' => (int) $b['buy_rate_paise'],
                'pre_gst_paise' => (int) $b['pre_gst_paise'],
                'gst_paise' => (int) $b['gst_paise'],
                'total_paid_paise' => (int) $b['total_paid_paise'],
                'purchase_date' => $db->normalizeDateTime($b['purchase_date'] ?? null),
                'platform' => (string) ($b['platform'] ?? 'Vault'),
                'created_at' => $db->normalizeDateTime($b['created_at'] ?? null),
            ]);
        }

        foreach ((array) $personalAssets as $pa) {
            $db->insert('personal_assets', [
                'id' => $pa['id'] ?? $db->generateUUID(),
                'user_id' => $userId,
                'title' => (string) ($pa['title'] ?? 'Asset'),
                'category' => (string) ($pa['category'] ?? 'other'),
                'quantity_label' => (string) ($pa['quantity_label'] ?? '1 Unit'),
                'purchase_value_paise' => (int) ($pa['purchase_value_paise'] ?? 0),
                'current_value_paise' => (int) ($pa['current_value_paise'] ?? 0),
                'note' => (string) ($pa['note'] ?? ''),
                'acquired_date' => $db->normalizeDateTime($pa['acquired_date'] ?? null),
                'created_at' => $db->normalizeDateTime($pa['created_at'] ?? null),
            ]);
        }

        if (is_array($settings)) {
            $db->execute("DELETE FROM user_settings WHERE user_id = ?", [$userId]);
            $db->insert('user_settings', [
                'user_id' => $userId,
                'gold_current_sell_paise' => isset($settings['gold_current_sell_paise']) ? (int) $settings['gold_current_sell_paise'] : null,
                'silver_current_sell_paise' => isset($settings['silver_current_sell_paise']) ? (int) $settings['silver_current_sell_paise'] : null,
                'debt_payoff_strategy' => (string) ($settings['debt_payoff_strategy'] ?? 'snowball'),
                'monthly_payment_capacity' => (int) ($settings['monthly_payment_capacity'] ?? 2500000),
                'currency' => 'INR',
                'updated_at' => $now,
            ], false);
        }

        if (is_array($activity) && $silent) {
            $db->execute("DELETE FROM activity_log WHERE user_id = ?", [$userId]);
            foreach (array_slice($activity, 0, 200) as $a) {
                $db->insert('activity_log', [
                    'id' => $a['id'] ?? $db->generateUUID(),
                    'user_id' => $userId,
                    'event_type' => (string) ($a['event_type'] ?? 'SYSTEM'),
                    'description' => (string) ($a['description'] ?? ''),
                    'delta_paise' => isset($a['delta_paise']) ? (int) $a['delta_paise'] : null,
                    'related_entity_id' => $a['related_entity_id'] ?? null,
                    'related_entity_name' => $a['related_entity_name'] ?? null,
                    'is_reversed' => !empty($a['is_reversed']) ? 1 : 0,
                    'created_at' => $db->normalizeDateTime($a['created_at'] ?? null),
                ]);
            }
        } elseif (!$silent) {
            $db->insert('activity_log', [
                'user_id' => $userId,
                'event_type' => 'IMPORT',
                'description' => "Synced/imported backup snapshot (schema v{$version})",
                'created_at' => $now,
            ]);
        }

        $db->commit();
        Response::success(['synced_at' => date('c')], 'Cloud storage synced');
    } catch (\Throwable $e) {
        $db->rollBack();
        throw $e;
    }
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Cloud sync failed');
}
