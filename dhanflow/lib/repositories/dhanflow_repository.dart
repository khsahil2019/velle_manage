import 'package:uuid/uuid.dart';
import '../core/constants/api_constants.dart';
import '../core/errors/failures.dart';
import '../core/network/api_client.dart';
import '../core/utils/inr_formatter.dart';
import '../models/models.dart';
import '../services/export_service.dart';
import '../services/local_storage_service.dart';
import '../services/seed_service.dart';

/// Offline-first repository backed by Hive, with optional sync to Vercel PHP API.
class DhanflowRepository {
  final ApiClient apiClient;
  static const _uuid = Uuid();

  DhanflowRepository({required this.apiClient});

  DhanflowAppState loadLocalState() => LocalStorageService.loadState();

  bool get canUndo => LocalStorageService.canUndo;

  DhanflowAppState _commit(
    DhanflowAppState current,
    DhanflowAppState next, {
    required String eventType,
    required String description,
    int? deltaPaise,
    String? entityId,
    String? entityName,
  }) {
    LocalStorageService.pushUndoSnapshot(current);
    final logEntry = ActivityLogModel(
      id: _uuid.v4(),
      eventType: eventType,
      description: description,
      deltaPaise: deltaPaise,
      relatedEntityId: entityId,
      relatedEntityName: entityName,
      createdAt: DateTime.now(),
    );
    final updated = next.copyWith(
      lastUpdated: DateTime.now(),
      activityLog: [logEntry, ...next.activityLog].take(300).toList(),
    );
    LocalStorageService.saveState(updated);
    return updated;
  }

  // ── CREDIT CARDS ──────────────────────────────────────────────

  DhanflowAppState updateCardAvailableLimit(
    DhanflowAppState state, {
    required String cardId,
    required int newAvailablePaise,
  }) {
    final card = state.creditCards.firstWhere((c) => c.id == cardId);
    if (newAvailablePaise < 0 || newAvailablePaise > card.totalLimitPaise) {
      throw ValidationFailure('Available limit must be between ₹0 and ${card.totalLimitFormatted}');
    }
    final oldOut = card.outstandingPaise;
    final newOut = (card.totalLimitPaise - newAvailablePaise).clamp(0, card.totalLimitPaise);
    final updatedCards = state.creditCards
        .map((c) => c.id == cardId ? c.copyWith(availableLimitPaise: newAvailablePaise) : c)
        .toList();

    return _commit(
      state,
      state.copyWith(creditCards: updatedCards),
      eventType: 'CC_UPDATE',
      description:
          '${card.name}: Avl limit updated → ${INRFormatter.formatPaise(newAvailablePaise)} (outstanding: ${INRFormatter.formatPaise(oldOut)} → ${INRFormatter.formatPaise(newOut)})',
      deltaPaise: newOut - oldOut,
      entityId: card.id,
      entityName: card.name,
    );
  }

  DhanflowAppState recordCardTransaction(
    DhanflowAppState state, {
    required String cardId,
    required bool isPayment,
    required int amountPaise,
    String note = '',
  }) {
    if (amountPaise <= 0) throw const ValidationFailure('Amount must be greater than ₹0');
    final card = state.creditCards.firstWhere((c) => c.id == cardId);

    late int newAvl;
    late String eventType;
    late String desc;
    late int delta;

    if (isPayment) {
      final newOut = (card.outstandingPaise - amountPaise).clamp(0, card.totalLimitPaise);
      newAvl = card.totalLimitPaise - newOut;
      eventType = 'CC_PAYMENT';
      delta = -amountPaise;
      desc = '${card.name}: Payment of ${INRFormatter.formatPaise(amountPaise)}${note.isNotEmpty ? ' — $note' : ''}';
    } else {
      if (amountPaise > card.availableLimitPaise) {
        throw ValidationFailure('Spend exceeds available limit (${card.availableFormatted})');
      }
      newAvl = (card.availableLimitPaise - amountPaise).clamp(0, card.totalLimitPaise);
      eventType = 'CC_SPEND';
      delta = amountPaise;
      desc = '${card.name}: Spend of ${INRFormatter.formatPaise(amountPaise)}${note.isNotEmpty ? ' — $note' : ''}';
    }

    final updatedCards = state.creditCards
        .map((c) => c.id == cardId ? c.copyWith(availableLimitPaise: newAvl) : c)
        .toList();

    return _commit(
      state,
      state.copyWith(creditCards: updatedCards),
      eventType: eventType,
      description: desc,
      deltaPaise: delta,
      entityId: card.id,
      entityName: card.name,
    );
  }

