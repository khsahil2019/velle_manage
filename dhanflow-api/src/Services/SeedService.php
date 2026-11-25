<?php
declare(strict_types=1);

/**
 * Seed Service — Populates a user's account with exact initial financial snapshot
 * All values in PAISE (₹ × 100) and GRAMS_X10000 (grams × 10000).
 */
class SeedService
{
    private Database $db;

    public function __construct(Database $db)
    {
        $this->db = $db;
    }

    public function resetUserToInitialSeed(string $userId, bool $clearActivity = true): void
    {
        $now = $this->db->now();
        $this->db->beginTransaction();
        try {
            // Clear existing user records in dependency order
            $this->db->execute("DELETE FROM card_transactions WHERE user_id = ?", [$userId]);
            $this->db->execute("DELETE FROM recovery_payments WHERE user_id = ?", [$userId]);
            $this->db->execute("DELETE FROM credit_cards WHERE user_id = ?", [$userId]);
            $this->db->execute("DELETE FROM loans WHERE user_id = ?", [$userId]);
            $this->db->execute("DELETE FROM personal_payables WHERE user_id = ?", [$userId]);
            $this->db->execute("DELETE FROM recoveries WHERE user_id = ?", [$userId]);
            $this->db->execute("DELETE FROM bullion_transactions WHERE user_id = ?", [$userId]);
            if ($clearActivity) {
                $this->db->execute("DELETE FROM activity_log WHERE user_id = ?", [$userId]);
            }

            // 1. 8 Credit Cards (Total Limit: ₹6,98,000.00 | Outstanding: ₹1,74,799.84)
            $cards = [
                ['SBI Card', 13900000, 2238217, 'Covered by Sakshi EMIs'],
                ['PNB Card', 5000000, 2554570, 'Active Pocket Debt'],
                ['ICICI Bank', 7500000, 5280952, 'Laptop EMI (Mar 2027)'],
                ['Axis Bank', 23000000, 21870377, 'Active Pocket Debt'],
                ['Roar Card', 5000000, 4975900, 'Quick Zero Target'],
                ['HDFC Swiggy', 3900000, 3900000, 'Cleared'],
                ['RBL Bank', 9500000, 9500000, 'Cleared'],
                ['Amazon Pay', 2000000, 2000000, 'Cleared'],
            ];
            foreach ($cards as $idx => [$name, $limit, $avl, $tag]) {
                $this->db->insert('credit_cards', [
                    'user_id' => $userId,
                    'name' => $name,
                    'total_limit' => $limit,
                    'available_limit' => $avl,
                    'category_tag' => $tag,
                    'display_order' => $idx,
                    'is_active' => 1,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }

            // 2. Loans (DMI Finance Loan: ₹7,463 × 7 = ₹52,241.00)
            $this->db->insert('loans', [
                'user_id' => $userId,
                'name' => 'DMI Finance Loan',
                'emi_amount' => 746300,
                'remaining_emis' => 7,
                'original_emis' => 7,
                'total_remaining' => 5224100,
                'note' => '',
                'is_active' => 1,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            // 3. Personal Payables (Arshi: ₹5,600.00)
            $this->db->insert('personal_payables', [
                'user_id' => $userId,
                'name' => 'Arshi',
                'amount' => 560000,
                'note' => 'Nadiya / Arshi',
                'is_settled' => 0,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            // 4. Recoveries (Kul Lena: ₹1,71,759.11)
            $recoveries = [
                ['Sakshi', 15847236, 'Old ₹30.5k + 6 EMIs ₹42k + Amazon 9 EMIs ₹85.9k'],
                ['Nripen', 683500, '₹1,945 × 3 + ₹1,000'],
                ['Faizu', 645175, 'Old ₹1,451.75 + ₹5,000 advance'],
            ];
            foreach ($recoveries as [$name, $amount, $note]) {
                $this->db->insert('recoveries', [
                    'user_id' => $userId,
                    'name' => $name,
                    'total_original' => $amount,
                    'total_pending' => $amount,
                    'note' => $note,
                    'is_settled' => 0,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }

            // 5. Gullak Gold & Silver Transactions (exact supplied figures in paise)
            $bullion = [
                // metal, grams_x10000, buy_rate_paise, pre_gst_paise, gst_paise, total_paid_paise, purchase_date
                ['gold', 2000, 1279728, 255945, 7679, 263624, '2026-11-20 14:48:00'],
                ['gold', 2000, 1279175, 255835, 7675, 263510, '2026-11-20 14:49:00'],
                ['gold', 1000, 1231952, 123196, 3696, 126892, '2026-11-25 21:51:00'],
                ['silver', 100005, 15974, 159748, 4792, 164540, '2026-11-20 14:44:00'],
                ['silver', 50000, 14593, 72965, 2190, 75155, '2026-11-25 22:00:00'],
            ];
            foreach ($bullion as [$metal, $gx, $rate, $pre, $gst, $paid, $date]) {
                $this->db->insert('bullion_transactions', [
                    'user_id' => $userId,
                    'metal' => $metal,
                    'grams_x10000' => $gx,
                    'buy_rate_paise' => $rate,
                    'pre_gst_paise' => $pre,
                    'gst_paise' => $gst,
                    'total_paid_paise' => $paid,
                    'purchase_date' => $date,
                    'platform' => 'Gullak',
                    'created_at' => $now,
                ]);
            }

            $this->db->insert('activity_log', [
                'user_id' => $userId,
                'event_type' => 'RESET',
                'description' => 'Initialized Trustvly account with baseline financial snapshot',
                'delta_paise' => null,
                'related_entity_type' => 'system',
                'related_entity_id' => $userId,
                'related_entity_name' => 'Seed Snapshot',
                'metadata_json' => json_encode(['schema_version' => '1.0.0']),
                'created_at' => $now,
            ]);

            $this->db->commit();
        } catch (\Throwable $e) {
            $this->db->rollBack();
            throw $e;
        }
    }
}
