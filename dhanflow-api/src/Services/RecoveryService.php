<?php
declare(strict_types=1);

/**
 * Recovery Service — Atomic recovery-to-debt operations & EMI updates
 */
class RecoveryService {
    private Database $db;

    public function __construct(Database $db) {
        $this->db = $db;
    }

    public function recordPayment(
        string  $recoveryId,
        int     $amountPaise,
        string  $note,
        ?string $linkedCardId,
        string  $userId
    ): array {
        if ($amountPaise <= 0) {
            throw new \InvalidArgumentException('Amount must be greater than 0');
        }

        $recovery     = $this->db->findOrFail('recoveries', $recoveryId, $userId);
        $pendingPaise = (int)$recovery['total_pending'];

        if ($amountPaise > $pendingPaise) {
            throw new \InvalidArgumentException(
                "Amount (₹" . number_format($amountPaise / 100, 2) . ") " .
                "exceeds pending balance (₹" . number_format($pendingPaise / 100, 2) . ")"
            );
        }

        $now = $this->db->now();
        $this->db->beginTransaction();
        try {
            $newPending   = $pendingPaise - $amountPaise;
            $isNowSettled = $newPending <= 0 ? 1 : 0;

            $this->db->execute(
                "UPDATE recoveries
                 SET total_pending = ?, is_settled = ?, updated_at = ?
                 WHERE id = ? AND user_id = ?",
                [$newPending, $isNowSettled, $now, $recoveryId, $userId]
            );

            $paymentId = $this->db->insert('recovery_payments', [
                'recovery_id'     => $recoveryId,
                'user_id'         => $userId,
                'amount'          => $amountPaise,
                'applied_to_card' => $linkedCardId,
                'note'            => $note,
                'payment_date'    => $now,
                'created_at'      => $now,
            ]);

            $cardName = null;
            if ($linkedCardId !== null && $linkedCardId !== '') {
                $card       = $this->db->findOrFail('credit_cards', $linkedCardId, $userId);
                $totalLimit = (int)$card['total_limit'];
                $currentAvl = (int)$card['available_limit'];
                $newAvl     = min($currentAvl + $amountPaise, $totalLimit);
                $cardName   = $card['name'];

                $this->db->execute(
                    "UPDATE credit_cards SET available_limit = ?, updated_at = ?
                     WHERE id = ? AND user_id = ?",
                    [$newAvl, $now, $linkedCardId, $userId]
                );

                $this->db->insert('card_transactions', [
                    'card_id'    => $linkedCardId,
                    'user_id'    => $userId,
                    'type'       => 'PAYMENT',
                    'amount'     => $amountPaise,
                    'note'       => "Recovery from {$recovery['name']}",
                    'txn_date'   => $now,
                    'created_at' => $now,
                ]);
            }

            $desc = "Recovery: {$recovery['name']} paid ₹" . number_format($amountPaise / 100, 2);
            if ($cardName) {
                $desc .= " → applied to {$cardName}";
            }
            if ($isNowSettled) {
                $desc .= " [FULLY SETTLED]";
            }

            $this->db->insert('activity_log', [
                'user_id'             => $userId,
                'event_type'          => $cardName ? 'RECOVERY_LINKED' : 'RECOVERY_RECEIVED',
                'description'         => $desc,
                'delta_paise'         => $amountPaise,
                'related_entity_type' => 'recovery',
                'related_entity_id'   => $recoveryId,
                'related_entity_name' => $recovery['name'],
                'metadata_json'       => json_encode([
                    'payment_id'       => $paymentId,
                    'linked_card_id'   => $linkedCardId,
                    'linked_card_name' => $cardName,
                    'is_now_settled'   => (bool)$isNowSettled,
                ]),
                'created_at'          => $now,
            ]);

            $this->db->commit();

            return [
                'payment_id'        => $paymentId,
                'recovery_id'       => $recoveryId,
                'amount_paise'      => $amountPaise,
                'new_pending_paise' => $newPending,
                'is_settled'        => (bool)$isNowSettled,
                'linked_card_id'    => $linkedCardId,
                'linked_card_name'  => $cardName,
            ];
        } catch (\Throwable $e) {
            $this->db->rollBack();
            throw $e;
        }
    }

    public function markEMIPaid(string $loanId, string $userId): array {
        $loan = $this->db->findOrFail('loans', $loanId, $userId);

        if ((int)$loan['remaining_emis'] <= 0) {
            throw new \InvalidArgumentException('No remaining EMIs for this loan');
        }

        $now = $this->db->now();
        $this->db->beginTransaction();
        try {
            $remainingEmis  = (int)$loan['remaining_emis'];
            $emiAmount      = (int)$loan['emi_amount'];
            $totalRemaining = (int)$loan['total_remaining'];

            $isLastEMI         = $remainingEmis === 1;
            $actualPayment     = $isLastEMI ? $totalRemaining : min($emiAmount, $totalRemaining);
            $newTotalRemaining = max(0, $totalRemaining - $actualPayment);
            $newRemainingEmis  = $remainingEmis - 1;
            $isCleared         = $newRemainingEmis <= 0 || $newTotalRemaining <= 0;

            $this->db->execute(
                "UPDATE loans SET remaining_emis = ?, total_remaining = ?,
                 is_active = ?, updated_at = ?
                 WHERE id = ? AND user_id = ?",
                [$newRemainingEmis, $newTotalRemaining, $isCleared ? 0 : 1, $now, $loanId, $userId]
            );

            $desc = "EMI paid: {$loan['name']} — ₹" . number_format($actualPayment / 100, 2);
            $desc .= $isCleared ? " [LOAN CLEARED!]" : " ({$newRemainingEmis} EMIs remaining)";

            $this->db->insert('activity_log', [
                'user_id'             => $userId,
                'event_type'          => 'LOAN_EMI',
                'description'         => $desc,
                'delta_paise'         => -$actualPayment,
                'related_entity_type' => 'loan',
                'related_entity_id'   => $loanId,
                'related_entity_name' => $loan['name'],
                'metadata_json'       => json_encode([
                    'actual_payment_paise' => $actualPayment,
                    'is_last_emi'          => $isLastEMI,
                    'is_cleared'           => $isCleared,
                ]),
                'created_at'          => $now,
            ]);

            $this->db->commit();

            return [
                'loan_id'              => $loanId,
                'actual_payment_paise' => $actualPayment,
                'new_remaining_emis'   => $newRemainingEmis,
                'new_total_remaining'  => $newTotalRemaining,
                'is_cleared'           => $isCleared,
            ];
        } catch (\Throwable $e) {
            $this->db->rollBack();
            throw $e;
        }
    }
}