  DhanflowAppState updateCardDetails(
    DhanflowAppState state, {
    required String cardId,
    required int newTotalLimitPaise,
    String? name,
    String? categoryTag,
    int? aprBps,
  }) {
    final card = state.creditCards.firstWhere((c) => c.id == cardId);
    if (newTotalLimitPaise <= 0) {
      throw const ValidationFailure('Total limit must be positive');
    }
    if (newTotalLimitPaise < card.outstandingPaise) {
      throw ValidationFailure('Limit cannot be less than outstanding (${card.outstandingFormatted})');
    }
    // Financial logic rule: outstanding remains unchanged on limit change
    final newAvl = newTotalLimitPaise - card.outstandingPaise;
    final diff = newTotalLimitPaise - card.totalLimitPaise;
    final trimmedName = name != null && name.trim().isNotEmpty ? name.trim() : card.name;

    final updatedCards = state.creditCards
        .map((c) => c.id == cardId
            ? c.copyWith(
                name: trimmedName,
                totalLimitPaise: newTotalLimitPaise,
                availableLimitPaise: newAvl,
                categoryTag: categoryTag ?? c.categoryTag,
                aprBps: aprBps ?? c.aprBps,
              )
            : c)
        .toList();

    return _commit(
      state,
      state.copyWith(creditCards: updatedCards),
      eventType: 'CC_UPDATE',
      description:
          '$trimmedName: Total limit updated to ${INRFormatter.formatPaise(newTotalLimitPaise)}',
      deltaPaise: diff,
      entityId: card.id,
      entityName: trimmedName,
    );
  }

  DhanflowAppState addCreditCard(
    DhanflowAppState state, {
    required String name,
    required int totalLimitPaise,
    required int availableLimitPaise,
    required String categoryTag,
    int aprBps = 3600,
  }) {
    if (name.trim().isEmpty) throw const ValidationFailure('Card name is required');
    if (totalLimitPaise <= 0) throw const ValidationFailure('Total limit must be positive');
    if (availableLimitPaise < 0 || availableLimitPaise > totalLimitPaise) {
      throw const ValidationFailure('Available limit must be between ₹0 and total limit');
    }

    final now = DateTime.now();
    final newCard = CreditCardModel(
      id: _uuid.v4(),
      userId: 'local',
      name: name.trim(),
      totalLimitPaise: totalLimitPaise,
      availableLimitPaise: availableLimitPaise,
      categoryTag: categoryTag.trim().isEmpty ? 'Active Pocket Debt' : categoryTag.trim(),
      displayOrder: state.creditCards.length,
      isActive: true,
      aprBps: aprBps,
      createdAt: now,
      updatedAt: now,
    );

    return _commit(
      state,
      state.copyWith(creditCards: [...state.creditCards, newCard]),
      eventType: 'CC_UPDATE',
      description: 'Added card ${newCard.name} (limit ${newCard.totalLimitFormatted})',
      deltaPaise: newCard.outstandingPaise,
      entityId: newCard.id,
      entityName: newCard.name,
    );
  }

  DhanflowAppState removeCreditCard(DhanflowAppState state, String cardId) {
    final card = state.creditCards.firstWhere((c) => c.id == cardId);
    final remaining = state.creditCards.where((c) => c.id != cardId).toList();
    return _commit(
      state,
      state.copyWith(creditCards: remaining),
      eventType: 'CC_UPDATE',
      description: 'Removed card ${card.name} from tracker',
      entityId: card.id,
      entityName: card.name,
    );
  }

