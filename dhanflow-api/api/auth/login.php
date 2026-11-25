<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $request = new Request();
    $db      = Database::getInstance();

    if (!$request->isPost()) {
        Response::error('Method not allowed', 405);
    }

    $request->requireFields(['email', 'password'])->validate();

    $email = strtolower(trim((string)$request->input('email')));
    $pass  = (string)$request->input('password');

    $user = $db->execute("SELECT * FROM users WHERE email = ?", [$email])->fetch();

    if (!$user || !password_verify($pass, (string)$user['password_hash'])) {
        Response::error('Invalid email or password', 401);
    }

    $tokens = Auth::generateTokenPair((string)$user['id']);
    Response::success([
        'user' => [
            'id'    => $user['id'],
            'name'  => $user['name'],
            'email' => $user['email'],
            'plan'  => $user['plan'],
        ],
        'tokens' => $tokens,
    ]);
} catch (\Throwable $e) {
    error_log('[DHANFLOW] Login error: ' . $e->getMessage());
    if ($e->getCode() === 503) Response::error($e->getMessage(), 503);
    Response::serverError();
}
