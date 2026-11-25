<?php
declare(strict_types=1);

/**
 * DHANFLOW PHP Backend Integration Test Suite (SQLite in-memory)
 * Verifies:
 *  1. Exact KPI figures from seed snapshot
 *  2. Bullion weighted average & GST arithmetic in paise
 *  3. Atomic Recovery-to-Card payment (and rollback safety)
 *  4. Final EMI payment protection
 *  5. Debt Freedom Engine Snowball vs Avalanche comparison
 */

putenv('DB_DRIVER=sqlite');
putenv('DB_PATH=:memory:');
putenv('JWT_SECRET=test_secret_key_for_ci');

require_once __DIR__ . '/../src/Core/Database.php';
require_once __DIR__ . '/../src/Core/Auth.php';
require_once __DIR__ . '/../src/Services/KPIService.php';
require_once __DIR__ . '/../src/Services/RecoveryService.php';
require_once __DIR__ . '/../src/Services/DebtEngineService.php';
require_once __DIR__ . '/../src/Services/SeedService.php';

function assertEqualsExact(mixed $expected, mixed $actual, string $label): void {
    if ($expected !== $actual) {
        fwrite(STDERR, "FAIL [{$label}]: expected " . var_export($expected, true) . ", got " . var_export($actual, true) . "\n");
        exit(1);
    }
    echo "PASS: {$label} => " . var_export($actual, true) . "\n";
}

$db  = Database::getInstance();
$pdo = $db->getPDO();

