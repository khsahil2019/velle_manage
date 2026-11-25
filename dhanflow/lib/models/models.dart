import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/inr_formatter.dart';

class CreditCardModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final int totalLimitPaise;
  final int availableLimitPaise;
  final String categoryTag;
  final int displayOrder;
  final bool isActive;
  final int aprBps; // Basis points (e.g. 3600 = 36.00% APR) for Debt Freedom Engine
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreditCardModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.totalLimitPaise,
    required this.availableLimitPaise,
    required this.categoryTag,
    required this.displayOrder,
    required this.isActive,
    this.aprBps = 3600,
    required this.createdAt,
    required this.updatedAt,
  });

  int get outstandingPaise => (totalLimitPaise - availableLimitPaise).clamp(0, totalLimitPaise);

  double get utilizationPct {
    if (totalLimitPaise <= 0) return 0.0;
    return (outstandingPaise / totalLimitPaise) * 100;
  }

  bool get isCleared => outstandingPaise <= 0;
  bool get isCoveredByRecovery {
    final t = categoryTag.toLowerCase();
    return t.contains('covered by') ||
        t.contains('sakshi') ||
        name.toLowerCase() == 'sbi card';
  }

  String get outstandingFormatted => INRFormatter.formatPaise(outstandingPaise);
  String get availableFormatted => INRFormatter.formatPaise(availableLimitPaise);
  String get totalLimitFormatted => INRFormatter.formatPaise(totalLimitPaise);
  String get utilizationFormatted => INRFormatter.formatPct(utilizationPct);
  Color get utilizationColor => AppColors.utilizationColor(utilizationPct);

  factory CreditCardModel.fromJson(Map<String, dynamic> json) => CreditCardModel(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? 'local',
        name: json['name'] as String,
        totalLimitPaise: (json['total_limit'] as num).toInt(),
        availableLimitPaise: (json['available_limit'] as num).toInt(),
        categoryTag: json['category_tag'] as String? ?? '',
        displayOrder: (json['display_order'] as num? ?? 0).toInt(),
        isActive: (json['is_active'] as num? ?? 1) == 1,
        aprBps: (json['apr_bps'] as num? ?? 3600).toInt(),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'total_limit': totalLimitPaise,
        'available_limit': availableLimitPaise,
        'category_tag': categoryTag,
        'display_order': displayOrder,
        'is_active': isActive ? 1 : 0,
        'apr_bps': aprBps,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  CreditCardModel copyWith({
    int? availableLimitPaise,
    int? totalLimitPaise,
    String? categoryTag,
    String? name,
    int? aprBps,
    bool? isActive,
    DateTime? updatedAt,
  }) =>
      CreditCardModel(
        id: id,
        userId: userId,
        name: name ?? this.name,
        totalLimitPaise: totalLimitPaise ?? this.totalLimitPaise,
        availableLimitPaise: availableLimitPaise ?? this.availableLimitPaise,
        categoryTag: categoryTag ?? this.categoryTag,
        displayOrder: displayOrder,
        isActive: isActive ?? this.isActive,
        aprBps: aprBps ?? this.aprBps,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        totalLimitPaise,
        availableLimitPaise,
        categoryTag,
        displayOrder,
        isActive,
        aprBps,
        updatedAt,
      ];
}

class LoanModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final int emiAmountPaise;
  final int remainingEmis;
  final int originalEmis;
  final int totalRemainingPaise;
  final String note;
  final bool isActive;
  final int aprBps;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LoanModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.emiAmountPaise,
    required this.remainingEmis,
    required this.originalEmis,
    required this.totalRemainingPaise,
    required this.note,
    required this.isActive,
    this.aprBps = 1600,
    required this.createdAt,
    required this.updatedAt,
  });

  int get paidEmis => (originalEmis - remainingEmis).clamp(0, originalEmis);
  bool get isCleared => remainingEmis <= 0 || totalRemainingPaise <= 0;
  double get progressPct => originalEmis > 0 ? (paidEmis / originalEmis) : 0.0;

  String get emiFormatted => INRFormatter.formatPaise(emiAmountPaise);
  String get totalRemainingFormatted => INRFormatter.formatPaise(totalRemainingPaise);

  LoanModel copyWith({
    int? remainingEmis,
    int? totalRemainingPaise,
    bool? isActive,
    DateTime? updatedAt,
  }) =>
      LoanModel(
        id: id,
        userId: userId,
        name: name,
        emiAmountPaise: emiAmountPaise,
        remainingEmis: remainingEmis ?? this.remainingEmis,
        originalEmis: originalEmis,
        totalRemainingPaise: totalRemainingPaise ?? this.totalRemainingPaise,
        note: note,
        isActive: isActive ?? this.isActive,
        aprBps: aprBps,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  factory LoanModel.fromJson(Map<String, dynamic> json) => LoanModel(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? 'local',
        name: json['name'] as String,
        emiAmountPaise: (json['emi_amount'] as num).toInt(),
        remainingEmis: (json['remaining_emis'] as num).toInt(),
        originalEmis: (json['original_emis'] as num? ?? json['remaining_emis'] as num).toInt(),
        totalRemainingPaise: (json['total_remaining'] as num).toInt(),
        note: json['note'] as String? ?? '',
        isActive: (json['is_active'] as num? ?? 1) == 1,
        aprBps: (json['apr_bps'] as num? ?? 1600).toInt(),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'emi_amount': emiAmountPaise,
        'remaining_emis': remainingEmis,
        'original_emis': originalEmis,
        'total_remaining': totalRemainingPaise,
        'note': note,
        'is_active': isActive ? 1 : 0,
        'apr_bps': aprBps,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        emiAmountPaise,
        remainingEmis,
        originalEmis,
        totalRemainingPaise,
        isActive,
        updatedAt,
      ];
}

class PersonalPayableModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final int amountPaise;
  final String note;
  final bool isSettled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PersonalPayableModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.amountPaise,
    required this.note,
    required this.isSettled,
    required this.createdAt,
    required this.updatedAt,
  });

  String get amountFormatted => INRFormatter.formatPaise(amountPaise);

  PersonalPayableModel copyWith({
    int? amountPaise,
    bool? isSettled,
    DateTime? updatedAt,
  }) =>
      PersonalPayableModel(
        id: id,
        userId: userId,
        name: name,
        amountPaise: amountPaise ?? this.amountPaise,
        note: note,
        isSettled: isSettled ?? this.isSettled,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  factory PersonalPayableModel.fromJson(Map<String, dynamic> json) => PersonalPayableModel(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? 'local',
        name: json['name'] as String,
        amountPaise: (json['amount'] as num).toInt(),
        note: json['note'] as String? ?? '',
        isSettled: (json['is_settled'] as num? ?? 0) == 1,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'amount': amountPaise,
        'note': note,
        'is_settled': isSettled ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, name, amountPaise, note, isSettled, updatedAt];
}

class RecoveryPaymentModel extends Equatable {
  final String id;
  final String recoveryId;
  final int amountPaise;
  final String? appliedToCardId;
  final String note;
  final DateTime paymentDate;

  const RecoveryPaymentModel({
    required this.id,
    required this.recoveryId,
    required this.amountPaise,
    this.appliedToCardId,
    required this.note,
    required this.paymentDate,
  });

  String get amountFormatted => INRFormatter.formatPaise(amountPaise);

