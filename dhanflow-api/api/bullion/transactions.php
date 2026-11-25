<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    if ($request->isGet()) {
        $metal = $request->query('metal');
        if ($metal && in_array($metal, ['gold', 'silver'], true)) {
            $txns = $db->execute(
                "SELECT * FROM bullion_transactions WHERE user_id = ? AND metal = ? ORDER BY purchase_date DESC",
                [$userId, $metal]
            )->fetchAll();
        } else {
            $txns = $db->execute(
                "SELECT * FROM bullion_transactions WHERE user_id = ? ORDER BY purchase_date DESC",
                [$userId]
            )->fetchAll();
        }
        Response::success($txns);
    }

    if ($request->isPost()) {
        $request
            ->requireFields(['metal', 'grams_x10000'])
            ->requirePositiveInt('grams_x10000')
            ->validate();

        $metal        = strtolower(trim((string)$request->input('metal')));
        $gramsX10000  = (int)$request->input('grams_x10000');
        $purchaseDate = trim((string)($request->input('purchase_date') ?? $db->now()));
        $platform     = trim((string)($request->input('platform') ?? 'Gullak'));

        if (!in_array($metal, ['gold', 'silver'], true)) {
            Response::error('metal must be gold or silver', 422);
        }

        // Accepts either buy_rate_paise (pre-GST/gm) OR total_paid_paise (incl. 3% GST)
        $buyRatePaise   = $request->input('buy_rate_paise');
        $totalPaidInput = $request->input('total_paid_paise');

        if ($buyRatePaise !== null) {
            $rate = (int)$buyRatePaise;
            if ($rate <= 0) Response::error('buy_rate_paise must be positive', 422);
            // pre_gst = round(grams * rate)
            $preGstPaise    = (int)bcdiv(bcadd(bcmul((string)$gramsX10000, (string)$rate), '5000'), '10000', 0);
            $gstPaise       = (int)round($preGstPaise * 3 / 100);
            $totalPaidPaise = $preGstPaise + $gstPaise;
        } elseif ($totalPaidInput !== null) {
            $totalPaidPaise = (int)$totalPaidInput;
            if ($totalPaidPaise <= 0) Response::error('total_paid_paise must be positive', 422);
            $preGstPaise = (int)round($totalPaidPaise * 100 / 103);
            $gstPaise    = $totalPaidPaise - $preGstPaise;
            $rate        = (int)bcdiv(bcadd(bcmul((string)$preGstPaise, '10000'), bcdiv((string)$gramsX10000, '2', 0)), (string)$gramsX10000, 0);
        } else {
            Response::error('Either buy_rate_paise or total_paid_paise is required', 422);
        }

        $now = $db->now();
        $id  = $db->insert('bullion_transactions', [
            'user_id'          => $userId,
            'metal'            => $metal,
            'grams_x10000'     => $gramsX10000,
            'buy_rate_paise'   => $rate,
            'pre_gst_paise'    => $preGstPaise,
            'gst_paise'        => $gstPaise,
            'total_paid_paise' => $totalPaidPaise,
            'purchase_date'    => $purchaseDate,
            'platform'         => $platform,
            'created_at'       => $now,
        ]);

        $gramsDisplay = number_format($gramsX10000 / 10000, 4);
        $db->insert('activity_log', [
            'user_id'             => $userId,
            'event_type'          => 'BULLION_BUY',
            'description'         => ucfirst($metal) . ": Bought {$gramsDisplay}gm @ ₹" . number_format($rate / 100, 2) . "/gm (Paid ₹" . number_format($totalPaidPaise / 100, 2) . ")",
            'delta_paise'         => $totalPaidPaise,
            'related_entity_type' => 'bullion',
            'related_entity_id'   => $id,
            'related_entity_name' => ucfirst($metal),
            'created_at'          => $now,
        ]);

        Response::success($db->findOrFail('bullion_transactions', $id, $userId), 'Bullion purchase recorded', 201);
    }

    if ($request->isDelete()) {
        $id = $request->routeParam('transactions') ?? $request->query('id');
        if (!$id) Response::error('Transaction ID required', 400);

        $txn = $db->findOrFail('bullion_transactions', (string)$id, $userId);
        $db->execute("DELETE FROM bullion_transactions WHERE id = ? AND user_id = ?", [$id, $userId]);

        $gramsDisplay = number_format(((int)$txn['grams_x10000']) / 10000, 4);
        $db->insert('activity_log', [
            'user_id'             => $userId,
            'event_type'          => 'BULLION_BUY',
            'description'         => ucfirst((string)$txn['metal']) . ": Deleted {$gramsDisplay}gm transaction",
            'delta_paise'         => -((int)$txn['total_paid_paise']),
            'related_entity_type' => 'bullion',
            'related_entity_id'   => (string)$id,
            'related_entity_name' => ucfirst((string)$txn['metal']),
            'created_at'          => $db->now(),
        ]);

        Response::success(['deleted' => true], 'Transaction removed');
    }

    Response::error('Method not allowed', 405);
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Bullion transaction failed');
}
