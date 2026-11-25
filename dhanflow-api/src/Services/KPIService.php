<?php
declare(strict_types=1);

/**
 * KPI Service — Server-side financial calculations + Financial Health Score + Smart Alerts
 *
 * CRITICAL RULES:
 * - All monetary amounts in PAISE (integer).
 * - Four distinct concepts never conflated:
 *   1. Gross Liabilities (Kul Dena)
 *   2. Receivables (Kul Lena)
 *   3. Bullion Cost Basis (Pre-GST purchase value)
 *   4. Bullion Liquidation Value (optional Sell Price × grams)
 */
class KPIService {
    private Database $db;

    public function __construct(Database $db) {
        $this->db = $db;
    }

    public function getFullSnapshot(string $userId): array {
        $cards = $this->db->findAll('credit_cards', $userId, 'display_order ASC, created_at ASC');
        $loans = $this->db->findAll('loans', $userId, 'created_at ASC');
        $payables = $this->db->execute(
            "SELECT * FROM personal_payables WHERE user_id = ? AND is_settled = 0 ORDER BY created_at ASC",
            [$userId]
        )->fetchAll();
        $recoveries = $this->db->execute(
            "SELECT * FROM recoveries WHERE user_id = ? AND is_settled = 0 ORDER BY total_pending DESC",
            [$userId]
        )->fetchAll();
        $bullion = $this->db->execute(
            "SELECT * FROM bullion_transactions WHERE user_id = ? ORDER BY purchase_date DESC",
            [$userId]
        )->fetchAll();
        $settings = $this->db->execute(
            "SELECT * FROM user_settings WHERE user_id = ?",
            [$userId]
        )->fetch() ?: [];

        $totalCCOutstanding = 0;
        $totalCCLimit = 0;
        $clearedCount = 0;
        $pocketDebt = 0;

        foreach ($cards as $card) {
            $limit       = (int)$card['total_limit'];
            $avl         = (int)$card['available_limit'];
            $outstanding = max(0, $limit - $avl);
            $totalCCLimit += $limit;
            $totalCCOutstanding += $outstanding;
            if ($outstanding === 0) {
                $clearedCount++;
            }
            $tag = (string)($card['category_tag'] ?? '');
            $isCoveredByRecovery = stripos($tag, 'covered by') !== false
                || stripos($tag, 'sakshi') !== false
                || strcasecmp((string)$card['name'], 'SBI Card') === 0;
            if (!$isCoveredByRecovery) {
                $pocketDebt += $outstanding;
            }
        }

        $totalLoanRemaining = 0;
        foreach ($loans as $loan) {
            $totalLoanRemaining += (int)$loan['total_remaining'];
        }

        $totalPayables = array_sum(array_map('intval', array_column($payables, 'amount')));
        $kulDena       = $totalCCOutstanding + $totalLoanRemaining + $totalPayables;
        $kulLena       = array_sum(array_map('intval', array_column($recoveries, 'total_pending')));
        $asalNetDebt   = $kulDena - $kulLena;

        $goldStats   = $this->computeBullionStats($bullion, 'gold', $settings);
        $silverStats = $this->computeBullionStats($bullion, 'silver', $settings);
        $gullakAsset = $goldStats['pre_gst_asset_paise'] + $silverStats['pre_gst_asset_paise'];

        $trueNetLiability = $asalNetDebt - $gullakAsset;

        $healthScore = $this->computeHealthScore($cards, $loans, $recoveries, $kulDena, $gullakAsset, $totalCCLimit, $totalCCOutstanding);
        $alerts      = $this->computeSmartAlerts($cards, $loans, $recoveries, $goldStats, $silverStats);

        return [
            'total_cc_outstanding_paise' => $totalCCOutstanding,
            'total_cc_limit_paise'       => $totalCCLimit,
            'total_loan_remaining_paise' => $totalLoanRemaining,
            'total_payables_paise'       => $totalPayables,
            'kul_dena_paise'             => $kulDena,
            'kul_lena_paise'             => $kulLena,
            'asal_net_debt_paise'        => $asalNetDebt,
            'gullak_asset_paise'         => $gullakAsset,
            'true_net_liability_paise'   => $trueNetLiability,
            'pocket_debt_paise'          => $pocketDebt,
            'total_cards_count'          => count($cards),
            'cleared_cards_count'        => $clearedCount,
            'gold_stats'                 => $goldStats,
            'silver_stats'               => $silverStats,
            'health_score'               => $healthScore,
            'smart_alerts'               => $alerts,
        ];
    }

