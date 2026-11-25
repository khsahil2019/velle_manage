<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    $loanId = $request->routeParam('loans');
    if (!$loanId) Response::error('Loan ID required', 400);

    $loan = $db->findOrFail('loans', $loanId, $userId);

    if ($request->isGet()) Response::success($loan);

    if ($request->isPut()) {
        $data = [];
        if ($request->input('name') !== null) $data['name'] = trim((string)$request->input('name'));
        if ($request->input('note') !== null) $data['note'] = trim((string)$request->input('note'));
        if ($request->input('emi_amount') !== null) $data['emi_amount'] = (int)$request->input('emi_amount');
        if ($request->input('remaining_emis') !== null) $data['remaining_emis'] = (int)$request->input('remaining_emis');
        if ($request->input('total_remaining') !== null) $data['total_remaining'] = (int)$request->input('total_remaining');

        $db->update('loans', $loanId, $userId, $data);
        Response::success($db->findOrFail('loans', $loanId, $userId), 'Loan updated');
    }

    if ($request->isDelete()) {
        $db->softDelete('loans', $loanId, $userId);
        $db->insert('activity_log', [
            'user_id'             => $userId,
            'event_type'          => 'LOAN_EMI',
            'description'         => "{$loan['name']}: Loan removed from tracker",
            'related_entity_type' => 'loan',
            'related_entity_id'   => $loanId,
            'related_entity_name' => $loan['name'],
            'created_at'          => $db->now(),
        ]);
        Response::success(['deleted' => true], 'Loan removed');
    }

    Response::error('Method not allowed', 405);
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Loan operation failed');
}
