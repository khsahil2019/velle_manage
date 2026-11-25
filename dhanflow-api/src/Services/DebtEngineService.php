<?php
declare(strict_types=1);

/**
 * Debt Freedom Engine Service
 * Simulates Snowball, Avalanche, and Custom payoff strategies in integer paise.
 */
class DebtEngineService {
    private Database $db;

    public function __construct(Database $db) {
        $this->db = $db;
    }

    public function simulatePayoff(
        string $userId,
        string $strategy = 'snowball',
        int $monthlyBudgetPaise = 2500000,
        array $aprOverridesBps = [], // ['item_id' => 3600] where 3600 bps = 36.00% APR
        array $customOrder = []
    ): array {
        $cards = $this->db->findAll('credit_cards', $userId, 'display_order ASC');
        $loans = $this->db->findAll('loans', $userId, 'created_at ASC');
        $payables = $this->db->execute(
            "SELECT * FROM personal_payables WHERE user_id = ? AND is_settled = 0",
            [$userId]
        )->fetchAll();

        $debts = [];
        foreach ($cards as $c) {
            $bal = max(0, (int)$c['total_limit'] - (int)$c['available_limit']);
            if ($bal <= 0) continue;
            $aprBps = (int)($aprOverridesBps[$c['id']] ?? 3600); // Default 36% APR for Indian CCs
            if (stripos((string)$c['category_tag'], 'emi') !== false) {
                $aprBps = (int)($aprOverridesBps[$c['id']] ?? 1500);
            }
            $minPay = max((int)round($bal * 0.05), min($bal, 50000)); // 5% or ₹500
            $debts[] = [
                'id'           => $c['id'],
                'name'         => $c['name'],
                'kind'         => 'credit_card',
                'balance'      => $bal,
                'apr_bps'      => $aprBps,
                'min_payment'  => $minPay,
            ];
        }
        foreach ($loans as $l) {
            $bal = (int)$l['total_remaining'];
            if ($bal <= 0) continue;
            $debts[] = [
                'id'          => $l['id'],
                'name'        => $l['name'],
                'kind'        => 'loan',
                'balance'     => $bal,
                'apr_bps'     => (int)($aprOverridesBps[$l['id']] ?? 1600),
                'min_payment' => min($bal, (int)$l['emi_amount']),
            ];
        }
        foreach ($payables as $p) {
            $bal = (int)$p['amount'];
            if ($bal <= 0) continue;
            $debts[] = [
                'id'          => $p['id'],
                'name'        => $p['name'],
                'kind'        => 'payable',
                'balance'     => $bal,
                'apr_bps'     => (int)($aprOverridesBps[$p['id']] ?? 0),
                'min_payment' => min($bal, 100000),
            ];
        }

        if (empty($debts)) {
            return [
                'strategy'              => $strategy,
                'total_debt_paise'      => 0,
                'months_to_freedom'     => 0,
                'debt_free_date'        => date('Y-m-d'),
                'total_interest_paise'  => 0,
                'interest_saved_paise'  => 0,
                'next_target'           => null,
                'order'                 => [],
            ];
        }

        $totalDebt = array_sum(array_column($debts, 'balance'));
        $minSum    = array_sum(array_column($debts, 'min_payment'));
        $budget    = max($monthlyBudgetPaise, $minSum);

        $ordered = $this->sortDebts($debts, $strategy, $customOrder);
        $sim     = $this->runSimulation($ordered, $budget);
        $minOnly = $this->runSimulation($ordered, $minSum);

        $freedomDate = date('Y-m-d', strtotime("+{$sim['months']} months"));

        return [
            'strategy'             => $strategy,
            'monthly_budget_paise' => $budget,
            'total_debt_paise'     => $totalDebt,
            'months_to_freedom'    => $sim['months'],
            'debt_free_date'       => $freedomDate,
            'total_interest_paise' => $sim['total_interest'],
            'interest_saved_paise' => max(0, $minOnly['total_interest'] - $sim['total_interest']),
            'next_target'          => $ordered[0]['name'] ?? null,
            'payoff_order'         => $sim['payoff_timeline'],
        ];
    }

    private function sortDebts(array $debts, string $strategy, array $customOrder): array {
        usort($debts, function ($a, $b) use ($strategy, $customOrder) {
            if ($strategy === 'avalanche') {
                return $b['apr_bps'] <=> $a['apr_bps'] ?: $a['balance'] <=> $b['balance'];
            }
            if ($strategy === 'custom' && !empty($customOrder)) {
                $ia = array_search($a['id'], $customOrder, true);
                $ib = array_search($b['id'], $customOrder, true);
                $ia = $ia === false ? PHP_INT_MAX : $ia;
                $ib = $ib === false ? PHP_INT_MAX : $ib;
                return $ia <=> $ib;
            }
            return $a['balance'] <=> $b['balance']; // snowball default
        });
        return $debts;
    }

    private function runSimulation(array $debts, int $budgetPaise): array {
        $items = $debts;
        $months = 0;
        $totalInterest = 0;
        $timeline = [];
        $maxMonths = 180;

        while ($months < $maxMonths) {
            $remainingSum = array_sum(array_column($items, 'balance'));
            if ($remainingSum <= 0) break;

            $months++;
            $availableBudget = $budgetPaise;

            // 1. Accrue monthly interest
            foreach ($items as &$d) {
                if ($d['balance'] <= 0) continue;
                $monthlyInterest = (int)round(($d['balance'] * $d['apr_bps']) / (10000 * 12));
                $d['balance'] += $monthlyInterest;
                $totalInterest += $monthlyInterest;
            }
            unset($d);

            // 2. Pay minimum on every active debt
            foreach ($items as &$d) {
                if ($d['balance'] <= 0) continue;
                $pay = min($d['balance'], $d['min_payment'], $availableBudget);
                $d['balance'] -= $pay;
                $availableBudget -= $pay;
                if ($d['balance'] === 0) {
                    $timeline[] = ['id' => $d['id'], 'name' => $d['name'], 'cleared_in_month' => $months];
                }
            }
            unset($d);

            // 3. Roll extra budget onto prioritized target(s)
            if ($availableBudget > 0) {
                foreach ($items as &$d) {
                    if ($d['balance'] <= 0 || $availableBudget <= 0) continue;
                    $extra = min($d['balance'], $availableBudget);
                    $d['balance'] -= $extra;
                    $availableBudget -= $extra;
                    if ($d['balance'] === 0) {
                        $timeline[] = ['id' => $d['id'], 'name' => $d['name'], 'cleared_in_month' => $months];
                    }
                }
                unset($d);
            }
        }

        return [
            'months'          => $months,
            'total_interest'  => $totalInterest,
            'payoff_timeline' => $timeline,
        ];
    }
}