    public function computeBullionStats(array $allTxns, string $metal, array $settings): array {
        $txns = array_values(array_filter($allTxns, fn($t) => $t['metal'] === $metal));

        if (empty($txns)) {
            return [
                'metal'                    => $metal,
                'total_grams_x10000'       => 0,
                'weighted_avg_rate_paise'  => 0,
                'effective_cost_paise'     => 0,
                'pre_gst_asset_paise'      => 0,
                'total_cash_paid_paise'    => 0,
                'total_gst_paid_paise'     => 0,
                'current_sell_price_paise' => null,
                'current_sell_value_paise' => null,
                'unrealised_pl_paise'      => null,
                'return_pct'               => null,
            ];
        }

        $totalGramsX10000 = 0;
        $weightedSum      = '0';
        $preGstAsset      = 0;
        $totalCashPaid    = 0;
        $totalGSTPaid     = 0;

        foreach ($txns as $txn) {
            $gx = (int)$txn['grams_x10000'];
            $r  = (int)$txn['buy_rate_paise'];
            $totalGramsX10000 += $gx;
            $weightedSum = bcadd($weightedSum, bcmul((string)$gx, (string)$r));
            $preGstAsset   += (int)$txn['pre_gst_paise'];
            $totalCashPaid += (int)$txn['total_paid_paise'];
            $totalGSTPaid  += (int)$txn['gst_paise'];
        }

        // Round half-up: (weightedSum + totalGramsX10000 / 2) / totalGramsX10000
        $weightedAvgRate = 0;
        if ($totalGramsX10000 > 0) {
            $half = bcdiv((string)$totalGramsX10000, '2', 0);
            $weightedAvgRate = (int)bcdiv(bcadd($weightedSum, $half), (string)$totalGramsX10000, 0);
        }

        // Effective cost per gram incl. 3% GST = totalCashPaid / totalGrams
        $effectiveCost = 0;
        if ($totalGramsX10000 > 0) {
            $num  = bcmul((string)$totalCashPaid, '10000');
            $half = bcdiv((string)$totalGramsX10000, '2', 0);
            $effectiveCost = (int)bcdiv(bcadd($num, $half), (string)$totalGramsX10000, 0);
        }

        $sellPriceKey     = $metal === 'gold' ? 'gold_current_sell_paise' : 'silver_current_sell_paise';
        $currentSellPrice = isset($settings[$sellPriceKey]) && $settings[$sellPriceKey] !== null
            ? (int)$settings[$sellPriceKey]
            : null;
        $currentSellValue = null;
        $unrealisedPL     = null;
        $returnPct        = null;

        if ($currentSellPrice !== null && $totalGramsX10000 > 0) {
            $sellNum = bcmul((string)$currentSellPrice, (string)$totalGramsX10000);
            $currentSellValue = (int)bcdiv(bcadd($sellNum, '5000'), '10000', 0);
            $unrealisedPL = $currentSellValue - $totalCashPaid;
            $returnPct = $totalCashPaid > 0
                ? round(($unrealisedPL / $totalCashPaid) * 100, 2)
                : null;
        }

        return [
            'metal'                    => $metal,
            'total_grams_x10000'       => $totalGramsX10000,
            'weighted_avg_rate_paise'  => $weightedAvgRate,
            'effective_cost_paise'     => $effectiveCost,
            'pre_gst_asset_paise'      => $preGstAsset,
            'total_cash_paid_paise'    => $totalCashPaid,
            'total_gst_paid_paise'     => $totalGSTPaid,
            'current_sell_price_paise' => $currentSellPrice,
            'current_sell_value_paise' => $currentSellValue,
            'unrealised_pl_paise'      => $unrealisedPL,
            'return_pct'               => $returnPct,
        ];
    }

