<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    if (!$request->isGet()) Response::error('Method not allowed', 405);

    $user = $db->execute(
        "SELECT id, name, email, plan, created_at FROM users WHERE id = ?",
        [$userId]
    )->fetch();

    if (!$user) {
        Response::unauthorized('User account not found');
    }

    $counts = [
        'credit_cards' => (int)$db->execute("SELECT COUNT(*) FROM credit_cards WHERE user_id = ? AND is_active = 1", [$userId])->fetchColumn(),
        'loans'        => (int)$db->execute("SELECT COUNT(*) FROM loans WHERE user_id = ? AND is_active = 1", [$userId])->fetchColumn(),
        'recoveries'   => (int)$db->execute("SELECT COUNT(*) FROM recoveries WHERE user_id = ?", [$userId])->fetchColumn(),
        'bullion'      => (int)$db->execute("SELECT COUNT(*) FROM bullion_transactions WHERE user_id = ?", [$userId])->fetchColumn(),
    ];

    Response::success([
        'user'           => $user,
        'storage_driver' => $db->getDriver(),
        'counts'         => $counts,
    ]);
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Failed to fetch user profile');
}
