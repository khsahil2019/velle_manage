<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    if ($request->isGet()) {
        $page   = max(1, (int)$request->query('page', 1));
        $limit  = min(100, max(1, (int)$request->query('limit', 50)));
        $offset = ($page - 1) * $limit;

        $entries = $db->execute(
            "SELECT * FROM activity_log WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?",
            [$userId, $limit, $offset]
        )->fetchAll();

        $total = (int)$db->execute(
            "SELECT COUNT(*) FROM activity_log WHERE user_id = ?",
            [$userId]
        )->fetchColumn();

        Response::success([
            'items' => $entries,
            'page'  => $page,
            'limit' => $limit,
            'total' => $total,
        ]);
    }

    Response::error('Method not allowed', 405);
} catch (\Throwable $e) {
    error_log('[DHANFLOW] Activity error: ' . $e->getMessage());
    Response::serverError();
}
