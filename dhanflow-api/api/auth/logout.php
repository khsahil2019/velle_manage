<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    if (!$request->isPost()) Response::error('Method not allowed', 405);

    $db->insert('activity_log', [
        'user_id'     => $userId,
        'event_type'  => 'AUTH_LOGOUT',
        'description' => 'Signed out from device session',
        'created_at'  => $db->now(),
    ]);

    Response::success(['signed_out' => true], 'Signed out successfully');
} catch (\Throwable $e) {
    if ($e->getCode() === 503) Response::error($e->getMessage(), 503);
    Response::success(['signed_out' => true], 'Signed out');
}
