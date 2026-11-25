import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/inr_formatter.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../../models/models.dart';
import '../../widgets/cards/cred_credit_card.dart';
import '../../widgets/common/dhan_ui.dart';

class DebtTab extends StatefulWidget {
  const DebtTab({super.key});

  @override
  State<DebtTab> createState() => _DebtTabState();
}

class _DebtTabState extends State<DebtTab> {
  int _segment = 0; // 0 = Cards, 1 = Loans & Payables, 2 = Freedom Engine
  int _cardFilter = 0; // 0 = All, 1 = Active, 2 = Cleared

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DhanflowCubit, DhanflowViewState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.border),
                ),
                child: Row(
                  children: [
                    _SegmentButton(
                      label: '${context.tr('debt_cards')} (${state.appState.creditCards.length})',
                      selected: _segment == 0,
                      onTap: () => setState(() => _segment = 0),
                    ),
                    _SegmentButton(
                      label: context.tr('debt_loans_payables'),
                      selected: _segment == 1,
                      onTap: () => setState(() => _segment = 1),
                    ),
                    _SegmentButton(
                      label: context.tr('debt_payoff_plan'),
                      selected: _segment == 2,
                      onTap: () => setState(() => _segment = 2),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _segment == 0
                  ? _CreditCardsView(
                      state: state,
                      filter: _cardFilter,
                      onFilterChanged: (f) => setState(() => _cardFilter = f),
                    )
                  : _segment == 1
                      ? _LoansPayablesView(state: state)
                      : _DebtFreedomEngineView(state: state),
            ),
          ],
        );
      },
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.black : context.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── CREDIT CARDS VIEW ───────────────────────────────────────────────────────

class _CreditCardsView extends StatelessWidget {
  final DhanflowViewState state;
  final int filter;
  final ValueChanged<int> onFilterChanged;

  const _CreditCardsView({
    required this.state,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final allCards = state.appState.creditCards;
    final cards = allCards.where((c) {
      if (filter == 1) return !c.isCleared;
      if (filter == 2) return c.isCleared;
      return true;
    }).toList();
    final kpi = state.kpis;
    final hidden = state.hideBalances;
    final isWide = MediaQuery.of(context).size.width >= 760;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
      children: [
        // CRED-style Credit Cards Portfolio Command Strip
        DhanCard(
          padding: const EdgeInsets.all(16),
          borderColor: context.borderLight,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: context.isDark
                ? const [Color(0xFF141A28), Color(0xFF0D111A)]
                : [Colors.white, const Color(0xFFF1F5F9)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: context.tr('debt_wallet'),
                subtitle: context.tr('debt_tap_hint'),
                trailing: ElevatedButton.icon(
                  onPressed: () => _showAddCardSheet(context),
                  icon: const Icon(Icons.add_card_rounded, size: 16),
                  label: Text(context.tr('debt_add_card')),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCol(
                      context.tr('debt_total_due'),
                      hidden ? '₹ ••••••' : INRFormatter.formatPaise(kpi.totalCCOutstandingPaise),
                      AppColors.accentRose,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCol(
                      context.tr('debt_avl_limit'),
                      hidden
                          ? '₹ ••••••'
                          : INRFormatter.formatPaise(
                              (kpi.totalCCLimitPaise - kpi.totalCCOutstandingPaise)
                                  .clamp(0, kpi.totalCCLimitPaise),
                            ),
                      AppColors.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCol(
                      context.tr('debt_used'),
                      INRFormatter.formatPct(kpi.overallUtilizationPct),
                      AppColors.utilizationColor(kpi.overallUtilizationPct),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              UtilizationBar(percentage: kpi.overallUtilizationPct, height: 5),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: Text('${context.tr('debt_filter_all')} (${allCards.length})'),
              selected: filter == 0,
              selectedColor: AppColors.accentGreen,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: filter == 0 ? Colors.black : context.textSecondary,
              ),
              onSelected: (_) => onFilterChanged(0),
            ),
            ChoiceChip(
              label: Text('${context.tr('debt_filter_active')} (${kpi.activeCardsCount})'),
              selected: filter == 1,
              selectedColor: AppColors.accentAmber,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: filter == 1 ? Colors.black : context.textSecondary,
              ),
              onSelected: (_) => onFilterChanged(1),
            ),
            ChoiceChip(
              label: Text('${context.tr('debt_filter_cleared')} (${kpi.clearedCardsCount})'),
              selected: filter == 2,
              selectedColor: AppColors.accentGreen,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: filter == 2 ? Colors.black : context.textSecondary,
              ),
              onSelected: (_) => onFilterChanged(2),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (cards.isEmpty)
          DhanCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('No cards match this filter',
                    style: TextStyle(fontSize: 13, color: context.textSecondary)),
              ),
            ),
          )
        else if (isWide)
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 14) / 2;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: cards
                    .asMap()
                    .entries
                    .map((entry) => SizedBox(
                          width: cardWidth,
                          child: _CreditCardItem(
                            card: entry.value,
                            hidden: hidden,
                            index: entry.key,
                          ),
                        ))
                    .toList(),
              );
            },
          )
        else
          ...cards.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _CreditCardItem(
                  card: entry.value,
                  hidden: hidden,
                  index: entry.key,
                ),
              )),
      ],
    );
  }
}

