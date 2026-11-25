import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/kpi_snapshot.dart';
import '../models/models.dart';
import '../repositories/dhanflow_repository.dart';
import '../services/debt_engine.dart';
import '../services/kpi_calculator.dart';

enum CloudSyncStatus { offline, syncing, synced, error }

class DhanflowViewState extends Equatable {
  final DhanflowAppState appState;
  final KPISnapshot kpis;
  final DebtPayoffPlan payoffPlan;
  final bool canUndo;
  final bool isSyncing;
  final CloudSyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final bool hideBalances;
  final String? flashMessage;
  final String? errorMessage;

  const DhanflowViewState({
    required this.appState,
    required this.kpis,
    required this.payoffPlan,
    required this.canUndo,
    this.isSyncing = false,
    this.syncStatus = CloudSyncStatus.offline,
    this.lastSyncedAt,
    this.hideBalances = false,
    this.flashMessage,
    this.errorMessage,
  });

  DhanflowViewState copyWith({
    DhanflowAppState? appState,
    KPISnapshot? kpis,
    DebtPayoffPlan? payoffPlan,
    bool? canUndo,
    bool? isSyncing,
    CloudSyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool? hideBalances,
    String? Function()? flashMessage,
    String? Function()? errorMessage,
  }) =>
      DhanflowViewState(
        appState: appState ?? this.appState,
        kpis: kpis ?? this.kpis,
        payoffPlan: payoffPlan ?? this.payoffPlan,
        canUndo: canUndo ?? this.canUndo,
        isSyncing: isSyncing ?? this.isSyncing,
        syncStatus: syncStatus ?? this.syncStatus,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        hideBalances: hideBalances ?? this.hideBalances,
        flashMessage: flashMessage != null ? flashMessage() : null,
        errorMessage: errorMessage != null ? errorMessage() : null,
      );

  @override
  List<Object?> get props => [
        appState,
        kpis,
        payoffPlan,
        canUndo,
        isSyncing,
        syncStatus,
        lastSyncedAt,
        hideBalances,
        flashMessage,
        errorMessage,
      ];
}

class DhanflowCubit extends Cubit<DhanflowViewState> {
  final DhanflowRepository repository;
  Timer? _syncDebounce;

  DhanflowCubit({required this.repository}) : super(_initialState(repository));

  static DhanflowViewState _initialState(DhanflowRepository repo) {
    final appState = repo.loadLocalState();
    return _buildViewState(
      appState,
      repo.canUndo,
      syncStatus: repo.isAuthenticated ? CloudSyncStatus.synced : CloudSyncStatus.offline,
    );
  }

  static DhanflowViewState _buildViewState(
    DhanflowAppState appState,
    bool canUndo, {
    String? flash,
    String? error,
    bool isSyncing = false,
    CloudSyncStatus syncStatus = CloudSyncStatus.offline,
    DateTime? lastSyncedAt,
    bool hideBalances = false,
  }) {
    final kpis = KPICalculator.compute(appState);
    final plan = DebtEngine.simulate(
      state: appState,
      strategy: appState.settings.debtPayoffStrategy,
      monthlyBudgetPaise: appState.settings.monthlyPaymentCapacityPaise,
    );
    return DhanflowViewState(
      appState: appState,
      kpis: kpis,
      payoffPlan: plan,
      canUndo: canUndo,
      isSyncing: isSyncing,
      syncStatus: syncStatus,
      lastSyncedAt: lastSyncedAt,
      hideBalances: hideBalances,
      flashMessage: flash,
      errorMessage: error,
    );
  }

  void toggleHideBalances() {
    emit(state.copyWith(hideBalances: !state.hideBalances));
  }

