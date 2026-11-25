import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/inr_formatter.dart';

int _parseInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? double.tryParse(value.trim())?.toInt() ?? fallback;
  return fallback;
}

int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String && value.trim().isNotEmpty) {
    return int.tryParse(value.trim()) ?? double.tryParse(value.trim())?.toInt();
  }
  return null;
}

bool _parseBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value.toInt() != 0;
  if (value is String) {
    final lower = value.trim().toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
  }
  return fallback;
}

DateTime _parseDate(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim()) ?? DateTime.now();
  }
  return DateTime.now();
}

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
        totalLimitPaise: _parseInt(json['total_limit']),
        availableLimitPaise: _parseInt(json['available_limit']),
        categoryTag: json['category_tag'] as String? ?? '',
        displayOrder: _parseInt(json['display_order']),
        isActive: _parseBool(json['is_active'], true),
        aprBps: _parseInt(json['apr_bps'], 3600),
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
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
        emiAmountPaise: _parseInt(json['emi_amount']),
        remainingEmis: _parseInt(json['remaining_emis']),
        originalEmis: _parseInt(json['original_emis'], _parseInt(json['remaining_emis'])),
        totalRemainingPaise: _parseInt(json['total_remaining']),
        note: json['note'] as String? ?? '',
        isActive: _parseBool(json['is_active'], true),
        aprBps: _parseInt(json['apr_bps'], 1600),
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
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
        amountPaise: _parseInt(json['amount']),
        note: json['note'] as String? ?? '',
        isSettled: _parseBool(json['is_settled'], false),
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
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
        amountPaise: _parseInt(json['amount']),
        appliedToCardId: json['applied_to_card'] as String?,
        note: json['note'] as String? ?? '',
        paymentDate: _parseDate(json['payment_date']),
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
    String? name,
    int? totalOriginalPaise,
    int? totalPendingPaise,
    String? note,
    bool? isSettled,
    List<RecoveryPaymentModel>? payments,
    DateTime? updatedAt,
  }) =>
      RecoveryModel(
        id: id,
        userId: userId,
        name: name ?? this.name,
        totalOriginalPaise: totalOriginalPaise ?? this.totalOriginalPaise,
        totalPendingPaise: totalPendingPaise ?? this.totalPendingPaise,
        note: note ?? this.note,
        isSettled: isSettled ?? this.isSettled,
        payments: payments ?? this.payments,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  factory RecoveryModel.fromJson(Map<String, dynamic> json) => RecoveryModel(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? 'local',
        name: json['name'] as String,
        totalOriginalPaise: _parseInt(json['total_original']),
        totalPendingPaise: _parseInt(json['total_pending']),
        note: json['note'] as String? ?? '',
        isSettled: _parseBool(json['is_settled'], false),
        payments: (json['payments'] as List<dynamic>? ?? [])
            .map((p) => RecoveryPaymentModel.fromJson(p as Map<String, dynamic>))
            .toList(),
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
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
  List<Object?> get props => [id, name, note, totalOriginalPaise, totalPendingPaise, isSettled, payments];
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
        gramsX10000: _parseInt(json['grams_x10000']),
        buyRatePaise: _parseInt(json['buy_rate_paise']),
        preGstPaise: _parseInt(json['pre_gst_paise']),
        gstPaise: _parseInt(json['gst_paise']),
        totalPaidPaise: _parseInt(json['total_paid_paise']),
        purchaseDate: _parseDate(json['purchase_date']),
        platform: json['platform'] as String? ?? 'Vault',
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
        deltaPaise: _parseNullableInt(json['delta_paise']),
        relatedEntityId: json['related_entity_id'] as String?,
        relatedEntityName: json['related_entity_name'] as String?,
        createdAt: _parseDate(json['created_at']),
        isReversed: _parseBool(json['is_reversed'], false),
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
  final String themeMode; // 'dark' | 'light' | 'system'
  final String languageCode; // 'en' | 'hi'

  const UserSettingsModel({
    this.goldCurrentSellPaise,
    this.silverCurrentSellPaise,
    this.debtPayoffStrategy = 'snowball',
    this.monthlyPaymentCapacityPaise = 2500000, // ₹25,000 default
    this.apiBaseUrl = 'https://vellemanage.vercel.app',
    this.themeMode = 'dark',
    this.languageCode = 'en',
  });

  UserSettingsModel copyWith({
    int? Function()? goldCurrentSellPaise,
    int? Function()? silverCurrentSellPaise,
    String? debtPayoffStrategy,
    int? monthlyPaymentCapacityPaise,
    String? apiBaseUrl,
    String? themeMode,
    String? languageCode,
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
        themeMode: themeMode ?? this.themeMode,
        languageCode: languageCode ?? this.languageCode,
      );

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) => UserSettingsModel(
        goldCurrentSellPaise: _parseNullableInt(json['gold_current_sell_paise']),
        silverCurrentSellPaise: _parseNullableInt(json['silver_current_sell_paise']),
        debtPayoffStrategy: json['debt_payoff_strategy'] as String? ?? 'snowball',
        monthlyPaymentCapacityPaise:
            _parseInt(json['monthly_payment_capacity'], 2500000),
        apiBaseUrl: json['api_base_url'] as String? ?? ApiConstants.defaultBaseUrl,
        themeMode: json['theme_mode'] as String? ?? 'dark',
        languageCode: json['language_code'] as String? ?? 'en',
      );

  Map<String, dynamic> toJson() => {
        'gold_current_sell_paise': goldCurrentSellPaise,
        'silver_current_sell_paise': silverCurrentSellPaise,
        'debt_payoff_strategy': debtPayoffStrategy,
        'monthly_payment_capacity': monthlyPaymentCapacityPaise,
        'api_base_url': apiBaseUrl,
        'theme_mode': themeMode,
        'language_code': languageCode,
      };

  @override
  List<Object?> get props => [
        goldCurrentSellPaise,
        silverCurrentSellPaise,
        debtPayoffStrategy,
        monthlyPaymentCapacityPaise,
        apiBaseUrl,
        themeMode,
        languageCode,
      ];
}

class PersonalAssetModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String category; // diamond, gold, silver, jewelry, property, stocks, cash, vehicle, gadget, other
  final String quantityLabel;
  final int purchaseValuePaise;
  final int currentValuePaise;
  final String note;
  final DateTime acquiredDate;
  final DateTime createdAt;

  const PersonalAssetModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    this.quantityLabel = '1 Unit',
    required this.purchaseValuePaise,
    required this.currentValuePaise,
    this.note = '',
    required this.acquiredDate,
    required this.createdAt,
  });

  int get gainLossPaise => currentValuePaise - purchaseValuePaise;
  double? get gainLossPct =>
      purchaseValuePaise > 0 ? (gainLossPaise / purchaseValuePaise) * 100 : null;

  String get currentValueFormatted => INRFormatter.formatPaise(currentValuePaise);
  String get purchaseValueFormatted => INRFormatter.formatPaise(purchaseValuePaise);

  String get categoryLabel {
    switch (category.toLowerCase()) {
      case 'diamond':
        return 'Diamond';
      case 'gold':
        return 'Gold Item';
      case 'silver':
        return 'Silver Item';
      case 'jewelry':
        return 'Jewelry';
      case 'property':
        return 'Property / Land';
      case 'stocks':
        return 'Stocks / MF';
      case 'cash':
        return 'Cash / FD';
      case 'vehicle':
        return 'Vehicle';
      case 'gadget':
        return 'Watch / Gadget';
      default:
        return 'Personal Asset';
    }
  }

  PersonalAssetModel copyWith({
    String? title,
    String? category,
    String? quantityLabel,
    int? purchaseValuePaise,
    int? currentValuePaise,
    String? note,
    DateTime? acquiredDate,
  }) =>
      PersonalAssetModel(
        id: id,
        userId: userId,
        title: title ?? this.title,
        category: category ?? this.category,
        quantityLabel: quantityLabel ?? this.quantityLabel,
        purchaseValuePaise: purchaseValuePaise ?? this.purchaseValuePaise,
        currentValuePaise: currentValuePaise ?? this.currentValuePaise,
        note: note ?? this.note,
        acquiredDate: acquiredDate ?? this.acquiredDate,
        createdAt: createdAt,
      );

  factory PersonalAssetModel.fromJson(Map<String, dynamic> json) =>
      PersonalAssetModel(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? 'local',
        title: json['title'] as String,
        category: (json['category'] as String? ?? 'other').toLowerCase(),
        quantityLabel: json['quantity_label'] as String? ?? '1 Unit',
        purchaseValuePaise: _parseInt(json['purchase_value_paise']),
        currentValuePaise: _parseInt(json['current_value_paise']),
        note: json['note'] as String? ?? '',
        acquiredDate: _parseDate(json['acquired_date']),
        createdAt: _parseDate(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'category': category,
        'quantity_label': quantityLabel,
        'purchase_value_paise': purchaseValuePaise,
        'current_value_paise': currentValuePaise,
        'note': note,
        'acquired_date': acquiredDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        quantityLabel,
        purchaseValuePaise,
        currentValuePaise,
        note,
        acquiredDate,
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
  final List<PersonalAssetModel> personalAssets;
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
    this.personalAssets = const [],
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
    List<PersonalAssetModel>? personalAssets,
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
        personalAssets: personalAssets ?? this.personalAssets,
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
        personalAssets: (json['personal_assets'] as List<dynamic>? ?? [])
            .map((e) => PersonalAssetModel.fromJson(e as Map<String, dynamic>))
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
        'personal_assets': personalAssets.map((e) => e.toJson()).toList(),
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
        personalAssets,
        activityLog,
        settings,
      ];
}