class _CreditCardItem extends StatelessWidget {
  final CreditCardModel card;
  final bool hidden;
  final int index;

  const _CreditCardItem({
    required this.card,
    required this.hidden,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 240 + (index.clamp(0, 6) * 45)),
      curve: Curves.easeOutCubic,
      builder: (context, anim, child) {
        return Opacity(
          opacity: anim,
          child: Transform.translate(
            offset: Offset(0, (1 - anim) * 14),
            child: child,
          ),
        );
      },
      child: CredCreditCard(
        card: card,
        hidden: hidden,
        onTapCard: () => _showCardCommandSheet(context, card, initialMode: 0),
        onTapOutstanding: () => _showCardCommandSheet(context, card, initialMode: 1),
        onTapAvailable: () => _showCardCommandSheet(context, card, initialMode: 0),
        onTapTag: () => _showCardCommandSheet(context, card, initialMode: 2),
      ),
    );
  }
}

const List<String> _kQuickCardTags = [
  'Active Pocket Debt',
  'Covered by EMI',
  'Quick Zero Target',
  'No Cost EMI',
  'Cleared',
];

/// Unified CRED-style bottom sheet triggered anywhere the user taps on a credit card.
void _showCardCommandSheet(
  BuildContext context,
  CreditCardModel card, {
  int initialMode = 0, // 0 = Avl Limit, 1 = Pay / Spend, 2 = Edit / Tag
}) {
  int mode = initialMode;
  final avlCtrl = TextEditingController();
  final txnAmtCtrl = TextEditingController();
  final txnNoteCtrl = TextEditingController();
  bool isPayment = true;

  final nameCtrl = TextEditingController(text: card.name);
  final limitCtrl = TextEditingController(text: (card.totalLimitPaise / 100.0).toStringAsFixed(2));
  final tagCtrl = TextEditingController(text: card.categoryTag);
  final aprCtrl = TextEditingController(text: (card.aprBps / 100.0).toStringAsFixed(1));

  final theme = resolveBankTheme(card.name, isCleared: card.isCleared);

  showDhanBottomSheet(context, builder: (ctx) {
    return StatefulBuilder(builder: (ctx, setSheetState) {
      final parsedAvl = double.tryParse(avlCtrl.text);
      final newAvlPaise = parsedAvl != null ? PaiseMath.rupeesToPaise(parsedAvl) : null;
      final previewOut = newAvlPaise != null
          ? (card.totalLimitPaise - newAvlPaise).clamp(0, card.totalLimitPaise)
          : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header strip with bank icon + quick summary
          Row(
            children: [
              BankEmblemIcon(brand: theme.brand, fallbackLabel: theme.bankCode, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: ctx.textPrimary)),
                    Text(
                      'Due ${card.outstandingFormatted} · Avl ${card.availableFormatted}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: ctx.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mode Switcher Pills
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ctx.isDark ? AppColors.bgPrimary : AppColors.lightBgCard2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ctx.border),
            ),
            child: Row(
              children: [
                _SegmentButton(
                  label: 'Update Avl',
                  selected: mode == 0,
                  onTap: () => setSheetState(() => mode = 0),
                ),
                _SegmentButton(
                  label: 'Pay / Spend',
                  selected: mode == 1,
                  onTap: () => setSheetState(() => mode = 1),
                ),
                _SegmentButton(
                  label: 'Edit / Tag',
                  selected: mode == 2,
                  onTap: () => setSheetState(() => mode = 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (mode == 0) ...[
            TextField(
              controller: avlCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              onChanged: (_) => setSheetState(() {}),
              decoration: InputDecoration(
                labelText: 'New Available Limit from Bank App (₹)',
                hintText: (card.availableLimitPaise / 100.0).toStringAsFixed(2),
                prefixText: '₹ ',
                suffixIcon: TextButton(
                  onPressed: () {
                    avlCtrl.text = (card.totalLimitPaise / 100.0).toStringAsFixed(2);
                    setSheetState(() {});
                  },
                  child: const Text('FULL'),
                ),
              ),
            ),
            if (previewOut != null) ...[
              const SizedBox(height: 10),
              DhanCard(
                backgroundColor: ctx.isDark ? AppColors.bgHover : AppColors.lightBgCard2,
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Updated Card Due',
                        style: TextStyle(fontSize: 12, color: ctx.textPrimary)),
                    Text(
                      INRFormatter.formatPaise(previewOut),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: previewOut == 0 ? AppColors.accentGreen : AppColors.accentAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                if (newAvlPaise == null || newAvlPaise < 0) return;
                context.read<DhanflowCubit>().updateCardAvailableLimit(card.id, newAvlPaise);
                Navigator.pop(ctx);
              },
              child: const Text('Update Available Limit'),
            ),
          ] else if (mode == 1) ...[
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('💳 Payment Made'),
                      ),
                    ),
                    selected: isPayment,
                    selectedColor: AppColors.accentGreen,
                    labelStyle: TextStyle(
                      color: isPayment ? Colors.black : ctx.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setSheetState(() => isPayment = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('🛒 New Spend'),
                      ),
                    ),
                    selected: !isPayment,
                    selectedColor: AppColors.accentRose,
                    labelStyle: TextStyle(
                      color: !isPayment ? Colors.white : ctx.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setSheetState(() => isPayment = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: txnAmtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                prefixText: '₹ ',
                suffixIcon: (isPayment && card.outstandingPaise > 0)
                    ? TextButton(
                        onPressed: () {
                          txnAmtCtrl.text = (card.outstandingPaise / 100.0).toStringAsFixed(2);
                          setSheetState(() {});
                        },
                        child: const Text('PAY FULL'),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: txnNoteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPayment ? AppColors.accentGreen : AppColors.accentRose,
                foregroundColor: isPayment ? Colors.black : Colors.white,
              ),
              onPressed: () {
                final val = double.tryParse(txnAmtCtrl.text);
                if (val == null || val <= 0) return;
                context.read<DhanflowCubit>().recordCardTransaction(
                      card.id,
                      isPayment: isPayment,
                      amountPaise: PaiseMath.rupeesToPaise(val),
                      note: txnNoteCtrl.text,
                    );
                Navigator.pop(ctx);
              },
              child: Text(isPayment ? 'Record Payment' : 'Record Spend'),
            ),
          ] else ...[
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Card Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: limitCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Total Credit Limit (₹)', prefixText: '₹ '),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: tagCtrl,
              onChanged: (_) => setSheetState(() {}),
              decoration: const InputDecoration(labelText: 'Tag'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _kQuickCardTags
                  .map((tag) => ChoiceChip(
                        label: Text(tag, style: const TextStyle(fontSize: 10.5)),
                        selected: tagCtrl.text.trim().toLowerCase() == tag.toLowerCase(),
                        selectedColor: AppColors.accentGreen,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: tagCtrl.text.trim().toLowerCase() == tag.toLowerCase()
                              ? Colors.black
                              : ctx.textSecondary,
                        ),
                        onSelected: (_) => setSheetState(() => tagCtrl.text = tag),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: aprCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'APR % (for Debt Engine)'),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                final lim = double.tryParse(limitCtrl.text);
                final apr = double.tryParse(aprCtrl.text);
                if (lim == null || lim <= 0) return;
                context.read<DhanflowCubit>().updateCardDetails(
                      card.id,
                      name: nameCtrl.text,
                      newTotalLimitPaise: PaiseMath.rupeesToPaise(lim),
                      categoryTag: tagCtrl.text,
                      aprBps: apr != null ? (apr * 100).round() : null,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.accentRose),
              onPressed: () {
                Navigator.pop(ctx);
                showProtectedDeleteDialog(
                  context,
                  title: 'Remove ${card.name}?',
                  message: 'Current due: ${card.outstandingFormatted}. Card data will be removed from your active ledger.',
                  actionLabel: 'Delete Card',
                  onConfirm: () => context.read<DhanflowCubit>().removeCreditCard(card.id),
                );
              },
              icon: const Icon(Icons.shield_outlined, size: 16),
              label: const Text('Remove Card from Ledger (Protected)'),
            ),
          ],
        ],
      );
    });
  });
}

void _showAddCardSheet(BuildContext context) {
  final nameCtrl = TextEditingController(text: kBankPresets.first.defaultCardName);
  final limCtrl = TextEditingController();
  final valCtrl = TextEditingController();
  final tagCtrl = TextEditingController(text: 'Active Pocket Debt');
  BankBrand selectedBrand = kBankPresets.first.brand;
  bool enterAvailableMode = true; // true = enter Available Limit, false = enter Current Due

  showDhanBottomSheet(context, builder: (ctx) {
    return StatefulBuilder(builder: (ctx, setSheetState) {
      final limRupees = double.tryParse(limCtrl.text) ?? 50000;
      final inputRupees = double.tryParse(valCtrl.text) ?? (enterAvailableMode ? limRupees : 0);
      final limPaise = PaiseMath.rupeesToPaise(limRupees.clamp(0, 100000000));
      final enteredPaise = PaiseMath.rupeesToPaise(inputRupees.clamp(0, limRupees.clamp(0, 100000000)));
      final previewAvl = enterAvailableMode ? enteredPaise : (limPaise - enteredPaise).clamp(0, limPaise);

      final previewModel = CreditCardModel(
        id: 'preview',
        userId: 'preview',
        name: nameCtrl.text.trim().isEmpty ? 'Your New Card' : nameCtrl.text.trim(),
        totalLimitPaise: limPaise > 0 ? limPaise : 5000000,
        availableLimitPaise: limPaise > 0 ? previewAvl : 5000000,
        categoryTag: tagCtrl.text,
        displayOrder: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add Credit Card',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ctx.textPrimary)),
          const SizedBox(height: 4),
          Text('Pick a bank and fill limits — live card updates below',
              style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
          const SizedBox(height: 12),

          // Live CRED Card Preview
          CredCreditCard(card: previewModel, isPreview: true),
          const SizedBox(height: 14),

          // 1-Tap Bank Selector Row with Authentic Bank Icons
          Text('SELECT BANK',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ctx.textTertiary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kBankPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, idx) {
                final preset = kBankPresets[idx];
                final isSelected = selectedBrand == preset.brand;
                return GestureDetector(
                  onTap: () {
                    setSheetState(() {
                      selectedBrand = preset.brand;
                      if (preset.defaultCardName.isNotEmpty) {
                        nameCtrl.text = preset.defaultCardName;
                      } else {
                        nameCtrl.clear();
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 66,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ctx.greenDim.withValues(alpha: 0.55)
                          : (ctx.isDark ? AppColors.bgHover : AppColors.lightBgCard2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.accentGreen : ctx.borderLight,
                        width: isSelected ? 1.4 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BankEmblemIcon(
                          brand: preset.brand,
                          fallbackLabel: preset.label,
                          size: 30,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preset.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.accentGreen : ctx.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: nameCtrl,
            onChanged: (_) => setSheetState(() {}),
            decoration: const InputDecoration(labelText: 'Card Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: limCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setSheetState(() {}),
            decoration: const InputDecoration(
              labelText: 'Total Limit (₹)',
              hintText: '50000',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const SizedBox(
                    width: double.infinity,
                    child: FittedBox(fit: BoxFit.scaleDown, child: Text('Enter Available Limit')),
                  ),
                  selected: enterAvailableMode,
                  selectedColor: AppColors.accentGreen,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: enterAvailableMode ? Colors.black : ctx.textSecondary,
                  ),
                  onSelected: (_) => setSheetState(() => enterAvailableMode = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const SizedBox(
                    width: double.infinity,
                    child: FittedBox(fit: BoxFit.scaleDown, child: Text('Enter Current Due')),
                  ),
                  selected: !enterAvailableMode,
                  selectedColor: AppColors.accentAmber,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: !enterAvailableMode ? Colors.black : ctx.textSecondary,
                  ),
                  onSelected: (_) => setSheetState(() => enterAvailableMode = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: valCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setSheetState(() {}),
            decoration: InputDecoration(
              labelText: enterAvailableMode ? 'Available Limit (₹)' : 'Current Due / Outstanding (₹)',
              hintText: enterAvailableMode ? 'Leave blank for full limit' : '0',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: tagCtrl,
            onChanged: (_) => setSheetState(() {}),
            decoration: const InputDecoration(labelText: 'Tag'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _kQuickCardTags
                .map((tag) => ChoiceChip(
                      label: Text(tag, style: const TextStyle(fontSize: 10.5)),
                      selected: tagCtrl.text.trim().toLowerCase() == tag.toLowerCase(),
                      selectedColor: AppColors.accentGreen,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: tagCtrl.text.trim().toLowerCase() == tag.toLowerCase()
                            ? Colors.black
                            : ctx.textSecondary,
                      ),
                      onSelected: (_) => setSheetState(() => tagCtrl.text = tag),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final lim = double.tryParse(limCtrl.text);
              if (nameCtrl.text.trim().isEmpty || lim == null || lim <= 0) return;
              final parsedVal = double.tryParse(valCtrl.text);
              final totalPaise = PaiseMath.rupeesToPaise(lim);
              final int avlPaise;
              if (parsedVal == null) {
                avlPaise = totalPaise;
              } else {
                final vPaise = PaiseMath.rupeesToPaise(parsedVal).clamp(0, totalPaise);
                avlPaise = enterAvailableMode ? vPaise : (totalPaise - vPaise).clamp(0, totalPaise);
              }
              context.read<DhanflowCubit>().addCreditCard(
                    name: nameCtrl.text,
                    totalLimitPaise: totalPaise,
                    availableLimitPaise: avlPaise,
                    categoryTag: tagCtrl.text,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Add Card to Wallet'),
          ),
        ],
      );
    });
  });
}

// ── LOANS & PAYABLES VIEW ───────────────────────────────────────────────────

class _LoansPayablesView extends StatelessWidget {
  final DhanflowViewState state;
  const _LoansPayablesView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DhanflowCubit>();
    final loans = state.appState.loans;
    final payables = state.appState.personalPayables;
    final hidden = state.hideBalances;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
      children: [
        SectionHeader(
          title: 'EMI Loans',
          trailing: TextButton.icon(
            onPressed: () => _showAddLoanSheet(context),
            icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.accentBlue),
            label: const Text('Add Loan', style: TextStyle(color: AppColors.accentBlue)),
          ),
        ),
        const SizedBox(height: 8),
        ...loans.map((loan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DhanCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        BankAvatarBadge(name: loan.name, overrideColor: AppColors.accentBlue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            loan.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        StatusChip(
                          text: loan.isCleared ? 'CLEARED' : '${loan.remainingEmis} EMIs left',
                          color: loan.isCleared ? AppColors.accentGreen : AppColors.accentBlue,
                          bgColor: loan.isCleared ? context.greenDim : context.blueDim,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCol('EMI AMOUNT', hidden ? '₹ •••••' : loan.emiFormatted,
                              AppColors.accentBlue),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCol('REMAINING', '${loan.remainingEmis} / ${loan.originalEmis}',
                              AppColors.accentAmber),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCol(
                              'TOTAL BALANCE',
                              hidden ? '₹ ••••••' : loan.totalRemainingFormatted,
                              loan.isCleared ? AppColors.accentGreen : AppColors.accentRose),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: List.generate(loan.originalEmis.clamp(0, 24), (i) {
                        final paid = i < loan.paidEmis;
                        return Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: paid ? AppColors.accentGreen : AppColors.accentRose,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (!loan.isCleared)
                          ElevatedButton.icon(
                            onPressed: () => _confirmEmiAction(
                              context,
                              title: 'Mark 1 EMI Paid?',
                              message:
                                  '${loan.name}: Reduces remaining balance by ${loan.remainingEmis == 1 ? loan.totalRemainingFormatted : loan.emiFormatted}',
                              confirmText: 'Mark EMI Paid',
                              confirmColor: AppColors.accentGreen,
                              onConfirm: () => cubit.markLoanEmiPaid(loan.id),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Mark 1 EMI Paid'),
                          ),
                        PopupMenuButton<String>(
                          tooltip: 'More options',
                          color: context.bgCard2,
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            size: 19,
                            color: context.textTertiary,
                          ),
                          onSelected: (val) {
                            if (val == 'delete') {
                              showProtectedDeleteDialog(
                                context,
                                title: 'Remove ${loan.name}?',
                                message: 'Remaining balance: ${loan.totalRemainingFormatted}.',
                                actionLabel: 'Delete Loan',
                                onConfirm: () => cubit.removeLoan(loan.id),
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.shield_outlined, size: 16, color: AppColors.accentRose),
                                  SizedBox(width: 8),
                                  Text('Remove Loan',
                                      style: TextStyle(fontSize: 12, color: AppColors.accentRose)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 12),
        SectionHeader(
          title: 'Personal Payables',
          trailing: TextButton.icon(
            onPressed: () => _showAddPayableSheet(context),
            icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.accentRose),
            label: const Text('Add Payable', style: TextStyle(color: AppColors.accentRose)),
          ),
        ),
        const SizedBox(height: 8),
        ...payables.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DhanCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        BankAvatarBadge(name: p.name, overrideColor: AppColors.accentPurple),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                ),
                              ),
                              if (p.note.isNotEmpty)
                                Text(p.note,
                                    style: TextStyle(fontSize: 11, color: context.textTertiary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hidden ? '₹ •••••' : p.amountFormatted,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: p.isSettled ? AppColors.accentGreen : AppColors.accentRose,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (!p.isSettled)
                          ElevatedButton(
                            onPressed: () => _showPayPayableSheet(context, p),
                            child: const Text('Record Payment'),
                          ),
                        PopupMenuButton<String>(
                          tooltip: 'More options',
                          color: context.bgCard2,
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            size: 19,
                            color: context.textTertiary,
                          ),
                          onSelected: (val) {
                            if (val == 'delete') {
                              showProtectedDeleteDialog(
                                context,
                                title: 'Remove ${p.name}?',
                                message: 'Pending amount: ${p.amountFormatted}.',
                                actionLabel: 'Delete Payable',
                                onConfirm: () => cubit.removePayable(p.id),
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.shield_outlined, size: 16, color: AppColors.accentRose),
                                  SizedBox(width: 8),
                                  Text('Remove Payable',
                                      style: TextStyle(fontSize: 12, color: AppColors.accentRose)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  void _showAddLoanSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emiCtrl = TextEditingController();
    final countCtrl = TextEditingController();
    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add EMI Loan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ctx.textPrimary)),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Loan Name')),
          const SizedBox(height: 10),
          TextField(
            controller: emiCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monthly EMI (₹)', prefixText: '₹ '),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: countCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Remaining EMIs'),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final emi = double.tryParse(emiCtrl.text);
              final cnt = int.tryParse(countCtrl.text);
              if (nameCtrl.text.trim().isEmpty || emi == null || cnt == null) return;
              context.read<DhanflowCubit>().addLoan(
                    name: nameCtrl.text,
                    emiAmountPaise: PaiseMath.rupeesToPaise(emi),
                    remainingEmis: cnt,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Add Loan'),
          ),
        ],
      );
    });
  }

  void _showAddPayableSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add Personal Payable',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ctx.textPrimary)),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 10),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount Owed (₹)', prefixText: '₹ '),
          ),
          const SizedBox(height: 10),
          TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note')),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text);
              if (nameCtrl.text.trim().isEmpty || amt == null) return;
              context.read<DhanflowCubit>().addPersonalPayable(
                    name: nameCtrl.text,
                    amountPaise: PaiseMath.rupeesToPaise(amt),
                    note: noteCtrl.text,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Add Payable'),
          ),
        ],
      );
    });
  }

  void _showPayPayableSheet(BuildContext context, PersonalPayableModel p) {
    final amtCtrl = TextEditingController(text: (p.amountPaise / 100.0).toStringAsFixed(2));
    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pay ${p.name}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ctx.textPrimary)),
          const SizedBox(height: 4),
          Text('Pending: ${p.amountFormatted}',
              style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount Paid (₹)', prefixText: '₹ '),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text);
              if (amt == null || amt <= 0) return;
              context.read<DhanflowCubit>().payPersonalPayable(p.id, PaiseMath.rupeesToPaise(amt));
              Navigator.pop(ctx);
            },
            child: const Text('Record Payment'),
          ),
        ],
      );
    });
  }
}

// ── DEBT FREEDOM ENGINE VIEW ────────────────────────────────────────────────

class _DebtFreedomEngineView extends StatelessWidget {
  final DhanflowViewState state;
  const _DebtFreedomEngineView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DhanflowCubit>();
    final plan = state.payoffPlan;
    final hidden = state.hideBalances;
    final budgetRupees =
        (state.appState.settings.monthlyPaymentCapacityPaise / 100.0).clamp(5000.0, 150000.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
      children: [
        DhanCard(
          borderColor: AppColors.accentGreen.withValues(alpha: 0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Strategy Selection',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in [
                    ('snowball', '❄️ Snowball (Smallest First)'),
                    ('avalanche', '🔥 Avalanche (Highest APR)'),
                    ('custom', '⚡ Custom Order'),
                  ])
                    ChoiceChip(
                      label: Text(s.$2),
                      selected: plan.strategy == s.$1,
                      selectedColor: AppColors.accentGreen,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: plan.strategy == s.$1 ? Colors.black : context.textSecondary,
                      ),
                      onSelected: (_) => cubit.updateDebtEngine(strategy: s.$1),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('Monthly Repayment Budget',
                        style: TextStyle(fontSize: 12, color: context.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hidden
                        ? '₹ •••••'
                        : INRFormatter.formatPaise(
                            state.appState.settings.monthlyPaymentCapacityPaise),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accentGreen),
                  ),
                ],
              ),
              Slider(
                value: budgetRupees,
                min: 5000,
                max: 150000,
                divisions: 29,
                activeColor: AppColors.accentGreen,
                onChanged: (v) =>
                    cubit.updateDebtEngine(monthlyBudgetPaise: PaiseMath.rupeesToPaise(v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DhanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payoff Projection',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCol(
                        'TOTAL DEBT',
                        hidden ? '₹ ••••••' : INRFormatter.formatPaise(plan.totalDebtPaise),
                        AppColors.accentRose),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCol('TIME TO FREEDOM', '${plan.monthsToFreedom} months',
                        AppColors.accentGreen),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCol(
                        'INTEREST SAVED',
                        hidden ? '₹ •••••' : INRFormatter.formatPaise(plan.interestSavedPaise),
                        AppColors.accentAmber),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (plan.nextTarget != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.greenDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed_rounded, color: AppColors.accentGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Next Target: ${plan.nextTarget} · Projected Debt-Free: ${plan.debtFreeDate.day}/${plan.debtFreeDate.month}/${plan.debtFreeDate.year}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentGreen),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Step-by-Step Clearance Order'),
        const SizedBox(height: 8),
        ...plan.payoffOrder.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DhanCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: context.isDark ? AppColors.bgHover : AppColors.lightBgCard2,
                    child: Text('$idx',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentGreen)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary)),
                        Text(
                          'Balance: ${hidden ? '₹ •••••' : INRFormatter.formatPaise(step.startingBalancePaise)} · APR ${(step.aprBps / 100).toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 11, color: context.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(
                    text: 'Month ${step.clearedInMonth}',
                    color: AppColors.accentBlue,
                    bgColor: context.blueDim,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCol(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: context.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ),
      ],
    );
  }
}

Future<void> _confirmEmiAction(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
  String confirmText = 'Confirm',
  Color confirmColor = AppColors.accentGreen,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.bgCard2,
      title: Text(title,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ctx.textPrimary)),
      content: Text(message, style: TextStyle(fontSize: 13, color: ctx.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          child: Text(confirmText),
        ),
      ],
    ),
  );
}
