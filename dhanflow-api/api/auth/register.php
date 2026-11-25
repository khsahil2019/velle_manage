<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $request = new Request();
    $db      = Database::getInstance();

    if (!$request->isPost()) {
        Response::error('Method not allowed', 405);
    }

    $request
        ->requireFields(['name', 'email', 'password'])
        ->validate();

    $email    = strtolower(trim((string)$request->input('email')));
    $name     = trim((string)$request->input('name'));
    $pass     = (string)$request->input('password');
    $seedDemo = (bool)($request->input('seed_initial_data') ?? true);

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        Response::error('Invalid email address', 422);
    }
    if (strlen($pass) < 8) {
        Response::error('Password must be at least 8 characters', 422);
    }

    $existing = $db->execute("SELECT id FROM users WHERE email = ?", [$email])->fetch();
    if ($existing) {
        Response::error('An account with this email already exists', 409);
    }

    $algo = defined('PASSWORD_ARGON2ID') ? PASSWORD_ARGON2ID : PASSWORD_BCRYPT;
    $now  = $db->now();

    $userId = $db->insert('users', [
        'email'         => $email,
        'name'          => $name,
        'password_hash' => password_hash($pass, $algo),
        'plan'          => 'free',
        'created_at'    => $now,
        'updated_at'    => $now,
    ]);

    $db->insert('user_settings', [
        'user_id'              => $userId,
        'debt_payoff_strategy' => 'snowball',
        'currency'             => 'INR',
        'updated_at'           => $now,
    ], false);

    if ($seedDemo) {
        $seedService = new SeedService($db);
        $seedService->resetUserToInitialSeed($userId);
    }

    $tokens = Auth::generateTokenPair($userId);
    Response::success([
        'user'   => ['id' => $userId, 'name' => $name, 'email' => $email, 'plan' => 'free'],
        'tokens' => $tokens,
    ], 'Account created', 201);
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Registration failed');
}
