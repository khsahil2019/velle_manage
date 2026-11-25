import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dhanflow/core/errors/failures.dart';
import 'package:dhanflow/core/network/api_client.dart';
import 'package:dhanflow/core/utils/inr_formatter.dart';
import 'package:dhanflow/main.dart';
import 'package:dhanflow/repositories/dhanflow_repository.dart';
import 'package:dhanflow/services/debt_engine.dart';
import 'package:dhanflow/services/export_service.dart';
import 'package:dhanflow/services/kpi_calculator.dart';
import 'package:dhanflow/services/local_storage_service.dart';
import 'package:dhanflow/services/seed_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('dhanflow_test_');
    Hive.init(tempDir.path);
    await LocalStorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('INRFormatter & PaiseMath', () {
    test('formats Indian lakh/crore grouping accurately', () {
      expect(INRFormatter.formatPaise(17479984), '₹1,74,799.84');
      expect(INRFormatter.formatPaise(5224100), '₹52,241.00');
      expect(INRFormatter.formatPaise(-634976), '-₹6,349.76');
      expect(INRFormatter.formatPaise(0), '₹0.00');
      expect(INRFormatter.formatPaise(15847236), '₹1,58,472.36');
    });
  });

  group('Seed Snapshot & KPICalculator Accuracy', () {
    test('exact initial financial snapshot matches all targets to the paise',
        () {
      final seed = SeedService.createInitialState();
      final kpi = KPICalculator.compute(seed);

      expect(kpi.totalCCOutstandingPaise, 17479984); // ₹1,74,799.84
      expect(kpi.totalCCLimitPaise, 69800000); // ₹6,98,000.00
      expect(kpi.totalLoanRemainingPaise, 5224100); // ₹52,241.00
      expect(kpi.totalPayablesPaise, 560000); // ₹5,600.00
      expect(kpi.kulDenaPaise, 23264084); // ₹2,32,640.84
      expect(kpi.kulLenaPaise, 17175911); // ₹1,71,759.11
      expect(kpi.asalNetDebtPaise, 6088173); // ₹60,881.73
      expect(kpi.gullakAssetPaise, 867689); // ₹8,676.89
      expect(kpi.trueNetLiabilityPaise, 5220484); // ₹52,204.84
      expect(kpi.pocketDebtPaise, 5818201); // ₹58,182.01
      expect(kpi.clearedCardsCount, 3);
      expect(kpi.totalCardsCount, 8);

      // Gold 24K
      expect(kpi.goldStats.totalGramsX10000, 5000); // 0.5000 gm
      expect(kpi.goldStats.weightedAvgRatePaise, 1269952); // ₹12,699.52/gm
      expect(kpi.goldStats.preGstAssetPaise, 634976); // ₹6,349.76
      expect(kpi.goldStats.totalCashPaidPaise, 654026); // ₹6,540.26

      // Silver
      expect(kpi.silverStats.totalGramsX10000, 150005); // 15.0005 gm
      expect(kpi.silverStats.weightedAvgRatePaise, 15514); // ₹155.14/gm
      expect(kpi.silverStats.preGstAssetPaise, 232713); // ₹2,327.13
      expect(kpi.silverStats.totalCashPaidPaise, 239695); // ₹2,396.95
    });
  });

  group('Repository Domain Operations & Integrity Rules', () {
    test('Recovery-to-Card link updates both Nripen and PNB Card atomically',
        () {
      final repo = DhanflowRepository(apiClient: ApiClient());
      final initial = repo.resetToSeed(SeedService.createInitialState());

      final nripen = initial.recoveries.firstWhere((r) => r.name == 'Nripen');
      final pnb = initial.creditCards.firstWhere((c) => c.name == 'PNB Card');

      final updated = repo.recordRecoveryPayment(
        initial,
        recoveryId: nripen.id,
        amountPaise: 683500,
        note: 'Settled via UPI',
        linkedCardId: pnb.id,
      );

      final nripenAfter =
          updated.recoveries.firstWhere((r) => r.id == nripen.id);
      final pnbAfter = updated.creditCards.firstWhere((c) => c.id == pnb.id);

      expect(nripenAfter.totalPendingPaise, 0);
      expect(nripenAfter.isSettled, isTrue);
      expect(pnbAfter.outstandingPaise,
          1761930); // ₹24,454.30 - ₹6,835.00 = ₹17,619.30
    });

    test('Mark 1 EMI paid + limit decrease protection + immutable undo', () {
      final repo = DhanflowRepository(apiClient: ApiClient());
      var state = repo.resetToSeed(SeedService.createInitialState());

      final dmi = state.loans.firstWhere((l) => l.name == 'DMI Finance Loan');
      state = repo.markLoanEmiPaid(state, dmi.id);
      final dmiAfter = state.loans.firstWhere((l) => l.id == dmi.id);
      expect(dmiAfter.remainingEmis, 6);
      expect(dmiAfter.totalRemainingPaise, 4477800); // ₹44,778.00

      // Limit decrease below outstanding must throw ValidationFailure
      final sbi = state.creditCards.firstWhere((c) => c.name == 'SBI Card');
      expect(
        () => repo.updateCardDetails(state,
            cardId: sbi.id, newTotalLimitPaise: 5000000),
        throwsA(isA<ValidationFailure>()),
      );

      // Undo restores DMI back to 7 EMIs while adding a REVERSAL log entry
      final undone = repo.undoLastAction(state)!;
      final dmiRestored = undone.loans.firstWhere((l) => l.id == dmi.id);
      expect(dmiRestored.remainingEmis, 7);
      expect(undone.activityLog.first.eventType, 'REVERSAL');
    });

    test('JSON export & import round-trip preserves exact state', () {
      final repo = DhanflowRepository(apiClient: ApiClient());
      final initial = repo.resetToSeed(SeedService.createInitialState());
      final jsonStr = ExportService.toPrettyJson(initial);
      final imported = repo.importBackupJson(initial, jsonStr);
      expect(KPICalculator.compute(imported).kulDenaPaise, 23264084);
      expect(KPICalculator.compute(imported).trueNetLiabilityPaise, 5220484);
    });
  });

  group('Debt Freedom Engine', () {
    test('Snowball targets Roar Card first and computes freedom timeline', () {
      final seed = SeedService.createInitialState();
      final plan = DebtEngine.simulate(
        state: seed,
        strategy: 'snowball',
        monthlyBudgetPaise: 3000000,
      );
      expect(plan.nextTarget, 'Roar Card');
      expect(plan.monthsToFreedom, greaterThan(0));
      expect(plan.payoffOrder.length, greaterThanOrEqualTo(6));
    });
  });

  group('DHANFLOW Widget Smoke Test', () {
    testWidgets('Renders Overview KPIs and navigates across all 5 tabs',
        (tester) async {
      final repo = DhanflowRepository(apiClient: ApiClient());
      repo.resetToSeed(SeedService.createInitialState());

      await tester.pumpWidget(DhanflowApp(
        apiClient: ApiClient(),
        repository: repo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('DHANFLOW'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('₹2,32,640.84'), findsWidgets);
      expect(find.text('₹1,71,759.11'), findsWidgets);
      expect(find.text('₹52,204.84'), findsWidgets);

      await tester.tap(find.text('Debt'));
      await tester.pumpAndSettle();
      expect(find.text('SBI Card'), findsOneWidget);

      await tester.tap(find.text('Kul Lena'));
      await tester.pumpAndSettle();
      expect(find.text('Sakshi'), findsOneWidget);

      await tester.tap(find.text('Bullion'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Gold 24K'), findsWidgets);

      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(find.text('Export JSON'), findsOneWidget);
    });
  });

  group('Seed Snapshot & KPICalculator Accuracy', () {
    test('exact initial financial snapshot matches all targets to the paise', () {
      final seed = SeedService.createInitialState();
      final kpi = KPICalculator.compute(seed);

      expect(kpi.totalCCOutstandingPaise, 17479984); // ₹1,74,799.84
      expect(kpi.totalCCLimitPaise, 69800000); // ₹6,98,000.00
      expect(kpi.totalLoanRemainingPaise, 5224100); // ₹52,241.00
      expect(kpi.totalPayablesPaise, 560000); // ₹5,600.00
      expect(kpi.kulDenaPaise, 23264084); // ₹2,32,640.84
      expect(kpi.kulLenaPaise, 17175911); // ₹1,71,759.11
      expect(kpi.asalNetDebtPaise, 6088173); // ₹60,881.73
      expect(kpi.gullakAssetPaise, 867689); // ₹8,676.89
      expect(kpi.trueNetLiabilityPaise, 5220484); // ₹52,204.84
      expect(kpi.pocketDebtPaise, 5818201); // ₹58,182.01
      expect(kpi.clearedCardsCount, 3);
      expect(kpi.totalCardsCount, 8);

      // Gold 24K
      expect(kpi.goldStats.totalGramsX10000, 5000); // 0.5000 gm
      expect(kpi.goldStats.weightedAvgRatePaise, 1269952); // ₹12,699.52/gm
      expect(kpi.goldStats.preGstAssetPaise, 634976); // ₹6,349.76
      expect(kpi.goldStats.totalCashPaidPaise, 654026); // ₹6,540.26

      // Silver
      expect(kpi.silverStats.totalGramsX10000, 150005); // 15.0005 gm
      expect(kpi.silverStats.weightedAvgRatePaise, 15514); // ₹155.14/gm
      expect(kpi.silverStats.preGstAssetPaise, 232713); // ₹2,327.13
      expect(kpi.silverStats.totalCashPaidPaise, 239695); // ₹2,396.95
    });
  });

  group('Repository Domain Operations & Integrity Rules', () {
    test('Recovery-to-Card link updates both Nripen and PNB Card atomically', () {
      final repo = DhanflowRepository(apiClient: ApiClient());
      final initial = repo.resetToSeed(SeedService.createInitialState());

      final nripen = initial.recoveries.firstWhere((r) => r.name == 'Nripen');
      final pnb = initial.creditCards.firstWhere((c) => c.name == 'PNB Card');

      final updated = repo.recordRecoveryPayment(
        initial,
        recoveryId: nripen.id,
        amountPaise: 683500,
        note: 'Settled via UPI',
        linkedCardId: pnb.id,
      );

      final nripenAfter = updated.recoveries.firstWhere((r) => r.id == nripen.id);
      final pnbAfter = updated.creditCards.firstWhere((c) => c.id == pnb.id);

      expect(nripenAfter.totalPendingPaise, 0);
      expect(nripenAfter.isSettled, isTrue);
      expect(pnbAfter.outstandingPaise, 1761930); // ₹24,454.30 - ₹6,835.00 = ₹17,619.30
    });

    test('Mark 1 EMI paid + limit decrease protection + immutable undo', () {
      final repo = DhanflowRepository(apiClient: ApiClient());
      var state = repo.resetToSeed(SeedService.createInitialState());

      final dmi = state.loans.firstWhere((l) => l.name == 'DMI Finance Loan');
      state = repo.markLoanEmiPaid(state, dmi.id);
      final dmiAfter = state.loans.firstWhere((l) => l.id == dmi.id);
      expect(dmiAfter.remainingEmis, 6);
      expect(dmiAfter.totalRemainingPaise, 4477800); // ₹44,778.00

      // Limit decrease below outstanding must throw ValidationFailure
      final sbi = state.creditCards.firstWhere((c) => c.name == 'SBI Card');
      expect(
        () => repo.updateCardDetails(state, cardId: sbi.id, newTotalLimitPaise: 5000000),
        throwsA(isA<ValidationFailure>()),
      );

      // Undo restores DMI back to 7 EMIs while adding a REVERSAL log entry
      final undone = repo.undoLastAction(state)!;
      final dmiRestored = undone.loans.firstWhere((l) => l.id == dmi.id);
      expect(dmiRestored.remainingEmis, 7);
      expect(undone.activityLog.first.eventType, 'REVERSAL');
    });

    test('JSON export & import round-trip preserves exact state', () {
      final repo = DhanflowRepository(apiClient: ApiClient());
      final initial = repo.resetToSeed(SeedService.createInitialState());
      final jsonStr = ExportService.toPrettyJson(initial);
      final imported = repo.importBackupJson(initial, jsonStr);
      expect(KPICalculator.compute(imported).kulDenaPaise, 23264084);
      expect(KPICalculator.compute(imported).trueNetLiabilityPaise, 5220484);
    });
  });

  group('Debt Freedom Engine', () {
    test('Snowball targets Roar Card first and computes freedom timeline', () {
      final seed = SeedService.createInitialState();
      final plan = DebtEngine.simulate(
        state: seed,
        strategy: 'snowball',
        monthlyBudgetPaise: 3000000,
      );
      expect(plan.nextTarget, 'Roar Card');
      expect(plan.monthsToFreedom, greaterThan(0));
      expect(plan.payoffOrder.length, greaterThanOrEqualTo(6));
    });
  });

  group('DHANFLOW Widget Smoke Test', () {
    testWidgets('Renders Overview KPIs and navigates across all 5 tabs', (tester) async {
      final repo = DhanflowRepository(apiClient: ApiClient());
      repo.resetToSeed(SeedService.createInitialState());

      await tester.pumpWidget(DhanflowApp(
        apiClient: ApiClient(),
        repository: repo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('DHANFLOW'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('₹2,32,640.84'), findsWidgets);
      expect(find.text('₹1,71,759.11'), findsWidgets);
      expect(find.text('₹52,204.84'), findsWidgets);

      await tester.tap(find.text('Debt'));
      await tester.pumpAndSettle();
      expect(find.text('SBI Card'), findsOneWidget);

      await tester.tap(find.text('Kul Lena'));
      await tester.pumpAndSettle();
      expect(find.text('Sakshi'), findsOneWidget);

      await tester.tap(find.text('Bullion'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Gold 24K'), findsWidgets);

      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(find.text('Export JSON'), findsOneWidget);
    });
  });
}