  // ── LOANS & PAYABLES ──────────────────────────────────────────

  DhanflowAppState markLoanEmiPaid(DhanflowAppState state, String loanId) {
    final loan = state.loans.firstWhere((l) => l.id == loanId);
    if (loan.remainingEmis <= 0 || loan.totalRemainingPaise <= 0) {
      throw const ValidationFailure('Loan already cleared');
    }

    // Final EMI uses actual remaining balance, never over-subtracts
    final isLastEmi = loan.remainingEmis == 1;
    final actualPayment = isLastEmi
        ? loan.totalRemainingPaise
        : (loan.emiAmountPaise < loan.totalRemainingPaise ? loan.emiAmountPaise : loan.totalRemainingPaise);
    final newRemaining = (loan.totalRemainingPaise - actualPayment).clamp(0, loan.totalRemainingPaise);
    final newCount = loan.remainingEmis - 1;
    final isCleared = newCount <= 0 || newRemaining <= 0;

    final updatedLoans = state.loans
        .map((l) => l.id == loanId
            ? l.copyWith(
                remainingEmis: newCount,
                totalRemainingPaise: newRemaining,
                isActive: !isCleared,
              )
            : l)
        .toList();

    return _commit(
      state,
      state.copyWith(loans: updatedLoans),
      eventType: 'LOAN_EMI',
      description:
          '${loan.name}: EMI of ${INRFormatter.formatPaise(actualPayment)} paid. ${isCleared ? 'LOAN CLEARED!' : '$newCount EMIs remaining (${INRFormatter.formatPaise(newRemaining)})'}',
      deltaPaise: -actualPayment,
      entityId: loan.id,
      entityName: loan.name,
    );
  }

  DhanflowAppState addLoan(
    DhanflowAppState state, {
    required String name,
    required int emiAmountPaise,
    required int remainingEmis,
    String note = '',
    int aprBps = 1600,
  }) {
    if (name.trim().isEmpty || emiAmountPaise <= 0 || remainingEmis <= 0) {
      throw const ValidationFailure('Enter valid loan name, EMI amount, and tenure');
    }
    final now = DateTime.now();
    final totalRem = emiAmountPaise * remainingEmis;
    final loan = LoanModel(
      id: _uuid.v4(),
      userId: 'local',
      name: name.trim(),
      emiAmountPaise: emiAmountPaise,
      remainingEmis: remainingEmis,
      originalEmis: remainingEmis,
      totalRemainingPaise: totalRem,
      note: note.trim(),
      isActive: true,
      aprBps: aprBps,
      createdAt: now,
      updatedAt: now,
    );

    return _commit(
      state,
      state.copyWith(loans: [...state.loans, loan]),
      eventType: 'LOAN_EMI',
      description: 'Added loan ${loan.name} (${loan.emiFormatted} × $remainingEmis EMIs)',
      deltaPaise: totalRem,
      entityId: loan.id,
      entityName: loan.name,
    );
  }

  DhanflowAppState removeLoan(DhanflowAppState state, String loanId) {
    final loan = state.loans.firstWhere((l) => l.id == loanId);
    return _commit(
      state,
      state.copyWith(loans: state.loans.where((l) => l.id != loanId).toList()),
      eventType: 'LOAN_EMI',
      description: 'Removed loan ${loan.name}',
      entityId: loan.id,
      entityName: loan.name,
    );
  }

  DhanflowAppState payPersonalPayable(
    DhanflowAppState state, {
    required String payableId,
    required int amountPaise,
  }) {
    final payable = state.personalPayables.firstWhere((p) => p.id == payableId);
    if (amountPaise <= 0 || amountPaise > payable.amountPaise) {
      throw ValidationFailure('Payment must be between ₹0.01 and ${payable.amountFormatted}');
    }
    final remaining = (payable.amountPaise - amountPaise).clamp(0, payable.amountPaise);
    final settled = remaining <= 0;

    final updated = state.personalPayables
        .map((p) => p.id == payableId ? p.copyWith(amountPaise: remaining, isSettled: settled) : p)
        .toList();

    return _commit(
      state,
      state.copyWith(personalPayables: updated),
      eventType: 'PAYABLE_PAID',
      description:
          '${payable.name}: Paid ${INRFormatter.formatPaise(amountPaise)}. ${settled ? 'Settled!' : 'Remaining: ${INRFormatter.formatPaise(remaining)}'}',
      deltaPaise: -amountPaise,
      entityId: payable.id,
      entityName: payable.name,
    );
  }

