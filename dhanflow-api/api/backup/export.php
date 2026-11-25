<?php
declare(strict_types=1);
require_once __DIR__ . '/../../src/Core/bootstrap.php';

try {
    $userId  = Auth::requireAuth();
    $request = new Request();
    $db      = Database::getInstance();

    $snapshot = SyncService::buildSnapshot($db, $userId);
    $syncHash = SyncService::computeHash($snapshot);
    $clientHash = trim((string)($request->query('hash', '') ?? ''));

    if ($clientHash !== '' && hash_equals($syncHash, $clientHash)) {
        Response::success([
            'unchanged'   => true,
            'sync_hash'   => $syncHash,
            'server_time' => date('c'),
        ], 'No changes');
    }

    $nowIso = date('c');
    $snapshot['last_updated'] = $nowIso;
    $snapshot['exported_at']  = $nowIso;
    $snapshot['unchanged']    = false;
    $snapshot['sync_hash']    = $syncHash;

    Response::success($snapshot);
} catch (\Throwable $e) {
    Response::handleThrowable($e, 'Backup export failed');
}