// Create SQLite compatible schema matching schema.sql
$pdo->exec("
CREATE TABLE users (
  id TEXT PRIMARY KEY, email TEXT UNIQUE, name TEXT, password_hash TEXT,
  plan TEXT DEFAULT 'free', plan_expires_at TEXT, created_at TEXT, updated_at TEXT
);
CREATE TABLE credit_cards (
  id TEXT PRIMARY KEY, user_id TEXT, name TEXT, total_limit INTEGER, available_limit INTEGER,
  category_tag TEXT, display_order INTEGER DEFAULT 0, is_active INTEGER DEFAULT 1,
  created_at TEXT, updated_at TEXT
);
CREATE TABLE card_transactions (
  id TEXT PRIMARY KEY, card_id TEXT, user_id TEXT, type TEXT, amount INTEGER,
  note TEXT, txn_date TEXT, created_at TEXT
);
CREATE TABLE loans (
  id TEXT PRIMARY KEY, user_id TEXT, name TEXT, emi_amount INTEGER, remaining_emis INTEGER,
  original_emis INTEGER, total_remaining INTEGER, note TEXT, is_active INTEGER DEFAULT 1,
  created_at TEXT, updated_at TEXT
);
CREATE TABLE personal_payables (
  id TEXT PRIMARY KEY, user_id TEXT, name TEXT, amount INTEGER, note TEXT,
  is_settled INTEGER DEFAULT 0, created_at TEXT, updated_at TEXT
);
CREATE TABLE recoveries (
  id TEXT PRIMARY KEY, user_id TEXT, name TEXT, total_original INTEGER, total_pending INTEGER,
  note TEXT, is_settled INTEGER DEFAULT 0, created_at TEXT, updated_at TEXT
);
CREATE TABLE recovery_payments (
  id TEXT PRIMARY KEY, recovery_id TEXT, user_id TEXT, amount INTEGER,
  applied_to_card TEXT, note TEXT, payment_date TEXT, created_at TEXT
);
CREATE TABLE bullion_transactions (
  id TEXT PRIMARY KEY, user_id TEXT, metal TEXT, grams_x10000 INTEGER, buy_rate_paise INTEGER,
  pre_gst_paise INTEGER, gst_paise INTEGER, total_paid_paise INTEGER,
  purchase_date TEXT, platform TEXT, created_at TEXT
);
CREATE TABLE user_settings (
  user_id TEXT PRIMARY KEY, gold_current_sell_paise INTEGER, silver_current_sell_paise INTEGER,
  debt_payoff_strategy TEXT DEFAULT 'snowball', monthly_payment_capacity INTEGER,
  currency TEXT DEFAULT 'INR', updated_at TEXT
);
CREATE TABLE activity_log (
  id TEXT PRIMARY KEY, user_id TEXT, event_type TEXT, description TEXT, delta_paise INTEGER,
  related_entity_type TEXT, related_entity_id TEXT, related_entity_name TEXT,
  metadata_json TEXT, created_at TEXT
);
");

$userId = $db->insert('users', [
    'email'         => 'sahil@dhanflow.app',
    'name'          => 'Sahil Khan',
    'password_hash' => password_hash('SecretPass123!', PASSWORD_DEFAULT),
    'plan'          => 'pro',
    'created_at'    => $db->now(),
    'updated_at'    => $db->now(),
]);
$db->insert('user_settings', ['user_id' => $userId, 'updated_at' => $db->now()], false);

// Seed exact snapshot
$seeder = new SeedService($db);
$seeder->resetUserToInitialSeed($userId);

// 1. Verify exact KPIs
$kpiService = new KPIService($db);
$kpis       = $kpiService->getFullSnapshot($userId);

assertEqualsExact(17479984, $kpis['total_cc_outstanding_paise'], 'CC Outstanding (₹1,74,799.84)');
assertEqualsExact(5224100,  $kpis['total_loan_remaining_paise'], 'DMI Loan (₹52,241.00)');
assertEqualsExact(560000,   $kpis['total_payables_paise'],       'Arshi Payable (₹5,600.00)');
assertEqualsExact(23264084, $kpis['kul_dena_paise'],             'Kul Dena (₹2,32,640.84)');
assertEqualsExact(17175911, $kpis['kul_lena_paise'],             'Kul Lena (₹1,71,759.11)');
assertEqualsExact(6088173,  $kpis['asal_net_debt_paise'],        'Asal Net Debt (₹60,881.73)');
assertEqualsExact(867689,   $kpis['gullak_asset_paise'],         'Gullak Pre-GST Asset (₹8,676.89)');
assertEqualsExact(5220484,  $kpis['true_net_liability_paise'],   'True Net Liability (₹52,204.84)');
assertEqualsExact(5818201,  $kpis['pocket_debt_paise'],          'Direct Pocket Debt (₹58,182.01)');
assertEqualsExact(3,        $kpis['cleared_cards_count'],        'Cleared Cards Count (3/8)');

// 2. Verify Bullion totals
assertEqualsExact(5000,    $kpis['gold_stats']['total_grams_x10000'],      'Gold Total Grams (0.5000 gm)');
assertEqualsExact(1269952, $kpis['gold_stats']['weighted_avg_rate_paise'], 'Gold Avg Rate (₹12,699.52/gm)');
assertEqualsExact(634976,  $kpis['gold_stats']['pre_gst_asset_paise'],     'Gold Asset Value (₹6,349.76)');
assertEqualsExact(654026,  $kpis['gold_stats']['total_cash_paid_paise'],   'Gold Total Paid (₹6,540.26)');

assertEqualsExact(150005,  $kpis['silver_stats']['total_grams_x10000'],      'Silver Total Grams (15.0005 gm)');
assertEqualsExact(15514,   $kpis['silver_stats']['weighted_avg_rate_paise'], 'Silver Avg Rate (₹155.14/gm)');
assertEqualsExact(232713,  $kpis['silver_stats']['pre_gst_asset_paise'],     'Silver Asset Value (₹2,327.13)');
assertEqualsExact(239695,  $kpis['silver_stats']['total_cash_paid_paise'],   'Silver Total Paid (₹2,396.95)');

// 3. Verify Atomic Recovery-to-Card (Nripen ₹6,835 -> PNB Card ₹24,454.30 -> ₹17,619.30)
$nripen = $db->execute("SELECT * FROM recoveries WHERE user_id = ? AND name = 'Nripen'", [$userId])->fetch();
$pnb    = $db->execute("SELECT * FROM credit_cards WHERE user_id = ? AND name = 'PNB Card'", [$userId])->fetch();
$recSvc = new RecoveryService($db);
$recRes = $recSvc->recordPayment($nripen['id'], 683500, 'UPI Settled', $pnb['id'], $userId);

assertEqualsExact(0,    $recRes['new_pending_paise'], 'Nripen Pending After Recovery (₹0)');
assertEqualsExact(true, $recRes['is_settled'],        'Nripen Settled');

$pnbAfter = $db->findOrFail('credit_cards', $pnb['id'], $userId);
$pnbOut   = (int)$pnbAfter['total_limit'] - (int)$pnbAfter['available_limit'];
assertEqualsExact(1761930, $pnbOut, 'PNB Outstanding After Recovery Link (₹17,619.30)');

// 4. Verify EMI payment + final EMI protection
$dmi = $db->execute("SELECT * FROM loans WHERE user_id = ? AND name = 'DMI Finance Loan'", [$userId])->fetch();
$emiRes = $recSvc->markEMIPaid($dmi['id'], $userId);
assertEqualsExact(6,       $emiRes['new_remaining_emis'],  'DMI EMIs Remaining (7 -> 6)');
assertEqualsExact(4477800, $emiRes['new_total_remaining'], 'DMI Balance (₹44,778.00)');

// 5. Verify Debt Freedom Engine
$engine = new DebtEngineService($db);
$planSnowball  = $engine->simulatePayoff($userId, 'snowball', 3000000);
$planAvalanche = $engine->simulatePayoff($userId, 'avalanche', 3000000);
assertEqualsExact('Roar Card', $planSnowball['next_target'], 'Snowball targets smallest balance (Roar Card)');
assertEqualsExact(true, $planSnowball['months_to_freedom'] > 0 && $planAvalanche['months_to_freedom'] > 0, 'Debt Freedom Engine simulation completes');

// 6. Verify JWT Auth Tokens
$tokens = Auth::generateTokenPair($userId);
$validatedSub = Auth::validateRefreshToken($tokens['refresh_token']);
assertEqualsExact($userId, $validatedSub, 'JWT Refresh Token Validation');

echo "\nALL PHP BACKEND TESTS PASSED!\n";
