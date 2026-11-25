<?php
declare(strict_types=1);

/**
 * Snapshot builder & deterministic SHA-256 fingerprint for zero-delay real-time sync.
 */
class SyncService {
    public static function buildSnapshot(Database $db, string $userId): array {
        $cards      = $db->execute("SELECT * FROM credit_cards WHERE user_id = ? AND is_active = 1 ORDER BY display_order ASC", [$userId])->fetchAll();
        $loans      = $db->execute("SELECT * FROM loans WHERE user_id = ? AND is_active = 1 ORDER BY created_at ASC", [$userId])->fetchAll();
        $payables   = $db->execute("SELECT * FROM personal_payables WHERE user_id = ? AND is_settled = 0 ORDER BY created_at ASC", [$userId])->fetchAll();
        $recoveries = $db->execute("SELECT * FROM recoveries WHERE user_id = ? ORDER BY is_settled ASC, total_pending DESC", [$userId])->fetchAll();
        $payments   = $db->execute("SELECT * FROM recovery_payments WHERE user_id = ? ORDER BY payment_date DESC", [$userId])->fetchAll();
        $bullion    = $db->execute("SELECT * FROM bullion_transactions WHERE user_id = ? ORDER BY purchase_date DESC", [$userId])->fetchAll();
        $assets     = $db->execute("SELECT * FROM personal_assets WHERE user_id = ? ORDER BY acquired_date DESC", [$userId])->fetchAll();
        $settings   = $db->execute("SELECT * FROM user_settings WHERE user_id = ?", [$userId])->fetch() ?: null;
        $activity   = $db->execute("SELECT * FROM activity_log WHERE user_id = ? ORDER BY created_at DESC LIMIT 200", [$userId])->fetchAll();

        foreach ($cards as &$c) {
            $c['total_limit']     = (int)($c['total_limit'] ?? 0);
            $c['available_limit'] = (int)($c['available_limit'] ?? 0);
            $c['display_order']   = (int)($c['display_order'] ?? 0);
            $c['is_active']       = (int)($c['is_active'] ?? 1);
            $c['apr_bps']         = (int)($c['apr_bps'] ?? 3600);
        }
        unset($c);

        foreach ($loans as &$l) {
            $l['emi_amount']      = (int)($l['emi_amount'] ?? 0);
            $l['remaining_emis']  = (int)($l['remaining_emis'] ?? 0);
            $l['original_emis']   = (int)($l['original_emis'] ?? 0);
            $l['total_remaining'] = (int)($l['total_remaining'] ?? 0);
            $l['is_active']       = (int)($l['is_active'] ?? 1);
            $l['apr_bps']         = (int)($l['apr_bps'] ?? 1600);
        }
        unset($l);

        foreach ($payables as &$p) {
            $p['amount']     = (int)($p['amount'] ?? 0);
            $p['is_settled'] = (int)($p['is_settled'] ?? 0);
        }
        unset($p);

        $paymentsByRec = [];
        foreach ($payments as $pay) {
            $pay['amount'] = (int)($pay['amount'] ?? 0);
            $paymentsByRec[$pay['recovery_id']][] = $pay;
        }
        foreach ($recoveries as &$rec) {
            $rec['total_original'] = (int)($rec['total_original'] ?? 0);
            $rec['total_pending']  = (int)($rec['total_pending'] ?? 0);
            $rec['is_settled']     = (int)($rec['is_settled'] ?? 0);
            $rec['payments']       = $paymentsByRec[$rec['id']] ?? [];
        }
        unset($rec);

        foreach ($bullion as &$b) {
            $b['grams_x10000']     = (int)($b['grams_x10000'] ?? 0);
            $b['buy_rate_paise']   = (int)($b['buy_rate_paise'] ?? 0);
            $b['pre_gst_paise']    = (int)($b['pre_gst_paise'] ?? 0);
            $b['gst_paise']        = (int)($b['gst_paise'] ?? 0);
            $b['total_paid_paise'] = (int)($b['total_paid_paise'] ?? 0);
        }
        unset($b);

        foreach ($assets as &$pa) {
            $pa['purchase_value_paise'] = (int)($pa['purchase_value_paise'] ?? 0);
            $pa['current_value_paise']  = (int)($pa['current_value_paise'] ?? 0);
        }
        unset($pa);

        if (is_array($settings)) {
            $settings['gold_current_sell_paise']   = isset($settings['gold_current_sell_paise']) ? (int)$settings['gold_current_sell_paise'] : null;
            $settings['silver_current_sell_paise'] = isset($settings['silver_current_sell_paise']) ? (int)$settings['silver_current_sell_paise'] : null;
            $settings['monthly_payment_capacity']  = (int)($settings['monthly_payment_capacity'] ?? 2500000);
        }

        foreach ($activity as &$act) {
            $act['delta_paise'] = isset($act['delta_paise']) ? (int)$act['delta_paise'] : null;
            $act['is_reversed'] = ((int)($act['is_reversed'] ?? 0)) === 1;
        }
        unset($act);

        return [
            'schema_version'       => '1.0.0',
            'credit_cards'         => $cards,
            'loans'                => $loans,
            'personal_payables'    => $payables,
            'recoveries'           => $recoveries,
            'bullion_transactions' => $bullion,
            'personal_assets'      => $assets,
            'user_settings'        => $settings,
            'activity_log'         => $activity,
        ];
    }

    public static function computeHash(array $snapshot): string {
        return hash(
            'sha256',
            (string)json_encode([
                'credit_cards'         => $snapshot['credit_cards'] ?? [],
                'loans'                => $snapshot['loans'] ?? [],
                'personal_payables'    => $snapshot['personal_payables'] ?? [],
                'recoveries'           => $snapshot['recoveries'] ?? [],
                'bullion_transactions' => $snapshot['bullion_transactions'] ?? [],
                'personal_assets'      => $snapshot['personal_assets'] ?? [],
                'user_settings'        => $snapshot['user_settings'] ?? null,
                'activity_log'         => $snapshot['activity_log'] ?? [],
            ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
        );
    }
}
