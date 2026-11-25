<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    if (!$request->isPost()) Response::error('Method not allowed', 405);

    $seed = new SeedService($db);
    $seed->resetUserToInitialSeed($userId, true);

    Response::success(['reset' => true], 'Account reset to initial financial snapshot');
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Account seed reset failed');
}
