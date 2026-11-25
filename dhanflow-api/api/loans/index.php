<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    if ($request->isGet()) {
        $loans = $db->execute(
            "SELECT * FROM loans WHERE user_id = ? ORDER BY is_active DESC, created_at ASC",
            [$userId]
        )->fetchAll();
        Response::success($loans);
    }

    if ($request->isPost()) {
        $request
            ->requireFields(['name', 'emi_amount', 'remaining_emis'])
            ->requirePositiveInt('emi_amount')
            ->requirePositiveInt('remaining_emis')
            ->validate();

        $name          = trim((string)$request->input('name'));
        $emiAmount     = (int)$request->input('emi_amount');
        $remainingEmis = (int)$request->input('remaining_emis');
        $totalRem      = $request->input('total_remaining') !== null
            ? (int)$request->input('total_remaining')
            : ($emiAmount * $remainingEmis);
        $note          = trim((string)($request->input('note') ?? ''));
        $now           = $db->now();

        $loanId = $db->insert('loans', [
            'user_id'         => $userId,
            'name'            => $name,
            'emi_amount'      => $emiAmount,
            'remaining_emis'  => $remainingEmis,
            'original_emis'   => $remainingEmis,
            'total_remaining' => $totalRem,
            'note'            => $note,
            'is_active'       => 1,
            'created_at'      => $now,
            'updated_at'      => $now,
        ]);

        $db->insert('activity_log', [
            'user_id'             => $userId,
            'event_type'          => 'LOAN_EMI',
            'description'         => "Loan added: {$name} — ₹" . number_format($emiAmount / 100, 2) . " × {$remainingEmis} EMIs",
            'delta_paise'         => $totalRem,
            'related_entity_type' => 'loan',
            'related_entity_id'   => $loanId,
            'related_entity_name' => $name,
            'created_at'          => $now,
        ]);

        Response::success($db->findOrFail('loans', $loanId, $userId), 'Loan added', 201);
    }

    Response::error('Method not allowed', 405);
} catch (\Throwable $e) {
    error_log('[DHANFLOW] Loans error: ' . $e->getMessage());
    Response::serverError();
}