  DhanflowAppState addPersonalPayable(
    DhanflowAppState state, {
    required String name,
    required int amountPaise,
    String note = '',
  }) {
    if (name.trim().isEmpty || amountPaise <= 0) {
      throw const ValidationFailure('Enter valid name and amount');
    }
    final now = DateTime.now();
    final item = PersonalPayableModel(
      id: _uuid.v4(),
      userId: 'local',
      name: name.trim(),
      amountPaise: amountPaise,
      note: note.trim(),
      isSettled: false,
      createdAt: now,
      updatedAt: now,
    );
    return _commit(
      state,
      state.copyWith(personalPayables: [...state.personalPayables, item]),
      eventType: 'PAYABLE_PAID',
      description: 'Added payable ${item.name} (${item.amountFormatted})',
      deltaPaise: amountPaise,
      entityId: item.id,
      entityName: item.name,
    );
  }

  DhanflowAppState removePayable(DhanflowAppState state, String id) {
    final item = state.personalPayables.firstWhere((p) => p.id == id);
    return _commit(
      state,
      state.copyWith(
          personalPayables: state.personalPayables.where((p) => p.id != id).toList()),
      eventType: 'PAYABLE_PAID',
      description: 'Removed payable ${item.name}',
      entityId: item.id,
      entityName: item.name,
    );
  }

  // ── RECOVERIES (KUL LENA) + ATOMIC CARD LINKING ───────────────

  DhanflowAppState recordRecoveryPayment(
    DhanflowAppState state, {
    required String recoveryId,
    required int amountPaise,
    String note = '',
    String? linkedCardId,
  }) {
    final rec = state.recoveries.firstWhere((r) => r.id == recoveryId);
    if (amountPaise <= 0 || amountPaise > rec.totalPendingPaise) {
      throw ValidationFailure('Recovery amount must be between ₹0.01 and ${rec.pendingFormatted}');
    }

    final newPending = (rec.totalPendingPaise - amountPaise).clamp(0, rec.totalPendingPaise);
    final isSettled = newPending <= 0;
    final payment = RecoveryPaymentModel(
      id: _uuid.v4(),
      recoveryId: recoveryId,
      amountPaise: amountPaise,
      appliedToCardId: linkedCardId,
      note: note.trim(),
      paymentDate: DateTime.now(),
    );

    final updatedRecoveries = state.recoveries
        .map((r) => r.id == recoveryId
            ? r.copyWith(
                totalPendingPaise: newPending,
                isSettled: isSettled,
                payments: [payment, ...r.payments],
              )
            : r)
        .toList();

    List<CreditCardModel> updatedCards = state.creditCards;
    String? linkedCardName;
    if (linkedCardId != null && linkedCardId.isNotEmpty) {
      final card = state.creditCards.firstWhere((c) => c.id == linkedCardId);
      linkedCardName = card.name;
      final newOut = (card.outstandingPaise - amountPaise).clamp(0, card.totalLimitPaise);
      final newAvl = card.totalLimitPaise - newOut;
      updatedCards = state.creditCards
          .map((c) => c.id == linkedCardId ? c.copyWith(availableLimitPaise: newAvl) : c)
          .toList();
    }

    final desc = StringBuffer()
      ..write('${rec.name}: Received ${INRFormatter.formatPaise(amountPaise)}')
      ..write(note.isNotEmpty ? ' — $note' : '')
      ..write(linkedCardName != null ? ' → Applied to $linkedCardName' : '')
      ..write(isSettled ? ' [SETTLED]' : ' (pending: ${INRFormatter.formatPaise(newPending)})');

    return _commit(
      state,
      state.copyWith(recoveries: updatedRecoveries, creditCards: updatedCards),
      eventType: linkedCardName != null ? 'RECOVERY_LINKED' : 'RECOVERY_RECEIVED',
      description: desc.toString(),
      deltaPaise: amountPaise,
      entityId: rec.id,
      entityName: rec.name,
    );
  }

