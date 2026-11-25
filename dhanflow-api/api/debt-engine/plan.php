<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();
    $engine  = new DebtEngineService($db);

    $strategy = (string)($request->input('strategy') ?? $request->query('strategy') ?? 'snowball');
    if (!in_array($strategy, ['snowball', 'avalanche', 'custom'], true)) {
        Response::error('Strategy must be snowball, avalanche, or custom', 422);
    }

    $budget = (int)($request->input('monthly_budget_paise') ?? $request->query('monthly_budget_paise') ?? 2500000);
    if ($budget <= 0) {
        Response::error('monthly_budget_paise must be positive', 422);
    }

    $aprOverrides = (array)($request->input('apr_overrides_bps') ?? []);
    $customOrder  = (array)($request->input('custom_order') ?? []);

    $plan = $engine->simulatePayoff($userId, $strategy, $budget, $aprOverrides, $customOrder);
    Response::success($plan);
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Failed to simulate payoff plan');
}
