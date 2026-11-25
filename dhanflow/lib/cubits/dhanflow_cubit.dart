import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/kpi_snapshot.dart';
import '../models/models.dart';
import '../repositories/dhanflow_repository.dart';
import '../services/debt_engine.dart';
import '../services/kpi_calculator.dart';

class DhanflowViewState extends Equatable {
  final DhanflowAppState appState;
  final KPISnapshot kpis;
  final DebtPayoffPlan payoffPlan;
  final bool canUndo;
  final bool isSyncing;
  final String? flashMessage;
  final String? errorMessage;

  const DhanflowViewState({
    required this.appState,
    required this.kpis,
    required this.payoffPlan,
    required this.canUndo,
    this.isSyncing = false,
    this.flashMessage,
    this.errorMessage,
  });

  DhanflowViewState copyWith({
    DhanflowAppState? appState,
    KPISnapshot? kpis,
    DebtPayoffPlan? payoffPlan,
    bool? canUndo,
    bool? isSyncing,
    String? Function()? flashMessage,
    String? Function()? errorMessage,
  }) =>
      DhanflowViewState(
        appState: appState ?? this.appState,
        kpis: kpis ?? this.kpis,
        payoffPlan: payoffPlan ?? this.payoffPlan,
        canUndo: canUndo ?? this.canUndo,
        isSyncing: isSyncing ?? this.isSyncing,
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
        flashMessage,
        errorMessage
      ];
}

class DhanflowCubit extends Cubit<DhanflowViewState> {
  final DhanflowRepository repository;

  DhanflowCubit({required this.repository}) : super(_initialState(repository));

  static DhanflowViewState _initialState(DhanflowRepository repo) {
    final appState = repo.loadLocalState();
    return _buildViewState(appState, repo.canUndo);
  }

  static DhanflowViewState _buildViewState(
    DhanflowAppState appState,
    bool canUndo, {
    String? flash,
    String? error,
    bool isSyncing = false,
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
      flashMessage: flash,
      errorMessage: error,
    );
  }

  void _apply(DhanflowAppState Function(DhanflowAppState s) mutation,
      {String? successMsg}) {
    try {
      final next = mutation(state.appState);
      emit(_buildViewState(next, repository.canUndo, flash: successMsg));
    } catch (e) {
      emit(state.copyWith(errorMessage: () => e.toString()));
    }
  }

  void clearMessages() {
    emit(state.copyWith(flashMessage: () => null, errorMessage: () => null));
  }

  void updateCardAvailableLimit(String cardId, int newAvailablePaise) => _apply(
        (s) => repository.updateCardAvailableLimit(s,
            cardId: cardId, newAvailablePaise: newAvailablePaise),
        successMsg: 'Available limit updated',
      );

  void recordCardTransaction(String cardId,
          {required bool isPayment,
          required int amountPaise,
          String note = ''}) =>
      _apply(
        (s) => repository.recordCardTransaction(s,
            cardId: cardId,
            isPayment: isPayment,
            amountPaise: amountPaise,
            note: note),
        successMsg: isPayment ? 'Payment recorded' : 'Spend recorded',
      );

  void updateCardDetails(String cardId,
          {required int newTotalLimitPaise,
          String? categoryTag,
          int? aprBps}) =>
      _apply(
        (s) => repository.updateCardDetails(s,
            cardId: cardId,
            newTotalLimitPaise: newTotalLimitPaise,
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
        (s) => repository.payPersonalPayable(s,
            payableId: payableId, amountPaise: amountPaise),
        successMsg: 'Payable updated',
      );

  void addPersonalPayable(
          {required String name, required int amountPaise, String note = ''}) =>
      _apply(
        (s) => repository.addPersonalPayable(s,
            name: name, amountPaise: amountPaise, note: note),
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

  void addBorrower(
          {required String name, required int amountPaise, String note = ''}) =>
      _apply(
        (s) => repository.addBorrower(s,
            name: name, amountPaise: amountPaise, note: note),
        successMsg: '$name added',
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
  }) =>
      _apply(
        (s) => repository.addBullionPurchase(s,
            metal: metal,
            gramsX10000: gramsX10000,
            buyRatePaise: buyRatePaise,
            totalPaidPaise: totalPaidPaise,
            purchaseDate: purchaseDate),
        successMsg: 'Bullion purchase added',
      );

  void deleteBullionTransaction(String id) => _apply(
        (s) => repository.deleteBullionTransaction(s, id),
        successMsg: 'Transaction removed',
      );

  void updateSellPrice(String metal, int? sellPricePaise) {
    final next = repository.updateSellPrice(state.appState,
        metal: metal, sellPricePaise: sellPricePaise);
    emit(_buildViewState(next, repository.canUndo));
  }

  void updateDebtEngine({String? strategy, int? monthlyBudgetPaise}) {
    final next = repository.updateDebtEngineSettings(state.appState,
        strategy: strategy, monthlyBudgetPaise: monthlyBudgetPaise);
    emit(_buildViewState(next, repository.canUndo));
  }

  void undoLastAction() {
    final restored = repository.undoLastAction(state.appState);
    if (restored != null) {
      emit(_buildViewState(restored, repository.canUndo,
          flash: 'Reverted last action'));
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
    final next = state.appState.copyWith(
      settings: state.appState.settings.copyWith(apiBaseUrl: url.trim()),
    );
    repository.apiClient.updateBaseUrl(url);
    emit(_buildViewState(next, repository.canUndo, flash: 'API URL updated'));
  }

  Future<void> pushToCloud() async {
    emit(state.copyWith(isSyncing: true));
    try {
      await repository.pushLocalSnapshotToCloud(state.appState);
      emit(_buildViewState(state.appState, repository.canUndo,
          flash: 'Synced to Vercel PHP Cloud'));
    } catch (e) {
      emit(_buildViewState(state.appState, repository.canUndo,
          error: e.toString()));
    }
  }

  Future<void> pullFromCloud() async {
    emit(state.copyWith(isSyncing: true));
    try {
      final restored = await repository.pullCloudSnapshot(state.appState);
      emit(_buildViewState(restored, repository.canUndo,
          flash: 'Pulled latest cloud snapshot'));
    } catch (e) {
      emit(_buildViewState(state.appState, repository.canUndo,
          error: e.toString()));
    }
  }
}