  DhanflowAppState addBorrower(
    DhanflowAppState state, {
    required String name,
    required int amountPaise,
    String note = '',
  }) {
    if (name.trim().isEmpty || amountPaise <= 0) {
      throw const ValidationFailure('Enter valid borrower name and amount');
    }
    final now = DateTime.now();
    final item = RecoveryModel(
      id: _uuid.v4(),
      userId: 'local',
      name: name.trim(),
      totalOriginalPaise: amountPaise,
      totalPendingPaise: amountPaise,
      note: note.trim(),
      isSettled: false,
      payments: const [],
      createdAt: now,
      updatedAt: now,
    );

    return _commit(
      state,
      state.copyWith(recoveries: [...state.recoveries, item]),
      eventType: 'RECOVERY_RECEIVED',
      description: 'Added borrower ${item.name} (${item.pendingFormatted} pending)',
      deltaPaise: amountPaise,
      entityId: item.id,
      entityName: item.name,
    );
  }

  DhanflowAppState removeRecovery(DhanflowAppState state, String id) {
    final rec = state.recoveries.firstWhere((r) => r.id == id);
    return _commit(
      state,
      state.copyWith(recoveries: state.recoveries.where((r) => r.id != id).toList()),
      eventType: 'RECOVERY_RECEIVED',
      description: 'Removed recovery entry ${rec.name}',
      entityId: rec.id,
      entityName: rec.name,
    );
  }

  // ── WEALTH & ASSET VAULT ───────────────────────────────────────

  DhanflowAppState addBullionPurchase(
    DhanflowAppState state, {
    required String metal,
    required int gramsX10000,
    int? buyRatePaise,
    int? totalPaidPaise,
    required DateTime purchaseDate,
    String platform = 'Vault',
  }) {
    if (gramsX10000 <= 0) throw const ValidationFailure('Grams must be positive');

    late int rate;
    late int preGst;
    late int gst;
    late int paid;

    if (buyRatePaise != null && buyRatePaise > 0) {
      rate = buyRatePaise;
      preGst = PaiseMath.preGstForGrams(gramsX10000, rate);
      gst = PaiseMath.gst3Pct(preGst);
      paid = preGst + gst;
    } else if (totalPaidPaise != null && totalPaidPaise > 0) {
      paid = totalPaidPaise;
      preGst = PaiseMath.removeGST3Pct(paid);
      gst = paid - preGst;
      rate = PaiseMath.effectiveCostPerGram(preGst, gramsX10000);
    } else {
      throw const ValidationFailure('Provide either Pre-GST Buy Rate/gm or Total Paid');
    }

    final txn = BullionTransactionModel(
      id: _uuid.v4(),
      userId: 'local',
      metal: metal,
      gramsX10000: gramsX10000,
      buyRatePaise: rate,
      preGstPaise: preGst,
      gstPaise: gst,
      totalPaidPaise: paid,
      purchaseDate: purchaseDate,
      platform: platform,
    );

    return _commit(
      state,
      state.copyWith(bullionTransactions: [txn, ...state.bullionTransactions]),
      eventType: 'BULLION_BUY',
      description:
          '${metal == 'gold' ? 'Gold 24K' : 'Silver'}: Bought ${txn.gramsFormatted} @ ${txn.rateFormatted} (Paid ${txn.totalPaidFormatted})',
      deltaPaise: paid,
      entityId: txn.id,
      entityName: metal,
    );
  }

