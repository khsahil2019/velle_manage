<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    $id = $request->routeParam('recoveries');
    if (!$id) Response::error('Recovery ID required', 400);

    $rec = $db->findOrFail('recoveries', $id, $userId);

    if ($request->isGet()) {
        $rec['payments'] = $db->execute(
            "SELECT * FROM recovery_payments WHERE recovery_id = ? AND user_id = ? ORDER BY payment_date DESC",
            [$id, $userId]
        )->fetchAll();
        Response::success($rec);
    }

    if ($request->isPut()) {
        $data = [];
        if ($request->input('name') !== null) $data['name'] = trim((string)$request->input('name'));
        if ($request->input('note') !== null) $data['note'] = trim((string)$request->input('note'));
        $db->update('recoveries', $id, $userId, $data);
        Response::success($db->findOrFail('recoveries', $id, $userId), 'Recovery updated');
    }

    if ($request->isDelete()) {
        $db->execute("DELETE FROM recoveries WHERE id = ? AND user_id = ?", [$id, $userId]);
        $db->insert('activity_log', [
            'user_id'             => $userId,
            'event_type'          => 'RECOVERY_RECEIVED',
            'description'         => "Recovery entry removed: {$rec['name']}",
            'related_entity_type' => 'recovery',
            'related_entity_id'   => $id,
            'related_entity_name' => $rec['name'],
            'created_at'          => $db->now(),
        ]);
        Response::success(['deleted' => true], 'Recovery removed');
    }

    Response::error('Method not allowed', 405);
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Recovery operation failed');
}