  factory RecoveryPaymentModel.fromJson(Map<String, dynamic> json) => RecoveryPaymentModel(
        id: json['id'] as String,
        recoveryId: json['recovery_id'] as String,
        amountPaise: (json['amount'] as num).toInt(),
        appliedToCardId: json['applied_to_card'] as String?,
        note: json['note'] as String? ?? '',
        paymentDate: DateTime.parse(json['payment_date'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recovery_id': recoveryId,
        'amount': amountPaise,
        'applied_to_card': appliedToCardId,
        'note': note,
        'payment_date': paymentDate.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, recoveryId, amountPaise, appliedToCardId, note, paymentDate];
}

class RecoveryModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final int totalOriginalPaise;
  final int totalPendingPaise;
  final String note;
  final bool isSettled;
  final List<RecoveryPaymentModel> payments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecoveryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.totalOriginalPaise,
    required this.totalPendingPaise,
    required this.note,
    required this.isSettled,
    required this.payments,
    required this.createdAt,
    required this.updatedAt,
  });

  int get recoveredPaise => totalOriginalPaise - totalPendingPaise;
  double get recoveryPct =>
      totalOriginalPaise > 0 ? (recoveredPaise / totalOriginalPaise * 100) : 0.0;

  String get pendingFormatted => INRFormatter.formatPaise(totalPendingPaise);
  String get originalFormatted => INRFormatter.formatPaise(totalOriginalPaise);

  RecoveryModel copyWith({
    int? totalPendingPaise,
    bool? isSettled,
    List<RecoveryPaymentModel>? payments,
    DateTime? updatedAt,
  }) =>
      RecoveryModel(
        id: id,
        userId: userId,
        name: name,
        totalOriginalPaise: totalOriginalPaise,
        totalPendingPaise: totalPendingPaise ?? this.totalPendingPaise,
        note: note,
        isSettled: isSettled ?? this.isSettled,
        payments: payments ?? this.payments,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  factory RecoveryModel.fromJson(Map<String, dynamic> json) => RecoveryModel(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? 'local',
        name: json['name'] as String,
        totalOriginalPaise: (json['total_original'] as num).toInt(),
        totalPendingPaise: (json['total_pending'] as num).toInt(),
        note: json['note'] as String? ?? '',
        isSettled: (json['is_settled'] as num? ?? 0) == 1,
        payments: (json['payments'] as List<dynamic>? ?? [])
            .map((p) => RecoveryPaymentModel.fromJson(p as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'total_original': totalOriginalPaise,
        'total_pending': totalPendingPaise,
        'note': note,
        'is_settled': isSettled ? 1 : 0,
        'payments': payments.map((p) => p.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, name, totalOriginalPaise, totalPendingPaise, isSettled, payments];
}

class BullionTransactionModel extends Equatable {
  final String id;
  final String userId;
  final String metal; // 'gold' | 'silver'
  final int gramsX10000;
  final int buyRatePaise;
  final int preGstPaise;
  final int gstPaise;
  final int totalPaidPaise;
  final DateTime purchaseDate;
  final String platform;

  const BullionTransactionModel({
    required this.id,
    required this.userId,
    required this.metal,
    required this.gramsX10000,
    required this.buyRatePaise,
    required this.preGstPaise,
    required this.gstPaise,
    required this.totalPaidPaise,
    required this.purchaseDate,
    required this.platform,
  });

  double get gramsDouble => gramsX10000 / 10000.0;
  String get gramsFormatted => INRFormatter.formatGrams(gramsX10000);
  String get rateFormatted => INRFormatter.formatRatePerGm(buyRatePaise);
  String get preGstFormatted => INRFormatter.formatPaise(preGstPaise);
  String get gstFormatted => INRFormatter.formatPaise(gstPaise);
  String get totalPaidFormatted => INRFormatter.formatPaise(totalPaidPaise);

  factory BullionTransactionModel.fromJson(Map<String, dynamic> json) =>
      BullionTransactionModel(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? 'local',
        metal: json['metal'] as String,
        gramsX10000: (json['grams_x10000'] as num).toInt(),
        buyRatePaise: (json['buy_rate_paise'] as num).toInt(),
        preGstPaise: (json['pre_gst_paise'] as num).toInt(),
        gstPaise: (json['gst_paise'] as num).toInt(),
        totalPaidPaise: (json['total_paid_paise'] as num).toInt(),
        purchaseDate: DateTime.parse(json['purchase_date'] as String),
        platform: json['platform'] as String? ?? 'Gullak',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'metal': metal,
        'grams_x10000': gramsX10000,
        'buy_rate_paise': buyRatePaise,
        'pre_gst_paise': preGstPaise,
        'gst_paise': gstPaise,
        'total_paid_paise': totalPaidPaise,
        'purchase_date': purchaseDate.toIso8601String(),
        'platform': platform,
      };

  @override
  List<Object?> get props => [
        id,
        metal,
        gramsX10000,
        buyRatePaise,
        preGstPaise,
        gstPaise,
        totalPaidPaise,
        purchaseDate,
      ];
}

class ActivityLogModel extends Equatable {
  final String id;
  final String eventType;
  final String description;
  final int? deltaPaise;
  final String? relatedEntityId;
  final String? relatedEntityName;
  final DateTime createdAt;
  final bool isReversed;

  const ActivityLogModel({
    required this.id,
    required this.eventType,
    required this.description,
    this.deltaPaise,
    this.relatedEntityId,
    this.relatedEntityName,
    required this.createdAt,
    this.isReversed = false,
  });

  ActivityLogModel copyWith({bool? isReversed}) => ActivityLogModel(
        id: id,
        eventType: eventType,
        description: description,
        deltaPaise: deltaPaise,
        relatedEntityId: relatedEntityId,
        relatedEntityName: relatedEntityName,
        createdAt: createdAt,
        isReversed: isReversed ?? this.isReversed,
      );

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) => ActivityLogModel(
        id: json['id'] as String,
        eventType: json['event_type'] as String? ?? 'SYSTEM',
        description: json['description'] as String,
        deltaPaise: (json['delta_paise'] as num?)?.toInt(),
        relatedEntityId: json['related_entity_id'] as String?,
        relatedEntityName: json['related_entity_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        isReversed: (json['is_reversed'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_type': eventType,
        'description': description,
        'delta_paise': deltaPaise,
        'related_entity_id': relatedEntityId,
        'related_entity_name': relatedEntityName,
        'created_at': createdAt.toIso8601String(),
        'is_reversed': isReversed,
      };

  @override
  List<Object?> get props => [id, eventType, description, deltaPaise, createdAt, isReversed];
}

class UserSettingsModel extends Equatable {
  final int? goldCurrentSellPaise;
  final int? silverCurrentSellPaise;
  final String debtPayoffStrategy; // 'snowball' | 'avalanche' | 'custom'
  final int monthlyPaymentCapacityPaise;
  final String apiBaseUrl;

  const UserSettingsModel({
    this.goldCurrentSellPaise,
    this.silverCurrentSellPaise,
    this.debtPayoffStrategy = 'snowball',
    this.monthlyPaymentCapacityPaise = 2500000, // ₹25,000 default
    this.apiBaseUrl = 'https://dhanflow-api.vercel.app',
  });

  UserSettingsModel copyWith({
    int? Function()? goldCurrentSellPaise,
    int? Function()? silverCurrentSellPaise,
    String? debtPayoffStrategy,
    int? monthlyPaymentCapacityPaise,
    String? apiBaseUrl,
  }) =>
      UserSettingsModel(
        goldCurrentSellPaise:
            goldCurrentSellPaise != null ? goldCurrentSellPaise() : this.goldCurrentSellPaise,
        silverCurrentSellPaise:
            silverCurrentSellPaise != null ? silverCurrentSellPaise() : this.silverCurrentSellPaise,
        debtPayoffStrategy: debtPayoffStrategy ?? this.debtPayoffStrategy,
        monthlyPaymentCapacityPaise:
            monthlyPaymentCapacityPaise ?? this.monthlyPaymentCapacityPaise,
        apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      );

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) => UserSettingsModel(
        goldCurrentSellPaise: (json['gold_current_sell_paise'] as num?)?.toInt(),
        silverCurrentSellPaise: (json['silver_current_sell_paise'] as num?)?.toInt(),
        debtPayoffStrategy: json['debt_payoff_strategy'] as String? ?? 'snowball',
        monthlyPaymentCapacityPaise:
            (json['monthly_payment_capacity'] as num? ?? 2500000).toInt(),
        apiBaseUrl: json['api_base_url'] as String? ?? 'https://dhanflow-api.vercel.app',
      );

  Map<String, dynamic> toJson() => {
        'gold_current_sell_paise': goldCurrentSellPaise,
        'silver_current_sell_paise': silverCurrentSellPaise,
        'debt_payoff_strategy': debtPayoffStrategy,
        'monthly_payment_capacity': monthlyPaymentCapacityPaise,
        'api_base_url': apiBaseUrl,
      };

  @override
  List<Object?> get props => [
        goldCurrentSellPaise,
        silverCurrentSellPaise,
        debtPayoffStrategy,
        monthlyPaymentCapacityPaise,
        apiBaseUrl,
      ];
}

class DhanflowAppState extends Equatable {
  final String schemaVersion;
  final DateTime lastUpdated;
  final List<CreditCardModel> creditCards;
  final List<LoanModel> loans;
  final List<PersonalPayableModel> personalPayables;
  final List<RecoveryModel> recoveries;
  final List<BullionTransactionModel> bullionTransactions;
  final List<ActivityLogModel> activityLog;
  final UserSettingsModel settings;

  const DhanflowAppState({
    this.schemaVersion = '1.0.0',
    required this.lastUpdated,
    required this.creditCards,
    required this.loans,
    required this.personalPayables,
    required this.recoveries,
    required this.bullionTransactions,
    required this.activityLog,
    required this.settings,
  });

  DhanflowAppState copyWith({
    DateTime? lastUpdated,
    List<CreditCardModel>? creditCards,
    List<LoanModel>? loans,
    List<PersonalPayableModel>? personalPayables,
    List<RecoveryModel>? recoveries,
    List<BullionTransactionModel>? bullionTransactions,
    List<ActivityLogModel>? activityLog,
    UserSettingsModel? settings,
  }) =>
      DhanflowAppState(
        schemaVersion: schemaVersion,
        lastUpdated: lastUpdated ?? DateTime.now(),
        creditCards: creditCards ?? this.creditCards,
        loans: loans ?? this.loans,
        personalPayables: personalPayables ?? this.personalPayables,
        recoveries: recoveries ?? this.recoveries,
        bullionTransactions: bullionTransactions ?? this.bullionTransactions,
        activityLog: activityLog ?? this.activityLog,
        settings: settings ?? this.settings,
      );

  factory DhanflowAppState.fromJson(Map<String, dynamic> json) => DhanflowAppState(
        schemaVersion: json['schema_version'] as String? ?? '1.0.0',
        lastUpdated: json['last_updated'] != null
            ? DateTime.parse(json['last_updated'] as String)
            : DateTime.now(),
        creditCards: (json['credit_cards'] as List<dynamic>)
            .map((e) => CreditCardModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        loans: (json['loans'] as List<dynamic>? ?? [])
            .map((e) => LoanModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        personalPayables: (json['personal_payables'] as List<dynamic>? ?? [])
            .map((e) => PersonalPayableModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        recoveries: (json['recoveries'] as List<dynamic>? ?? [])
            .map((e) => RecoveryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        bullionTransactions: (json['bullion_transactions'] as List<dynamic>)
            .map((e) => BullionTransactionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        activityLog: (json['activity_log'] as List<dynamic>? ?? [])
            .map((e) => ActivityLogModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        settings: json['user_settings'] != null
            ? UserSettingsModel.fromJson(json['user_settings'] as Map<String, dynamic>)
            : const UserSettingsModel(),
      );

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'last_updated': lastUpdated.toIso8601String(),
        'credit_cards': creditCards.map((e) => e.toJson()).toList(),
        'loans': loans.map((e) => e.toJson()).toList(),
        'personal_payables': personalPayables.map((e) => e.toJson()).toList(),
        'recoveries': recoveries.map((e) => e.toJson()).toList(),
        'bullion_transactions': bullionTransactions.map((e) => e.toJson()).toList(),
        'activity_log': activityLog.map((e) => e.toJson()).toList(),
        'user_settings': settings.toJson(),
      };

  @override
  List<Object?> get props => [
        schemaVersion,
        lastUpdated,
        creditCards,
        loans,
        personalPayables,
        recoveries,
        bullionTransactions,
        activityLog,
        settings,
      ];
}