  DhanflowAppState deleteBullionTransaction(DhanflowAppState state, String id) {
    final txn = state.bullionTransactions.firstWhere((t) => t.id == id);
    return _commit(
      state,
      state.copyWith(
          bullionTransactions: state.bullionTransactions.where((t) => t.id != id).toList()),
      eventType: 'ASSET_REMOVE',
      description: 'Removed ${txn.metal} holding (${txn.gramsFormatted} @ ${txn.rateFormatted})',
      deltaPaise: -txn.totalPaidPaise,
      entityId: txn.id,
      entityName: txn.metal,
    );
  }

  DhanflowAppState addPersonalAsset(
    DhanflowAppState state, {
    required String title,
    required String category,
    String quantityLabel = '1 Unit',
    required int purchaseValuePaise,
    required int currentValuePaise,
    String note = '',
    DateTime? acquiredDate,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) throw const ValidationFailure('Asset title is required');
    if (currentValuePaise < 0 || purchaseValuePaise < 0) {
      throw const ValidationFailure('Asset values cannot be negative');
    }
    final now = DateTime.now();
    final asset = PersonalAssetModel(
      id: _uuid.v4(),
      userId: 'local',
      title: trimmed,
      category: category.toLowerCase(),
      quantityLabel: quantityLabel.trim().isEmpty ? '1 Unit' : quantityLabel.trim(),
      purchaseValuePaise: purchaseValuePaise,
      currentValuePaise: currentValuePaise,
      note: note.trim(),
      acquiredDate: acquiredDate ?? now,
      createdAt: now,
    );
    return _commit(
      state,
      state.copyWith(personalAssets: [asset, ...state.personalAssets]),
      eventType: 'ASSET_ADD',
      description:
          'Added ${asset.categoryLabel}: ${asset.title} (${asset.quantityLabel}) valued at ${asset.currentValueFormatted}',
      deltaPaise: asset.currentValuePaise,
      entityId: asset.id,
      entityName: asset.title,
    );
  }

  DhanflowAppState updatePersonalAsset(
    DhanflowAppState state, {
    required String assetId,
    required String title,
    required String category,
    required String quantityLabel,
    required int purchaseValuePaise,
    required int currentValuePaise,
    required String note,
  }) {
    final existing = state.personalAssets.firstWhere((a) => a.id == assetId);
    final updated = existing.copyWith(
      title: title.trim().isEmpty ? existing.title : title.trim(),
      category: category.toLowerCase(),
      quantityLabel: quantityLabel.trim().isEmpty ? '1 Unit' : quantityLabel.trim(),
      purchaseValuePaise: purchaseValuePaise,
      currentValuePaise: currentValuePaise,
      note: note.trim(),
    );
    final updatedList =
        state.personalAssets.map((a) => a.id == assetId ? updated : a).toList();
    return _commit(
      state,
      state.copyWith(personalAssets: updatedList),
      eventType: 'ASSET_UPDATE',
      description:
          'Updated ${updated.title}: valuation ${existing.currentValueFormatted} → ${updated.currentValueFormatted}',
      deltaPaise: updated.currentValuePaise - existing.currentValuePaise,
      entityId: updated.id,
      entityName: updated.title,
    );
  }

  DhanflowAppState deletePersonalAsset(DhanflowAppState state, String assetId) {
    final existing = state.personalAssets.firstWhere((a) => a.id == assetId);
    return _commit(
      state,
      state.copyWith(
        personalAssets: state.personalAssets.where((a) => a.id != assetId).toList(),
      ),
      eventType: 'ASSET_REMOVE',
      description: 'Removed asset: ${existing.title} (${existing.currentValueFormatted})',
      deltaPaise: -existing.currentValuePaise,
      entityId: existing.id,
      entityName: existing.title,
    );
  }

  DhanflowAppState logExportBackup(DhanflowAppState state) {
    return _commit(
      state,
      state,
      eventType: 'EXPORT',
      description: 'Exported portable JSON financial snapshot',
    );
  }