  void _apply(DhanflowAppState Function(DhanflowAppState s) mutation, {String? successMsg}) {
    try {
      final next = mutation(state.appState);
      final authed = repository.isAuthenticated;
      emit(_buildViewState(
        next,
        repository.canUndo,
        flash: successMsg,
        syncStatus: authed ? CloudSyncStatus.syncing : CloudSyncStatus.offline,
        lastSyncedAt: state.lastSyncedAt,
        hideBalances: state.hideBalances,
      ));
      if (authed) {
        _scheduleAutoCloudSync();
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: () => e.toString()));
    }
  }

  void _scheduleAutoCloudSync() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 650), () async {
      await _syncSilently();
    });
  }

  Future<void> _syncSilently() async {
    if (!repository.isAuthenticated) return;
    try {
      await repository.pushLocalSnapshotToCloud(state.appState, silent: true);
      if (!isClosed) {
        emit(state.copyWith(
          isSyncing: false,
          syncStatus: CloudSyncStatus.synced,
          lastSyncedAt: DateTime.now(),
        ));
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          isSyncing: false,
          syncStatus: CloudSyncStatus.error,
        ));
      }
    }
  }

  /// Called automatically after Sign In or Sign Up succeeds.
  Future<void> handleAuthConnected({
    required bool justSignedUp,
    required bool uploadLocalOnSignup,
  }) async {
    if (justSignedUp && uploadLocalOnSignup) {
      await pushToCloud();
    } else {
      await pullFromCloud();
    }
  }

  void handleSignedOut() {
    _syncDebounce?.cancel();
    emit(state.copyWith(
      isSyncing: false,
      syncStatus: CloudSyncStatus.offline,
      flashMessage: () => 'Signed out — switched to local storage mode',
    ));
  }

  void clearMessages() {
    emit(state.copyWith(flashMessage: () => null, errorMessage: () => null));
  }

  void updateCardAvailableLimit(String cardId, int newAvailablePaise) => _apply(
        (s) => repository.updateCardAvailableLimit(s,
            cardId: cardId, newAvailablePaise: newAvailablePaise),
        successMsg: 'Available limit updated',
      );

  void recordCardTransaction(String cardId, {required bool isPayment, required int amountPaise, String note = ''}) =>
      _apply(
        (s) => repository.recordCardTransaction(s,
            cardId: cardId, isPayment: isPayment, amountPaise: amountPaise, note: note),
        successMsg: isPayment ? 'Payment recorded' : 'Spend recorded',
      );

  void updateCardDetails(
    String cardId, {
    required int newTotalLimitPaise,
    String? name,
    String? categoryTag,
    int? aprBps,
  }) =>
      _apply(
        (s) => repository.updateCardDetails(s,
            cardId: cardId,
            newTotalLimitPaise: newTotalLimitPaise,
            name: name,
            categoryTag: categoryTag,
            aprBps: aprBps),
        successMsg: 'Card details updated',
      );

  void addCreditCard({
    required String name,
    required int totalLimitPaise,
    required int availableLimitPaise,
    required String categoryTag,
    int aprBps = 3600,
  }) =>
      _apply(
        (s) => repository.addCreditCard(s,
            name: name,
            totalLimitPaise: totalLimitPaise,
            availableLimitPaise: availableLimitPaise,
            categoryTag: categoryTag,
            aprBps: aprBps),
        successMsg: '$name added',
      );

  void removeCreditCard(String cardId) => _apply(
        (s) => repository.removeCreditCard(s, cardId),
        successMsg: 'Card removed',
      );

  void markLoanEmiPaid(String loanId) => _apply(
        (s) => repository.markLoanEmiPaid(s, loanId),
        successMsg: 'EMI marked paid',
      );

  void addLoan({
    required String name,
    required int emiAmountPaise,
    required int remainingEmis,
    String note = '',
    int aprBps = 1600,
  }) =>
      _apply(
        (s) => repository.addLoan(s,
            name: name,
            emiAmountPaise: emiAmountPaise,
            remainingEmis: remainingEmis,
            note: note,
            aprBps: aprBps),
        successMsg: '$name added',
      );

  void removeLoan(String loanId) => _apply(
        (s) => repository.removeLoan(s, loanId),
        successMsg: 'Loan removed',
      );

  void payPersonalPayable(String payableId, int amountPaise) => _apply(
        (s) => repository.payPersonalPayable(s, payableId: payableId, amountPaise: amountPaise),
        successMsg: 'Payable updated',
      );

  void addPersonalPayable({required String name, required int amountPaise, String note = ''}) =>
      _apply(
        (s) => repository.addPersonalPayable(s, name: name, amountPaise: amountPaise, note: note),
        successMsg: '$name added',
      );

  void removePayable(String id) => _apply(
        (s) => repository.removePayable(s, id),
        successMsg: 'Payable removed',
      );

  void recordRecoveryPayment({
    required String recoveryId,
    required int amountPaise,
    String note = '',
    String? linkedCardId,
  }) =>
      _apply(
        (s) => repository.recordRecoveryPayment(s,
            recoveryId: recoveryId,
            amountPaise: amountPaise,
            note: note,
            linkedCardId: linkedCardId),
        successMsg: linkedCardId != null
            ? 'Recovery recorded & applied to card'
            : 'Recovery payment recorded',
      );

  void addBorrower({required String name, required int amountPaise, String note = ''}) => _apply(
        (s) => repository.addBorrower(s, name: name, amountPaise: amountPaise, note: note),
        successMsg: '$name added',
      );

  void addAdvanceToRecovery({
    required String recoveryId,
    required int additionalAmountPaise,
    String note = '',
  }) =>
      _apply(
        (s) => repository.addAdvanceToRecovery(
          s,
          recoveryId: recoveryId,
          additionalAmountPaise: additionalAmountPaise,
          note: note,
        ),
        successMsg: 'Receivable amount added',
      );

  void updateBorrowerDetails({
    required String recoveryId,
    required String name,
    required int newPendingPaise,
    required String note,
  }) =>
      _apply(
        (s) => repository.updateBorrowerDetails(
          s,
          recoveryId: recoveryId,
          name: name,
          newPendingPaise: newPendingPaise,
          note: note,
        ),
        successMsg: 'Borrower updated',
      );

  void removeRecovery(String id) => _apply(
        (s) => repository.removeRecovery(s, id),
        successMsg: 'Recovery entry removed',
      );

  void addBullionPurchase({
    required String metal,
    required int gramsX10000,
    int? buyRatePaise,
    int? totalPaidPaise,
    required DateTime purchaseDate,
    String platform = 'Vault',
  }) =>
      _apply(
        (s) => repository.addBullionPurchase(s,
            metal: metal,
            gramsX10000: gramsX10000,
            buyRatePaise: buyRatePaise,
            totalPaidPaise: totalPaidPaise,
            purchaseDate: purchaseDate,
            platform: platform),
        successMsg: 'Asset purchase added',
      );

  void deleteBullionTransaction(String id) => _apply(
        (s) => repository.deleteBullionTransaction(s, id),
        successMsg: 'Entry removed',
      );

  void addPersonalAsset({
    required String title,
    required String category,
    String quantityLabel = '1 Unit',
    required int purchaseValuePaise,
    required int currentValuePaise,
    String note = '',
    DateTime? acquiredDate,
  }) =>
      _apply(
        (s) => repository.addPersonalAsset(
          s,
          title: title,
          category: category,
          quantityLabel: quantityLabel,
          purchaseValuePaise: purchaseValuePaise,
          currentValuePaise: currentValuePaise,
          note: note,
          acquiredDate: acquiredDate,
        ),
        successMsg: 'Asset added to vault',
      );

  void updatePersonalAsset({
    required String assetId,
    required String title,
    required String category,
    required String quantityLabel,
    required int purchaseValuePaise,
    required int currentValuePaise,
    required String note,
  }) =>
      _apply(
        (s) => repository.updatePersonalAsset(
          s,
          assetId: assetId,
          title: title,
          category: category,
          quantityLabel: quantityLabel,
          purchaseValuePaise: purchaseValuePaise,
          currentValuePaise: currentValuePaise,
          note: note,
        ),
        successMsg: 'Asset valuation updated',
      );

  void deletePersonalAsset(String assetId) => _apply(
        (s) => repository.deletePersonalAsset(s, assetId),
        successMsg: 'Asset removed',
      );

  void recordExportBackup() => _apply(
        (s) => repository.logExportBackup(s),
      );

  void updateSellPrice(String metal, int? sellPricePaise) {
    final next = repository.updateSellPrice(state.appState,
        metal: metal, sellPricePaise: sellPricePaise);
    emit(_buildViewState(
      next,
      repository.canUndo,
      syncStatus: repository.isAuthenticated ? CloudSyncStatus.syncing : CloudSyncStatus.offline,
      lastSyncedAt: state.lastSyncedAt,
      hideBalances: state.hideBalances,
    ));
    if (repository.isAuthenticated) _scheduleAutoCloudSync();
  }

  void updateDebtEngine({String? strategy, int? monthlyBudgetPaise}) {
    final next = repository.updateDebtEngineSettings(state.appState,
        strategy: strategy, monthlyBudgetPaise: monthlyBudgetPaise);
    emit(_buildViewState(
      next,
      repository.canUndo,
      syncStatus: repository.isAuthenticated ? CloudSyncStatus.syncing : CloudSyncStatus.offline,
      lastSyncedAt: state.lastSyncedAt,
      hideBalances: state.hideBalances,
    ));
    if (repository.isAuthenticated) _scheduleAutoCloudSync();
  }

  void toggleThemeMode() {
    final current = state.appState.settings.themeMode;
    final nextMode = current == 'light' ? 'dark' : 'light';
    setThemeMode(nextMode);
  }

  void setThemeMode(String mode) {
    final next = repository.updateThemeMode(state.appState, mode);
    emit(_buildViewState(
      next,
      repository.canUndo,
      syncStatus: state.syncStatus,
      lastSyncedAt: state.lastSyncedAt,
      hideBalances: state.hideBalances,
    ));
    if (repository.isAuthenticated) _scheduleAutoCloudSync();
  }

  void toggleLanguage() {
    final current = state.appState.settings.languageCode;
    setLanguageCode(current == 'hi' ? 'en' : 'hi');
  }

  void setLanguageCode(String code) {
    final next = repository.updateLanguageCode(state.appState, code);
    emit(_buildViewState(
      next,
      repository.canUndo,
      syncStatus: state.syncStatus,
      lastSyncedAt: state.lastSyncedAt,
      hideBalances: state.hideBalances,
    ));
    if (repository.isAuthenticated) _scheduleAutoCloudSync();
  }

  void undoLastAction() {
    final restored = repository.undoLastAction(state.appState);
    if (restored != null) {
      final authed = repository.isAuthenticated;
      emit(_buildViewState(
        restored,
        repository.canUndo,
        flash: 'Reverted last action',
        syncStatus: authed ? CloudSyncStatus.syncing : CloudSyncStatus.offline,
        lastSyncedAt: state.lastSyncedAt,
        hideBalances: state.hideBalances,
      ));
      if (authed) _scheduleAutoCloudSync();
    }
  }

  void importJson(String rawJson) => _apply(
        (s) => repository.importBackupJson(s, rawJson),
        successMsg: 'Backup restored successfully',
      );

  void resetToSeed() => _apply(
        (s) => repository.resetToSeed(s),
        successMsg: 'Reset to initial financial snapshot',
      );

  void updateApiBaseUrl(String url) {
    final next = repository.updateApiBaseUrl(state.appState, url);
    emit(_buildViewState(
      next,
      repository.canUndo,
      flash: 'API URL updated',
      syncStatus: state.syncStatus,
      lastSyncedAt: state.lastSyncedAt,
      hideBalances: state.hideBalances,
    ));
  }

  Future<void> pushToCloud() async {
    emit(state.copyWith(
      isSyncing: true,
      syncStatus: CloudSyncStatus.syncing,
    ));
    try {
      await repository.pushLocalSnapshotToCloud(state.appState, silent: false);
      emit(_buildViewState(
        state.appState,
        repository.canUndo,
        flash: 'Saved to Cloud Backend Storage',
        syncStatus: CloudSyncStatus.synced,
        lastSyncedAt: DateTime.now(),
        hideBalances: state.hideBalances,
      ));
    } catch (e) {
      emit(_buildViewState(
        state.appState,
        repository.canUndo,
        error: e.toString(),
        syncStatus: CloudSyncStatus.error,
        lastSyncedAt: state.lastSyncedAt,
        hideBalances: state.hideBalances,
      ));
    }
  }

  Future<void> pullFromCloud() async {
    emit(state.copyWith(
      isSyncing: true,
      syncStatus: CloudSyncStatus.syncing,
    ));
    try {
      final restored = await repository.pullCloudSnapshot(state.appState);
      emit(_buildViewState(
        restored,
        repository.canUndo,
        flash: 'Loaded financial data from Cloud Backend',
        syncStatus: CloudSyncStatus.synced,
        lastSyncedAt: DateTime.now(),
        hideBalances: state.hideBalances,
      ));
    } catch (e) {
      emit(_buildViewState(
        state.appState,
        repository.canUndo,
        error: e.toString(),
        syncStatus: CloudSyncStatus.error,
        lastSyncedAt: state.lastSyncedAt,
        hideBalances: state.hideBalances,
      ));
    }
  }

  @override
  Future<void> close() {
    _syncDebounce?.cancel();
    return super.close();
  }
}
