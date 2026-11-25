<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $request = new Request();
    $db      = Database::getInstance();

    if (!$request->isPost()) {
        Response::error('Method not allowed', 405);
    }

    $request->requireFields(['refresh_token'])->validate();

    $refreshToken = (string)$request->input('refresh_token');
    $userId       = Auth::validateRefreshToken($refreshToken);

    $user = $db->execute("SELECT id, name, email, plan FROM users WHERE id = ?", [$userId])->fetch();
    if (!$user) {
        Response::unauthorized('User no longer exists');
    }

    $tokens = Auth::generateTokenPair($userId);
    Response::success([
        'user'   => $user,
        'tokens' => $tokens,
    ], 'Token refreshed');
} catch (\InvalidArgumentException $e) {
    Response::unauthorized($e->getMessage());
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Token refresh failed');
}