  DhanflowAppState updateSellPrice(
    DhanflowAppState state, {
    required String metal,
    int? sellPricePaise,
  }) {
    final updatedSettings = metal == 'gold'
        ? state.settings.copyWith(goldCurrentSellPaise: () => sellPricePaise)
        : state.settings.copyWith(silverCurrentSellPaise: () => sellPricePaise);
    final updated = state.copyWith(settings: updatedSettings);
    LocalStorageService.saveState(updated);
    return updated;
  }

  // ── SETTINGS / DEBT ENGINE / BACKUP / UNDO ────────────────────

  DhanflowAppState updateThemeMode(DhanflowAppState state, String mode) {
    final updated = state.copyWith(
      settings: state.settings.copyWith(themeMode: mode),
    );
    LocalStorageService.saveState(updated);
    return updated;
  }

  DhanflowAppState updateDebtEngineSettings(
    DhanflowAppState state, {
    String? strategy,
    int? monthlyBudgetPaise,
  }) {
    final updated = state.copyWith(
      settings: state.settings.copyWith(
        debtPayoffStrategy: strategy,
        monthlyPaymentCapacityPaise: monthlyBudgetPaise,
      ),
    );
    LocalStorageService.saveState(updated);
    return updated;
  }

  DhanflowAppState? undoLastAction(DhanflowAppState current) {
    return LocalStorageService.popUndoSnapshot(current);
  }

  DhanflowAppState importBackupJson(DhanflowAppState current, String rawJson) {
    final parsed = ExportService.parseAndValidateJson(rawJson);
    LocalStorageService.pushUndoSnapshot(current);
    final withLog = parsed.copyWith(
      lastUpdated: DateTime.now(),
      activityLog: [
        ActivityLogModel(
          id: _uuid.v4(),
          eventType: 'IMPORT',
          description: 'Restored financial snapshot from JSON backup',
          createdAt: DateTime.now(),
        ),
        ...parsed.activityLog,
      ].take(300).toList(),
    );
    LocalStorageService.saveState(withLog);
    return withLog;
  }

  DhanflowAppState resetToSeed(DhanflowAppState current) {
    LocalStorageService.clearUndoStack();
    final seed = SeedService.createInitialState(apiBaseUrl: current.settings.apiBaseUrl);
    LocalStorageService.saveState(seed);
    return seed;
  }

  DhanflowAppState updateApiBaseUrl(DhanflowAppState current, String url) {
    final normalized = ApiConstants.normalizeBaseUrl(url);
    final next = current.copyWith(
      settings: current.settings.copyWith(apiBaseUrl: normalized),
    );
    LocalStorageService.saveState(next);
    apiClient.updateBaseUrl(normalized);
    return next;
  }

  // ── CLOUD SYNC (VERCEL PHP API) ───────────────────────────────

  bool get isAuthenticated => LocalStorageService.getTokens() != null;

  Future<void> pushLocalSnapshotToCloud(
    DhanflowAppState state, {
    bool silent = true,
  }) async {
    apiClient.updateBaseUrl(state.settings.apiBaseUrl);
    final payload = state.toJson();
    payload['silent'] = silent;
    final res = await apiClient.post(ApiConstants.backupImport, data: payload);
    if (res.data['success'] != true) {
      throw Failure(res.data['message'] as String? ?? 'Cloud sync failed');
    }
  }

  Future<DhanflowAppState> pullCloudSnapshot(DhanflowAppState current) async {
    apiClient.updateBaseUrl(current.settings.apiBaseUrl);
    final res = await apiClient.get(ApiConstants.backupExport);
    if (res.data['success'] != true) {
      throw Failure(res.data['message'] as String? ?? 'Cloud restore failed');
    }
    final data = res.data['data'] as Map<String, dynamic>;
    final rawSettings = data['user_settings'] as Map<String, dynamic>?;
    final mergedSettings = {
      ...?rawSettings,
      'api_base_url': current.settings.apiBaseUrl,
    };
    final cloudState = DhanflowAppState.fromJson({
      ...data,
      'user_settings': mergedSettings,
    });
    LocalStorageService.pushUndoSnapshot(current);
    LocalStorageService.saveState(cloudState);
    return cloudState;
  }
}