    private function computeHealthScore(
        array $cards,
        array $loans,
        array $recoveries,
        int $kulDena,
        int $gullakAsset,
        int $totalCCLimit,
        int $totalCCOutstanding
    ): array {
        // 1. Credit Utilization (25 pts): <=10% = 25, 30% = 18, 60% = 10, >=90% = 2
        $utilPct = $totalCCLimit > 0 ? ($totalCCOutstanding / $totalCCLimit) * 100 : 0.0;
        $utilScore = (int)max(0, min(25, round(25 - ($utilPct * 0.25))));

        // 2. Cleared Cards Ratio (25 pts)
        $clearedCount = count(array_filter($cards, fn($c) => ((int)$c['total_limit'] - (int)$c['available_limit']) <= 0));
        $clearedScore = count($cards) > 0 ? (int)round(($clearedCount / count($cards)) * 25) : 25;

        // 3. Recovery Collection Progress (20 pts)
        $origRec = array_sum(array_map(fn($r) => (int)$r['total_original'], $recoveries));
        $pendRec = array_sum(array_map(fn($r) => (int)$r['total_pending'], $recoveries));
        $recScore = $origRec > 0 ? (int)round((($origRec - $pendRec) / $origRec) * 20) : 20;
        $recScore = max(5, $recScore); // baseline 5 pts for actively tracking receivables

        // 4. EMI Progress (20 pts)
        $origEmis = array_sum(array_map(fn($l) => (int)$l['original_emis'], $loans));
        $remEmis  = array_sum(array_map(fn($l) => (int)$l['remaining_emis'], $loans));
        $emiScore = $origEmis > 0 ? (int)max(5, round((($origEmis - $remEmis) / $origEmis) * 20)) : 20;

        // 5. Bullion / Asset Buffer (10 pts)
        $assetRatio = $kulDena > 0 ? min(1.0, ($gullakAsset / $kulDena) * 5) : 1.0;
        $assetScore = (int)round($assetRatio * 10);

        $total = max(0, min(100, $utilScore + $clearedScore + $recScore + $emiScore + $assetScore));

        return [
            'score'      => $total,
            'disclaimer' => 'Personal financial clarity indicator only — not a CIBIL or bank credit score.',
            'breakdown'  => [
                ['label' => 'Credit Utilization',   'score' => $utilScore,    'max' => 25],
                ['label' => 'Cleared Cards Ratio',  'score' => $clearedScore, 'max' => 25],
                ['label' => 'Recovery Collection',  'score' => $recScore,     'max' => 20],
                ['label' => 'EMI Payoff Progress',  'score' => $emiScore,     'max' => 20],
                ['label' => 'Asset Buffer',         'score' => $assetScore,   'max' => 10],
            ],
        ];
    }

    private function computeSmartAlerts(
        array $cards,
        array $loans,
        array $recoveries,
        array $goldStats,
        array $silverStats
    ): array {
        $alerts = [];
        foreach ($cards as $card) {
            $limit = (int)$card['total_limit'];
            $out   = max(0, $limit - (int)$card['available_limit']);
            $pct   = $limit > 0 ? ($out / $limit) * 100 : 0.0;

            if ($pct >= 80) {
                $alerts[] = [
                    'severity' => 'high',
                    'title'    => "{$card['name']} utilization at " . number_format($pct, 1) . "%",
                    'message'  => "Above 80% threshold. Tag: {$card['category_tag']}",
                ];
            } elseif ($out > 0 && $out <= 50000) { // <= ₹500 quick zero target
                $alerts[] = [
                    'severity' => 'tip',
                    'title'    => "Quick Zero Win: {$card['name']}",
                    'message'  => "Only ₹" . number_format($out / 100, 2) . " left to mark another card Cleared!",
                ];
            }
        }

        foreach ($loans as $loan) {
            $rem = (int)$loan['remaining_emis'];
            if ($rem > 0 && $rem <= 3) {
                $alerts[] = [
                    'severity' => 'info',
                    'title'    => "{$loan['name']} nearing closure",
                    'message'  => "Only {$rem} EMIs remaining.",
                ];
            }
        }

        foreach ([$goldStats, $silverStats] as $metalStat) {
            if (($metalStat['unrealised_pl_paise'] ?? 0) > 0) {
                $name = ucfirst((string)$metalStat['metal']);
                $alerts[] = [
                    'severity' => 'positive',
                    'title'    => "{$name} in profit",
                    'message'  => "Unrealized gain of ₹" . number_format($metalStat['unrealised_pl_paise'] / 100, 2),
                ];
            }
        }

        return $alerts;
    }
}
