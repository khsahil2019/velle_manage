import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/inr_formatter.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../../models/kpi_snapshot.dart';
import '../../models/models.dart';
import '../../widgets/common/dhan_ui.dart';

/// Assets Vault Tab: track Gold, Silver, Diamonds, Jewelry, Property, Stocks, Cash & Any Personal Holding.
class BullionTab extends StatefulWidget {
  const BullionTab({super.key});

  @override
  State<BullionTab> createState() => _BullionTabState();
}

typedef AssetsTab = BullionTab;

class _BullionTabState extends State<BullionTab> {
  String _filter = 'all'; // all | diamond | gold | silver | things

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DhanflowCubit, DhanflowViewState>(
      builder: (context, state) {
        final kpi = state.kpis;
        final txns = state.appState.bullionTransactions;
        final customAssets = state.appState.personalAssets;
        final hidden = state.hideBalances;
        final isDark = context.isDark;
        final width = MediaQuery.of(context).size.width;

        final filteredCustom = customAssets.where((a) {
          if (_filter == 'all') return true;
          if (_filter == 'diamond') {
            return a.category == 'diamond' || a.category == 'jewelry';
          }
          if (_filter == 'gold') return a.category == 'gold';
          if (_filter == 'silver') return a.category == 'silver';
          if (_filter == 'things') {
            return !['diamond', 'jewelry', 'gold', 'silver'].contains(a.category);
          }
          return true;
        }).toList();

        final showGoldWeight = _filter == 'all' || _filter == 'gold';
        final showSilverWeight = _filter == 'all' || _filter == 'silver';

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            // ── HERO ASSET VAULT SUMMARY CARD ───────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.accentAmber.withValues(alpha: isDark ? 0.35 : 0.45),
                  width: 1.2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF171B26),
                          AppColors.bgCard,
                          AppColors.accentAmber.withValues(alpha: 0.10),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFFFFBEB),
                          const Color(0xFFFEF3C7).withValues(alpha: 0.45),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? AppColors.accentAmber.withValues(alpha: 0.10)
                        : const Color(0x0F0F172A),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentAmber.withValues(alpha: isDark ? 0.16 : 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accentAmber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.diamond_outlined, size: 12, color: AppColors.accentAmber),
                            SizedBox(width: 5),
                            Text(
                              'MY WEALTH VAULT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppColors.accentAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentAmber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _showAddAssetSheet(context),
                        icon: const Icon(Icons.add_rounded, size: 17),
                        label: const Text('Add Asset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Total Tracked Assets Valuation',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hidden ? '₹ • • • • • •' : kpi.totalAssetsFormatted,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: context.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gold, Silver, Diamonds, Property & everything you own',
                    style: TextStyle(fontSize: 11, color: context.textTertiary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _VaultStatWell(
                          label: 'Gold 24K',
                          value: hidden ? '₹ ••••' : kpi.goldStats.assetValueFormatted,
                          sub: kpi.goldStats.totalGramsFormatted,
                          accent: AppColors.accentAmber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _VaultStatWell(
                          label: 'Silver',
                          value: hidden ? '₹ ••••' : kpi.silverStats.assetValueFormatted,
                          sub: kpi.silverStats.totalGramsFormatted,
                          accent: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _VaultStatWell(
                          label: 'Items & Gems',
                          value: hidden ? '₹ ••••' : kpi.customAssetsFormatted,
                          sub: '${customAssets.length} holdings',
                          accent: const Color(0xFF06B6D4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── CATEGORY FILTER PILLS ───────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipPill(
                    label: 'All Assets',
                    icon: Icons.apps_rounded,
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipPill(
                    label: 'Diamonds & Jewelry',
                    icon: Icons.diamond_outlined,
                    selected: _filter == 'diamond',
                    accent: const Color(0xFF06B6D4),
                    onTap: () => setState(() => _filter = 'diamond'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipPill(
                    label: 'Gold',
                    icon: Icons.workspace_premium_rounded,
                    selected: _filter == 'gold',
                    accent: AppColors.accentAmber,
                    onTap: () => setState(() => _filter = 'gold'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipPill(
                    label: 'Silver',
                    icon: Icons.blur_circular_rounded,
                    selected: _filter == 'silver',
                    accent: const Color(0xFF94A3B8),
                    onTap: () => setState(() => _filter = 'silver'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipPill(
                    label: 'Property & Things',
                    icon: Icons.category_outlined,
                    selected: _filter == 'things',
                    accent: AppColors.accentGreen,
                    onTap: () => setState(() => _filter = 'things'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── DIAMONDS, JEWELRY & PERSONAL ITEMS SECTION ──────────
            SectionHeader(
              title: 'Diamonds, Jewelry & Personal Items',
              subtitle: customAssets.isEmpty
                  ? 'Add diamonds, property, stocks, cash, watches, gadgets or any asset'
                  : 'Tap any asset card to update valuation or manage',
              trailing: TextButton.icon(
                onPressed: () => _showAddAssetSheet(context, initialTab: 0),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 15, color: Color(0xFF06B6D4)),
                label: const Text(
                  'Add Item',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF06B6D4)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (filteredCustom.isEmpty)
              DhanCard(
                borderColor: context.border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.16 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.diamond_outlined, color: Color(0xFF06B6D4), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _filter == 'all'
                                    ? 'Track Diamonds, Things & Personal Wealth'
                                    : 'No items in this category yet',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Add solitaire diamonds, 22K jewelry, fixed deposits, stocks, real estate, watches or vehicles.',
                                style: TextStyle(fontSize: 11, color: context.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _QuickPresetButton(
                          label: '+ Diamond',
                          color: const Color(0xFF06B6D4),
                          onTap: () => _showAddAssetSheet(context, initialTab: 0, presetCategory: 'diamond'),
                        ),
                        _QuickPresetButton(
                          label: '+ Jewelry',
                          color: AppColors.accentAmber,
                          onTap: () => _showAddAssetSheet(context, initialTab: 0, presetCategory: 'jewelry'),
                        ),
                        _QuickPresetButton(
                          label: '+ Cash / FD',
                          color: AppColors.accentGreen,
                          onTap: () => _showAddAssetSheet(context, initialTab: 0, presetCategory: 'cash'),
                        ),
                        _QuickPresetButton(
                          label: '+ Property / Thing',
                          color: AppColors.accentBlue,
                          onTap: () => _showAddAssetSheet(context, initialTab: 0, presetCategory: 'property'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Builder(builder: (context) {
                final cols = width >= 820 ? 2 : 1;
                if (cols == 1) {
                  return Column(
                    children: filteredCustom
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PersonalAssetCard(
                                asset: item,
                                hidden: hidden,
                                onTap: () => _showEditAssetSheet(context, item),
                              ),
                            ))
                        .toList(),
                  );
                }
                final rows = <Widget>[];
                for (int i = 0; i < filteredCustom.length; i += 2) {
                  final second = i + 1 < filteredCustom.length ? filteredCustom[i + 1] : null;
                  rows.add(
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _PersonalAssetCard(
                              asset: filteredCustom[i],
                              hidden: hidden,
                              onTap: () => _showEditAssetSheet(context, filteredCustom[i]),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: second != null
                                ? _PersonalAssetCard(
                                    asset: second,
                                    hidden: hidden,
                                    onTap: () => _showEditAssetSheet(context, second),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (i + 2 < filteredCustom.length) rows.add(const SizedBox(height: 10));
                }
                return Column(children: rows);
              }),

            if (showGoldWeight || showSilverWeight) ...[
              const SizedBox(height: 20),
              SectionHeader(
                title: 'Precious Metals Weight Holdings',
                subtitle: 'Gram-exact Gold 24K & Silver cost basis + live rate simulator',
                trailing: TextButton.icon(
                  onPressed: () => _showAddAssetSheet(context, initialTab: 1),
                  icon: const Icon(Icons.scale_rounded, size: 15, color: AppColors.accentAmber),
                  label: const Text(
                    'Add Weight',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentAmber),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            if (showGoldWeight) ...[
              _MetalSummaryCard(
                title: 'Gold 24K (Weight Vault)',
                badge: 'Au 999.9',
                accentColor: AppColors.accentAmber,
                stats: kpi.goldStats,
                txns: txns.where((t) => t.metal == 'gold').toList(),
                hidden: hidden,
              ),
              const SizedBox(height: 14),
            ],
            if (showSilverWeight)
              _MetalSummaryCard(
                title: 'Silver (Weight Vault)',
                badge: 'Ag 999',
                accentColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                stats: kpi.silverStats,
                txns: txns.where((t) => t.metal == 'silver').toList(),
                hidden: hidden,
              ),
          ],
        );
      },
    );
  }

  void _showAddAssetSheet(
    BuildContext context, {
    int initialTab = 0, // 0 = Item/Diamond/Thing, 1 = Weight (Gold/Silver)
    String presetCategory = 'diamond',
  }) {
    int mode = initialTab;

    // Mode 0 controllers (Any Asset / Diamond / Thing)
    String category = presetCategory;
    final titleCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final currentCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime itemDate = DateTime.now();

    // Mode 1 controllers (Gold / Silver by Weight)
    String metal = 'gold';
    bool rateMode = true;
    final gramsCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final vaultNameCtrl = TextEditingController(text: 'Physical Locker');
    DateTime metalDate = DateTime.now();

    final categories = const [
      ('diamond', 'Diamond', Icons.diamond_outlined),
      ('jewelry', 'Jewelry', Icons.auto_awesome_outlined),
      ('gold', 'Gold Item', Icons.workspace_premium_rounded),
      ('silver', 'Silver Item', Icons.blur_circular_rounded),
      ('property', 'Property', Icons.home_work_outlined),
      ('stocks', 'Stocks / MF', Icons.show_chart_rounded),
      ('cash', 'Cash / FD', Icons.account_balance_wallet_outlined),
      ('vehicle', 'Vehicle', Icons.directions_car_outlined),
      ('gadget', 'Watch / Tech', Icons.watch_outlined),
      ('other', 'Other Thing', Icons.inventory_2_outlined),
    ];

    showDhanBottomSheet(context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheetState) {
        final isDark = ctx.isDark;
        final grams = double.tryParse(gramsCtrl.text);
        final inputVal = double.tryParse(valueCtrl.text);

        int? preGstPreview;
        int? gstPreview;
        int? paidPreview;
        int? ratePreview;

        if (grams != null && grams > 0 && inputVal != null && inputVal > 0) {
          final gx = PaiseMath.gramsToX10000(grams);
          if (rateMode) {
            ratePreview = PaiseMath.rupeesToPaise(inputVal);
            preGstPreview = PaiseMath.preGstForGrams(gx, ratePreview);
            gstPreview = PaiseMath.gst3Pct(preGstPreview);
            paidPreview = preGstPreview + gstPreview;
          } else {
            paidPreview = PaiseMath.rupeesToPaise(inputVal);
            preGstPreview = PaiseMath.removeGST3Pct(paidPreview);
            gstPreview = paidPreview - preGstPreview;
            ratePreview = PaiseMath.effectiveCostPerGram(preGstPreview, gx);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add to My Assets Vault',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ctx.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track diamonds, jewelry, property, stocks, cash, things, or gram-exact Gold & Silver',
              style: TextStyle(fontSize: 11, color: ctx.textSecondary),
            ),
            const SizedBox(height: 12),

            // Mode Switcher
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgHover : AppColors.lightBgCard2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ctx.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeTabButton(
                      label: '💎 Asset / Item',
                      selected: mode == 0,
                      onTap: () => setSheetState(() => mode = 0),
                    ),
                  ),
                  Expanded(
                    child: _ModeTabButton(
                      label: '⚖️ Gold / Silver (gm)',
                      selected: mode == 1,
                      onTap: () => setSheetState(() => mode = 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (mode == 0) ...[
              Text(
                'CATEGORY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ctx.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: categories.map((c) {
                  final selected = category == c.$1;
                  return ChoiceChip(
                    avatar: Icon(
                      c.$3,
                      size: 14,
                      color: selected ? Colors.black : ctx.textSecondary,
                    ),
                    label: Text(c.$2),
                    selected: selected,
                    selectedColor: AppColors.accentAmber,
                    backgroundColor: isDark ? AppColors.bgHover : AppColors.lightBgCard2,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.black : ctx.textSecondary,
                    ),
                    onSelected: (_) => setSheetState(() => category = c.$1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Asset Name / Item Title',
                  hintText: category == 'diamond'
                      ? 'e.g. Solitaire Diamond Ring'
                      : category == 'property'
                          ? 'e.g. 2BHK Flat / Plot'
                          : 'e.g. Gold Bangles / Stocks / MacBook',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quantity / Purity / Spec (optional)',
                  hintText: 'e.g. 0.75 Carat VVS1 · or 22K 15gm · or 1 Unit',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: costCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Purchase Cost (₹)',
                        prefixText: '₹ ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: currentCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Current Value (₹)',
                        prefixText: '₹ ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location / Notes (optional)',
                  hintText: 'e.g. Home Safe, Bank Locker, Zerodha, Certified IGI',
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentAmber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  final cur = double.tryParse(currentCtrl.text);
                  final cost = double.tryParse(costCtrl.text) ?? cur;
                  if (title.isEmpty || cur == null || cur < 0) return;

                  context.read<DhanflowCubit>().addPersonalAsset(
                        title: title,
                        category: category,
                        quantityLabel: qtyCtrl.text.trim().isEmpty ? '1 Unit' : qtyCtrl.text.trim(),
                        purchaseValuePaise: PaiseMath.rupeesToPaise(cost ?? cur),
                        currentValuePaise: PaiseMath.rupeesToPaise(cur),
                        note: noteCtrl.text.trim(),
                        acquiredDate: itemDate,
                      );
                  Navigator.pop(ctx);
                },
                child: const Text('Save to Asset Vault'),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('🥇 Gold 24K')),
                      selected: metal == 'gold',
                      selectedColor: AppColors.accentAmber,
                      labelStyle: TextStyle(
                        color: metal == 'gold' ? Colors.black : ctx.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setSheetState(() => metal = 'gold'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('🥈 Silver')),
                      selected: metal == 'silver',
                      selectedColor: const Color(0xFFCBD5E1),
                      labelStyle: TextStyle(
                        color: metal == 'silver' ? Colors.black : ctx.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setSheetState(() => metal = 'silver'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: gramsCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setSheetState(() {}),
                decoration: const InputDecoration(labelText: 'Weight in Grams (e.g. 0.5000)'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const SizedBox(
                        width: double.infinity,
                        child: FittedBox(fit: BoxFit.scaleDown, child: Text('Pre-GST Rate/gm')),
                      ),
                      selected: rateMode,
                      selectedColor: AppColors.accentGreen,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: rateMode ? Colors.black : ctx.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setSheetState(() => rateMode = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const SizedBox(
                        width: double.infinity,
                        child: FittedBox(fit: BoxFit.scaleDown, child: Text('Total Paid (Incl. GST)')),
                      ),
                      selected: !rateMode,
                      selectedColor: AppColors.accentGreen,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: !rateMode ? Colors.black : ctx.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setSheetState(() => rateMode = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: valueCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setSheetState(() {}),
                decoration: InputDecoration(
                  labelText: rateMode ? 'Buy Rate per gram (Pre-GST ₹)' : 'Total Cash Paid (₹)',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: vaultNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Storage / Source (e.g. Physical Vault, Jeweler, Digital)',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: metalDate,
                    firstDate: DateTime(2015),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null && ctx.mounted) {
                    setSheetState(() {
                      metalDate = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        metalDate.hour,
                        metalDate.minute,
                      );
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 15),
                label: Text(
                  'Purchase Date: ${INRFormatter.formatDateTime(metalDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (paidPreview != null &&
                  preGstPreview != null &&
                  gstPreview != null &&
                  ratePreview != null) ...[
                const SizedBox(height: 10),
                DhanCard(
                  backgroundColor: isDark ? AppColors.bgHover : AppColors.lightBgCard2,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _PreviewRow('Pre-GST Rate', INRFormatter.formatRatePerGm(ratePreview)),
                      _PreviewRow('Pre-GST Value', INRFormatter.formatPaise(preGstPreview)),
                      _PreviewRow('3% GST', INRFormatter.formatPaise(gstPreview),
                          color: AppColors.accentRose),
                      _PreviewRow('Total Cash Paid', INRFormatter.formatPaise(paidPreview),
                          color: AppColors.accentAmber),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentAmber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  if (grams == null || grams <= 0 || inputVal == null || inputVal <= 0) return;
                  context.read<DhanflowCubit>().addBullionPurchase(
                        metal: metal,
                        gramsX10000: PaiseMath.gramsToX10000(grams),
                        buyRatePaise: rateMode ? PaiseMath.rupeesToPaise(inputVal) : null,
                        totalPaidPaise: !rateMode ? PaiseMath.rupeesToPaise(inputVal) : null,
                        purchaseDate: metalDate,
                        platform: vaultNameCtrl.text.trim().isEmpty
                            ? 'Vault'
                            : vaultNameCtrl.text.trim(),
                      );
                  Navigator.pop(ctx);
                },
                child: const Text('Add Weight Holding'),
              ),
            ],
          ],
        );
      });
    });
  }

  void _showEditAssetSheet(BuildContext context, PersonalAssetModel asset) {
    final titleCtrl = TextEditingController(text: asset.title);
    final qtyCtrl = TextEditingController(text: asset.quantityLabel);
    final costCtrl = TextEditingController(
      text: (asset.purchaseValuePaise / 100.0).toStringAsFixed(0),
    );
    final curCtrl = TextEditingController(
      text: (asset.currentValuePaise / 100.0).toStringAsFixed(0),
    );
    final noteCtrl = TextEditingController(text: asset.note);
    String category = asset.category;

    showDhanBottomSheet(context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheetState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Update ${asset.title}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ctx.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove asset',
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose),
                  onPressed: () {
                    Navigator.pop(ctx);
                    showProtectedDeleteDialog(
                      context,
                      title: 'Remove ${asset.title}?',
                      message:
                          'Current valuation ${asset.currentValueFormatted} will be removed from your Net Assets calculation.',
                      actionLabel: 'Remove Asset',
                      onConfirm: () => context.read<DhanflowCubit>().deletePersonalAsset(asset.id),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Asset Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: 'Quantity / Spec'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Purchase Cost (₹)', prefixText: '₹ '),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: curCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Current Value (₹)', prefixText: '₹ '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Location / Note'),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                final cur = double.tryParse(curCtrl.text);
                final cost = double.tryParse(costCtrl.text) ?? cur;
                if (cur == null || cur < 0) return;
                context.read<DhanflowCubit>().updatePersonalAsset(
                      assetId: asset.id,
                      title: titleCtrl.text.trim(),
                      category: category,
                      quantityLabel: qtyCtrl.text.trim(),
                      purchaseValuePaise: PaiseMath.rupeesToPaise(cost ?? cur),
                      currentValuePaise: PaiseMath.rupeesToPaise(cur),
                      note: noteCtrl.text.trim(),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Update Valuation'),
            ),
          ],
        );
      });
    });
  }
}

class _VaultStatWell extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color accent;

  const _VaultStatWell({
    required this.label,
    required this.value,
    required this.sub,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgPrimary.withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: context.textTertiary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.5, color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.icon,
    required this.selected,
    this.accent = AppColors.accentGreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: isDark ? 0.22 : 0.16)
              : (isDark ? AppColors.bgCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : context.border,
            width: selected ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? accent : context.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? accent : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPresetButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickPresetButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: context.isDark ? 0.14 : 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? context.bgCard : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: selected ? Border.all(color: AppColors.accentAmber.withValues(alpha: 0.45)) : null,
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.accentAmber : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalAssetCard extends StatelessWidget {
  final PersonalAssetModel asset;
  final bool hidden;
  final VoidCallback onTap;

  const _PersonalAssetCard({
    required this.asset,
    required this.hidden,
    required this.onTap,
  });

  ({IconData icon, Color color}) _styleFor(String cat) {
    switch (cat.toLowerCase()) {
      case 'diamond':
        return (icon: Icons.diamond_outlined, color: const Color(0xFF06B6D4));
      case 'jewelry':
        return (icon: Icons.auto_awesome_outlined, color: AppColors.accentAmber);
      case 'gold':
        return (icon: Icons.workspace_premium_rounded, color: AppColors.accentAmber);
      case 'silver':
        return (icon: Icons.blur_circular_rounded, color: const Color(0xFF94A3B8));
      case 'property':
        return (icon: Icons.home_work_outlined, color: AppColors.accentGreen);
      case 'stocks':
        return (icon: Icons.show_chart_rounded, color: AppColors.accentBlue);
      case 'cash':
        return (icon: Icons.account_balance_wallet_outlined, color: AppColors.accentGreen);
      case 'vehicle':
        return (icon: Icons.directions_car_outlined, color: AppColors.accentPurple);
      case 'gadget':
        return (icon: Icons.watch_outlined, color: AppColors.accentBlue);
      default:
        return (icon: Icons.inventory_2_outlined, color: AppColors.accentAmber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = _styleFor(asset.category);
    final pl = asset.gainLossPaise;
    final pct = asset.gainLossPct;

    return DhanCard(
      onTap: onTap,
      borderColor: st.color.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: st.color.withValues(alpha: context.isDark ? 0.16 : 0.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: st.color.withValues(alpha: 0.35)),
                ),
                child: Icon(st.icon, color: st.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${asset.categoryLabel} · ${asset.quantityLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hidden ? '₹ •••••' : asset.currentValueFormatted,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: st.color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (pl != 0 && pct != null)
                    Text(
                      hidden ? '••••' : '${pl > 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: pl >= 0 ? AppColors.accentGreen : AppColors.accentRose,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (asset.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              asset.note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: context.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetalSummaryCard extends StatefulWidget {
  final String title;
  final String badge;
  final Color accentColor;
  final BullionStats stats;
  final List<BullionTransactionModel> txns;
  final bool hidden;

  const _MetalSummaryCard({
    required this.title,
    required this.badge,
    required this.accentColor,
    required this.stats,
    required this.txns,
    required this.hidden,
  });

  @override
  State<_MetalSummaryCard> createState() => _MetalSummaryCardState();
}

class _MetalSummaryCardState extends State<_MetalSummaryCard> {
  late final TextEditingController _sellCtrl;

  @override
  void initState() {
    super.initState();
    _sellCtrl = TextEditingController(
      text: widget.stats.currentSellPricePaise != null
          ? (widget.stats.currentSellPricePaise! / 100.0).toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _sellCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    final pl = s.unrealisedPLPaise;
    final sellVal = s.currentSellValuePaise;
    final cubit = context.read<DhanflowCubit>();
    final h = widget.hidden;
    final isDark = context.isDark;

    return DhanCard(
      borderColor: widget.accentColor.withValues(alpha: 0.28),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          context.bgCard,
          widget.accentColor.withValues(alpha: isDark ? 0.08 : 0.06),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: isDark ? 0.16 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: widget.accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                text: s.totalGramsFormatted,
                color: widget.accentColor,
                bgColor: widget.accentColor.withValues(alpha: isDark ? 0.14 : 0.12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricCell('Avg Buy (Pre-GST)', h ? '₹ •••••' : s.avgRateFormatted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCell('Effective Cost (Incl. GST)', h ? '₹ •••••' : s.effectiveCostFormatted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricCell('Pre-GST Asset Value', h ? '₹ •••••' : s.assetValueFormatted,
                    color: AppColors.accentGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCell('Total Cash Paid', h ? '₹ •••••' : s.totalPaidFormatted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricCell('Total 3% GST Paid', h ? '₹ •••' : s.gstPaidFormatted,
                    color: AppColors.accentRose),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCell('Break-Even Sell/gm', h ? '₹ •••••' : s.effectiveCostFormatted,
                    color: AppColors.accentAmber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgHover : AppColors.lightBgCard2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Market Rate Simulator (/gm)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter current live market buyback price (/gm) to compute unrealised gain/loss.',
                  style: TextStyle(fontSize: 10, color: context.textTertiary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _sellCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    cubit.updateSellPrice(
                      s.metal,
                      parsed != null && parsed > 0 ? PaiseMath.rupeesToPaise(parsed) : null,
                    );
                  },
                  decoration: const InputDecoration(
                    labelText: 'Current Market Rate (/gm)',
                    prefixText: '₹ ',
                  ),
                ),
                if (pl != null && sellVal != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EST. SELL VALUE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: context.textTertiary,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                h ? '₹ •••••' : INRFormatter.formatPaise(sellVal),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: context.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'UNREALISED P/L',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: context.textTertiary,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                h
                                    ? '₹ ••••'
                                    : '${pl >= 0 ? '+' : ''}${INRFormatter.formatPaise(pl)} (${s.returnPct?.toStringAsFixed(2) ?? '0.00'}%)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: pl >= 0 ? AppColors.accentGreen : AppColors.accentRose,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'HOLDING ENTRIES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: context.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          if (widget.txns.isEmpty)
            Text('No entries logged yet.', style: TextStyle(fontSize: 11, color: context.textTertiary))
          else
            ...widget.txns.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${t.gramsFormatted} @ ${h ? '₹ •••••' : t.rateFormatted}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            Text(
                              '${INRFormatter.formatDateTime(t.purchaseDate)} · Pre-GST ${h ? '₹ ••••' : t.preGstFormatted}',
                              style: TextStyle(fontSize: 10, color: context.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        h ? '₹ ••••' : t.totalPaidFormatted,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Entry options',
                        color: context.bgCard2,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 16,
                          color: context.textTertiary,
                        ),
                        onSelected: (val) {
                          if (val == 'delete') {
                            showProtectedDeleteDialog(
                              context,
                              title: 'Remove ${t.metal.toUpperCase()} Holding?',
                              message:
                                  '${t.gramsFormatted} acquired on ${INRFormatter.formatDateTime(t.purchaseDate)} (Paid ${t.totalPaidFormatted}).',
                              actionLabel: 'Delete Entry',
                              onConfirm: () => cubit.deleteBullionTransaction(t.id),
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    size: 16, color: AppColors.accentRose),
                                SizedBox(width: 8),
                                Text('Remove Entry',
                                    style: TextStyle(fontSize: 12, color: AppColors.accentRose)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MetricCell(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, color: context.textTertiary),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color ?? context.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _PreviewRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: context.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color ?? context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
