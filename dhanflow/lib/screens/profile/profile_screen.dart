import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/inr_formatter.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/dhanflow_cubit.dart';
import '../../services/export_service.dart';
import '../../widgets/common/dhan_ui.dart';
import '../activity/activity_tab.dart';

/// Rich Profile Hub: switches between organized Profile Menu (Account, Language, Theme,
/// Cloud/Local Backups, Payoff Strategy, Privacy Policy, Terms, Security, Easy Help, Sign Out)
/// and the integrated Activity Log tab.
class ProfileScreen extends StatefulWidget {
  final ValueNotifier<int>? subTabNotifier;

  const ProfileScreen({super.key, this.subTabNotifier});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _subTab = 0; // 0 = Profile & Menu, 1 = Activity Log

  @override
  void initState() {
    super.initState();
    _subTab = widget.subTabNotifier?.value ?? 0;
    widget.subTabNotifier?.addListener(_onExternalTabChange);
  }

  @override
  void dispose() {
    widget.subTabNotifier?.removeListener(_onExternalTabChange);
    super.dispose();
  }

  void _onExternalTabChange() {
    final target = widget.subTabNotifier?.value ?? 0;
    if (mounted && target != _subTab) {
      setState(() => _subTab = target);
    }
  }

  void _setSubTab(int tab) {
    setState(() => _subTab = tab);
    if (widget.subTabNotifier != null) {
      widget.subTabNotifier!.value = tab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      children: [
        // ── PROFILE SEGMENT BAR (MENU vs ACTIVITY LOG) ──────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ProfileTabPill(
                    icon: Icons.grid_view_rounded,
                    label: context.tr('prof_menu_tab'),
                    selected: _subTab == 0,
                    onTap: () => _setSubTab(0),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ProfileTabPill(
                    icon: Icons.history_rounded,
                    label: context.tr('prof_activity_tab'),
                    selected: _subTab == 1,
                    onTap: () => _setSubTab(1),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _subTab == 1
              ? const ActivityTab()
              : _ProfileMenuView(
                  onOpenActivity: () => _setSubTab(1),
                  isDark: isDark,
                ),
        ),
      ],
    );
  }
}

class _ProfileTabPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileTabPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final activeBg = isDark ? AppColors.accentGreen : const Color(0xFF059669);
    final activeFg = isDark ? Colors.black : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? activeFg : context.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? activeFg : context.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuView extends StatelessWidget {
  final VoidCallback onOpenActivity;
  final bool isDark;

  const _ProfileMenuView({
    required this.onOpenActivity,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DhanflowCubit, DhanflowViewState>(
      builder: (context, state) {
        final cubit = context.read<DhanflowCubit>();
        final authState = context.watch<AuthCubit>().state;
        final app = state.appState;
        final isHi = context.isHindi;

        final userName = authState is AuthAuthenticated
            ? (authState.user['name'] as String? ?? 'Trustvly Member')
            : 'Trustvly Member';
        final userEmail = authState is AuthAuthenticated
            ? (authState.user['email'] as String? ?? '')
            : '';
        final driverLabel = authState is AuthAuthenticated
            ? (authState.storageDriver ?? 'CLOUD DB').toUpperCase()
            : 'CLOUD';

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
          children: [
            // ── USER IDENTITY HEADER CARD ───────────────────────────
            DhanCard(
              borderColor: AppColors.accentGreen.withValues(alpha: 0.35),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.bgCard2,
                        AppColors.bgCard,
                        AppColors.accentGreen.withValues(alpha: 0.09),
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFF8FAFC),
                        AppColors.accentGreen.withValues(alpha: 0.08),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGreen.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            authState is AuthAuthenticated ? authState.initials : 'TV',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: context.textPrimary,
                              ),
                            ),
                            if (userEmail.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                              ),
                            ],
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                StatusChip(
                                  text: isHi ? 'स्थायी लॉगिन सक्रिय' : 'PERMANENT SESSION',
                                  color: AppColors.accentGreen,
                                  bgColor: context.greenDim,
                                ),
                                StatusChip(
                                  text: driverLabel,
                                  color: AppColors.accentBlue,
                                  bgColor: context.blueDim,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileMiniStat(
                          label: context.tr('debt_cards'),
                          value: '${app.creditCards.length}',
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ProfileMiniStat(
                          label: context.tr('nav_assets'),
                          value: '${app.bullionTransactions.length + app.personalAssets.length}',
                          color: AppColors.accentAmber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ProfileMiniStat(
                          label: context.tr('nav_kullena'),
                          value: '${app.recoveries.length}',
                          color: AppColors.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ProfileMiniStat(
                          label: context.tr('prof_activity_tab'),
                          value: '${app.activityLog.length}',
                          color: AppColors.accentPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── SECTION 1: ACCOUNT & LOGS ───────────────────────────
            _SectionLabel(context.tr('prof_section_quick')),
            const SizedBox(height: 8),
            DhanCard(
              padding: EdgeInsets.zero,
              child: _MenuTile(
                icon: Icons.history_rounded,
                iconColor: AppColors.accentGreen,
                title: context.tr('prof_activity_tile'),
                subtitle: context.tr('prof_activity_sub'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.greenDim,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${app.activityLog.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentGreen,
                    ),
                  ),
                ),
                onTap: onOpenActivity,
                isLast: true,
              ),
            ),
            const SizedBox(height: 18),

            // ── SECTION 2: EASY SETTINGS & LANGUAGE ─────────────────
            _SectionLabel(context.tr('prof_section_pref')),
            const SizedBox(height: 8),
            DhanCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.translate_rounded,
                    iconColor: AppColors.accentBlue,
                    title: context.tr('prof_lang_tile'),
                    subtitle: context.tr('prof_lang_sub'),
                    trailing: StatusChip(
                      text: isHi ? 'हिन्दी' : 'ENGLISH',
                      color: AppColors.accentBlue,
                      bgColor: context.blueDim,
                    ),
                    onTap: () => _showLanguageSheet(context, cubit, isHi),
                  ),
                  _MenuTile(
                    icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    iconColor: isDark ? AppColors.accentAmber : const Color(0xFF6366F1),
                    title: context.tr('prof_theme_tile'),
                    subtitle: isDark
                        ? context.tr('prof_theme_dark')
                        : context.tr('prof_theme_light'),
                    trailing: Switch.adaptive(
                      value: !isDark,
                      activeTrackColor: const Color(0xFF059669),
                      onChanged: (_) => cubit.toggleThemeMode(),
                    ),
                    onTap: () => cubit.toggleThemeMode(),
                  ),
                  _MenuTile(
                    icon: Icons.visibility_off_outlined,
                    iconColor: AppColors.accentGreen,
                    title: context.tr('prof_mask_tile'),
                    subtitle: context.tr('prof_mask_sub'),
                    trailing: Switch.adaptive(
                      value: state.hideBalances,
                      activeTrackColor: AppColors.accentGreen,
                      onChanged: (_) => cubit.toggleHideBalances(),
                    ),
                    onTap: () => cubit.toggleHideBalances(),
                  ),
                  _MenuTile(
                    icon: Icons.bolt_rounded,
                    iconColor: AppColors.accentAmber,
                    title: context.tr('prof_payoff_tile'),
                    subtitle:
                        '${app.settings.debtPayoffStrategy.toUpperCase()} · ${INRFormatter.formatPaise(app.settings.monthlyPaymentCapacityPaise)}/mo',
                    onTap: () => _showStrategySheet(context, cubit, app.settings),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── SECTION 3: BACKUP & CLOUD VAULT ─────────────────────
            _SectionLabel(context.tr('prof_section_sync')),
            const SizedBox(height: 8),
            DhanCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.cloud_sync_outlined,
                    iconColor: AppColors.accentGreen,
                    title: context.tr('prof_cloud_tile'),
                    subtitle: app.settings.apiBaseUrl,
                    trailing: StatusChip(
                      text: state.syncStatus == CloudSyncStatus.synced
                          ? context.tr('synced')
                          : (state.syncStatus == CloudSyncStatus.syncing
                              ? context.tr('syncing')
                              : context.tr('local')),
                      color: state.syncStatus == CloudSyncStatus.error
                          ? AppColors.accentRose
                          : AppColors.accentGreen,
                      bgColor: state.syncStatus == CloudSyncStatus.error
                          ? context.roseDim
                          : context.greenDim,
                    ),
                    onTap: () => _showCloudSyncSheet(context, cubit, state),
                  ),
                  _MenuTile(
                    icon: Icons.data_object_rounded,
                    iconColor: AppColors.accentPurple,
                    title: context.tr('prof_json_tile'),
                    subtitle: isHi
                        ? 'JSON फ़ाइल डाउनलोड, अपलोड या रीसेट करें'
                        : 'Export, import JSON file or reset data safely',
                    onTap: () => _showJsonBackupSheet(context, cubit, state),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── SECTION 4: PRIVACY POLICY, SECURITY & HELP ──────────
            _SectionLabel(context.tr('prof_section_more')),
            const SizedBox(height: 8),
            DhanCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: AppColors.accentBlue,
                    title: context.tr('prof_privacy_policy'),
                    subtitle: context.tr('prof_privacy_sub'),
                    onTap: () => _showInfoSheet(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      color: AppColors.accentBlue,
                      title: context.tr('prof_privacy_policy'),
                      sections: isHi
                          ? const [
                              ('1. आपका डेटा सिर्फ़ आपका है',
                                  'Trustvly आपकी वित्तीय जानकारी को पहले आपके अपने डिवाइस (Hive Local Vault) में सेव करता है और क्लाउड सिंक सिर्फ़ आपके लॉगिन किए गए खाते से जुड़ता है।'),
                              ('2. कोई विज्ञापन या थर्ड-पार्टी ट्रैकिंग नहीं',
                                  'हम आपके क्रेडिट कार्ड, लोन, या संपत्ति की जानकारी किसी विज्ञापन कंपनी या तीसरे पक्ष के साथ साझा नहीं करते।'),
                              ('3. पूरा नियंत्रण और एक्सपोर्ट',
                                  'आप कभी भी अपना पूरा डेटा JSON फ़ाइल के रूप में एक्सपोर्ट या डिलीट कर सकते हैं।'),
                            ]
                          : const [
                              ('1. Private First Storage',
                                  'Trustvly stores your financial ledger locally on your device using Hive Vault and syncs only to your authenticated cloud account.'),
                              ('2. Zero Ad Trackers or Data Selling',
                                  'Your credit cards, loans, recoveries, and personal assets are never shared with advertisers, data brokers, or third parties.'),
                              ('3. Full User Control',
                                  'You own 100% of your financial snapshot. Export portable JSON backups or reset data anytime.'),
                            ],
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.gavel_rounded,
                    iconColor: AppColors.accentAmber,
                    title: context.tr('prof_terms'),
                    subtitle: context.tr('prof_terms_sub'),
                    onTap: () => _showInfoSheet(
                      context,
                      icon: Icons.gavel_rounded,
                      color: AppColors.accentAmber,
                      title: context.tr('prof_terms'),
                      sections: isHi
                          ? const [
                              ('व्यक्तिगत हिसाब किताब के लिए',
                                  'Trustvly आपकी रोज़मर्रा की उधारी, कार्ड लिमिट और संपत्ति का आसान रिकॉर्ड रखने के लिए है। यह बैंक का आधिकारिक CIBIL स्कोर नहीं है।'),
                              ('कीमत और मूल्यांकन',
                                  'सोना, चांदी, हीरा या अन्य संपत्तियों की मौजूदा कीमत आपके द्वारा दर्ज अनुमानित कीमत पर आधारित होती है।'),
                              ('सुरक्षित डिलीट नियम',
                                  'गलती से कोई ज़रूरी लेन-देन न मिटे, इसलिए डिलीट करने से पहले DELETE टाइप करना अनिवार्य है।'),
                            ]
                          : const [
                              ('Personal Clarity Tool',
                                  'Trustvly is built for personal money tracking, credit card discipline, and wealth clarity. Health scores are internal indicators—not official CIBIL scores.'),
                              ('Asset Valuations',
                                  'Gold, silver, diamond, and personal item valuations rely on the purchase costs and market rates you enter.'),
                              ('Safe Records Rule',
                                  'Destructive deletions require explicit typed DELETE confirmation so important entries are never erased by mistake.'),
                            ],
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.verified_user_outlined,
                    iconColor: AppColors.accentGreen,
                    title: context.tr('prof_security'),
                    subtitle: context.tr('prof_security_sub'),
                    onTap: () => _showInfoSheet(
                      context,
                      icon: Icons.verified_user_outlined,
                      color: AppColors.accentGreen,
                      title: context.tr('prof_security'),
                      sections: isHi
                          ? const [
                              ('स्थायी सुरक्षित सत्र (JWT)',
                                  'एक बार साइन इन करने के बाद आपका खाता डिवाइस पर सुरक्षित रूप से लॉग-इन रहता है ताकि बार-बार पासवर्ड न डालना पड़े।'),
                              ('DELETE सुरक्षा कवच',
                                  'कार्ड, लोन, वसूली या संपत्ति हटाने के लिए DELETE लिखना जरूरी है।'),
                              ('इतिहास (Audit Trail)',
                                  'किए गए हर बदलाव का रिकॉर्ड प्रोफ़ाइल -> गतिविधि लॉग में सुरक्षित रहता है।'),
                            ]
                          : const [
                              ('Permanent Authenticated Session',
                                  'Signed JWT authentication keeps your account signed in across app launches until you tap Sign Out.'),
                              ('Typed DELETE Safeguard',
                                  'Accidental single-tap deletion is blocked across cards, loans, borrowers, and assets.'),
                              ('Immutable Activity Audit Log',
                                  'Every edit, payment, recovery, and JSON backup creates a timestamped entry inside Profile -> Activity Log.'),
                            ],
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.help_outline_rounded,
                    iconColor: AppColors.accentPurple,
                    title: context.tr('prof_help'),
                    subtitle: context.tr('prof_help_sub'),
                    onTap: () => _showInfoSheet(
                      context,
                      icon: Icons.help_outline_rounded,
                      color: AppColors.accentPurple,
                      title: context.tr('prof_help'),
                      sections: isHi
                          ? const [
                              ('1. होम (Home)',
                                  'यहाँ आपका असली नेट हिसाब, कुल देना, कुल लेना और संपत्तियों की कुल कीमत एक नज़र में दिखती है।'),
                              ('2. कर्ज़ (Debt)',
                                  'किसी भी क्रेडिट कार्ड पर सीधे टैप करके तुरंत नई बची लिमिट लिखें, पेमेंट भरें या खर्च जोड़ें।'),
                              ('3. कुल लेना (Kul Lena)',
                                  'जिन लोगों से पैसे वापस लेने हैं उनका नाम जोड़ें। पैसा मिलने पर "पेमेंट मिला" दबाएं — चाहें तो उसे सीधे क्रेडिट कार्ड बिल में जोड़ सकते हैं।'),
                              ('4. संपत्ति (Assets)',
                                  'सोना, चांदी, हीरा, ज़मीन, FD, गाड़ी या कोई भी कीमती चीज़ जोड़ें ताकि आपकी असली नेट वर्थ दिखे।'),
                            ]
                          : const [
                              ('1. Home Dashboard',
                                  'See your true Net Balance = (Money Owed − Money Coming Back) − Your Total Assets in one plain view.'),
                              ('2. Debt & Credit Cards',
                                  'Tap directly anywhere on a credit card to update available limit, pay a bill, record a spend, or change its tag.'),
                              ('3. Kul Lena (Receivables)',
                                  'Track friends or borrowers who owe you money. Record partial payments and optionally apply them directly to pay down a credit card.'),
                              ('4. My Assets Vault',
                                  'Add diamonds, gold, silver, jewelry, property, stocks, cash, or gadgets you own.'),
                            ],
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: context.textSecondary,
                    title: context.tr('prof_about'),
                    subtitle: context.tr('prof_about_sub'),
                    onTap: () => _showInfoSheet(
                      context,
                      icon: Icons.info_outline_rounded,
                      color: AppColors.accentGreen,
                      title: 'Trustvly v2.0',
                      sections: isHi
                          ? const [
                              ('Trustvly मिशन',
                                  'आसान भाषा, साफ़ डिज़ाइन, अंग्रेज़ी व हिंदी सपोर्ट और Dark/White दोनों मोड के साथ आपका निजी वित्त साथी।'),
                              ('मुख्य फीचर्स',
                                  'क्रेडिट कार्ड मैनेजर, कुल लेना वसूली ट्रैकर, हीरा/सोना/संपत्ति वॉल्ट, और क्लाउड + लोकल JSON बैकअप।'),
                            ]
                          : const [
                              ('Trustvly Mission',
                                  'Built to bring effortless debt freedom and wealth clarity with bilingual English + Hindi support and crisp Dark & White modes.'),
                              ('Core Stack',
                                  'Offline-first Flutter ledger paired with multi-database Vercel PHP API storage and portable JSON backups.'),
                            ],
                    ),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── SIGN OUT BUTTON ─────────────────────────────────────
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentRose,
                side: BorderSide(color: AppColors.accentRose.withValues(alpha: 0.55), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _confirmSignOut(context, isHi),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(
                context.tr('prof_signout'),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                context.tr('prof_signout_sub'),
                style: TextStyle(fontSize: 10.5, color: context.textTertiary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageSheet(BuildContext context, DhanflowCubit cubit, bool isHi) {
    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ctx.tr('prof_lang_tile'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ctx.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            isHi ? 'अपनी पसंदीदा आसान भाषा चुनें' : 'Choose the language you are most comfortable with',
            style: TextStyle(fontSize: 12, color: ctx.textSecondary),
          ),
          const SizedBox(height: 14),
          _LanguageChoiceCard(
            flag: '🇬🇧',
            title: 'English (Simple & Easy)',
            subtitle: 'Plain everyday English across every screen',
            selected: !isHi,
            onTap: () {
              cubit.setLanguageCode('en');
              Navigator.pop(ctx);
            },
          ),
          const SizedBox(height: 10),
          _LanguageChoiceCard(
            flag: '🇮🇳',
            title: 'हिन्दी (सरल हिंदी)',
            subtitle: 'आसान और साफ़ हिंदी में पूरा ऐप',
            selected: isHi,
            onTap: () {
              cubit.setLanguageCode('hi');
              Navigator.pop(ctx);
            },
          ),
        ],
      );
    });
  }

  void _showStrategySheet(
      BuildContext context, DhanflowCubit cubit, dynamic settings) {
    final budgetCtrl = TextEditingController(
      text: ((settings.monthlyPaymentCapacityPaise as int) / 100).toStringAsFixed(0),
    );
    showDhanBottomSheet(context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheetState) {
        final strategy = ctx.watch<DhanflowCubit>().state.appState.settings.debtPayoffStrategy;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ctx.tr('prof_payoff_tile'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ctx.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Snowball (Smallest)')),
                    selected: strategy == 'snowball',
                    selectedColor: AppColors.accentGreen,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: strategy == 'snowball' ? Colors.black : ctx.textSecondary,
                    ),
                    onSelected: (_) => cubit.updateDebtEngine(strategy: 'snowball'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Avalanche (APR)')),
                    selected: strategy == 'avalanche',
                    selectedColor: AppColors.accentGreen,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: strategy == 'avalanche' ? Colors.black : ctx.textSecondary,
                    ),
                    onSelected: (_) => cubit.updateDebtEngine(strategy: 'avalanche'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Payment Budget (₹)',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                final v = double.tryParse(budgetCtrl.text);
                if (v == null || v <= 0) return;
                cubit.updateDebtEngine(monthlyBudgetPaise: PaiseMath.rupeesToPaise(v));
                Navigator.pop(ctx);
              },
              child: const Text('Save Strategy'),
            ),
          ],
        );
      });
    });
  }

  void _showCloudSyncSheet(
      BuildContext context, DhanflowCubit cubit, DhanflowViewState state) {
    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ctx.tr('prof_cloud_tile'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ctx.textPrimary),
          ),
          const SizedBox(height: 12),
          _ApiDiagnosticsStrip(apiUrl: state.appState.settings.apiBaseUrl),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.isSyncing
                      ? null
                      : () {
                          cubit.pushToCloud();
                          Navigator.pop(ctx);
                        },
                  icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Push to Cloud')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.isSyncing
                      ? null
                      : () {
                          cubit.pullFromCloud();
                          Navigator.pop(ctx);
                        },
                  icon: const Icon(Icons.cloud_download_outlined, size: 16),
                  label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Pull from Cloud')),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  void _showJsonBackupSheet(
      BuildContext context, DhanflowCubit cubit, DhanflowViewState state) {
    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ctx.tr('prof_json_tile'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ctx.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Every local JSON export or restore is automatically logged inside Profile -> Activity Log.',
            style: TextStyle(fontSize: 11.5, color: ctx.textSecondary),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () async {
              await ExportService.exportBackup(state.appState);
              cubit.recordExportBackup();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Export JSON Backup'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showImportSheet(context);
            },
            icon: const Icon(Icons.upload_rounded, size: 16),
            label: const Text('Import JSON Backup'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentRose,
              side: BorderSide(color: AppColors.accentRose.withValues(alpha: 0.5)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _confirmReset(context);
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 16),
            label: const Text('Reset Snapshot to Defaults'),
          ),
        ],
      );
    });
  }

  void _showImportSheet(BuildContext context) {
    final ctrl = TextEditingController();
    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Import JSON Backup',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ctx.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Paste backup JSON or pick a .json file from storage',
            style: TextStyle(fontSize: 11, color: ctx.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  if (result != null && result.files.single.path != null) {
                    final content = await File(result.files.single.path!).readAsString();
                    ctrl.text = content;
                  }
                },
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: const Text('Pick .json File'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final clip = await Clipboard.getData('text/plain');
                  if (clip?.text != null) ctrl.text = clip!.text!;
                },
                icon: const Icon(Icons.paste_rounded, size: 16),
                label: const Text('Paste'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: ctrl,
            maxLines: 6,
            decoration: const InputDecoration(hintText: '{"schema_version": "1.0.0", ...}'),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              context.read<DhanflowCubit>().importJson(ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Validate & Restore'),
          ),
        ],
      );
    });
  }

  void _confirmReset(BuildContext context) {
    showProtectedDeleteDialog(
      context,
      title: 'Reset to Initial Snapshot?',
      message:
          'This restores all credit cards, loans, payables, recoveries, and initial asset holdings to default seed values.',
      actionLabel: 'Reset Everything',
      onConfirm: () => context.read<DhanflowCubit>().resetToSeed(),
    );
  }

  void _confirmSignOut(BuildContext context, bool isHi) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.bgCard2,
        title: Text(
          isHi ? 'साइन आउट करें?' : 'Sign Out?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ctx.textPrimary),
        ),
        content: Text(
          isHi
              ? 'साइन आउट करने के बाद ऐप खोलने पर दोबारा साइन इन करना होगा।'
              : 'You will return to the Sign In screen and need to log in again to access your vault.',
          style: TextStyle(fontSize: 13, color: ctx.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isHi ? 'रद्द करें' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRose,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
            },
            child: Text(isHi ? 'साइन आउट करें' : 'Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showInfoSheet(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required List<(String, String)> sections,
  }) {
    showDhanBottomSheet(context, builder: (ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: ctx.isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ctx.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...sections.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DhanCard(
                  backgroundColor: ctx.isDark ? AppColors.bgHover : AppColors.lightBgCard2,
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.$1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ctx.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.$2,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: ctx.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.isHindi ? 'समझ गया' : 'Got It'),
          ),
        ],
      );
    });
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: context.textTertiary,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: context.border, width: 0.8)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: context.isDark ? 0.16 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: context.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (trailing != null)
              trailing!
            else
              Icon(Icons.chevron_right_rounded, size: 19, color: context.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _LanguageChoiceCard extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChoiceCard({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? context.greenDim.withValues(alpha: 0.5) : context.bgHover.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accentGreen : context.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: ctxSecondary(context)),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? AppColors.accentGreen : context.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Color ctxSecondary(BuildContext c) => c.textSecondary;
}

class _ProfileMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProfileMiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.bgPrimary.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 9.5,
                color: context.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiDiagnosticsStrip extends StatefulWidget {
  final String apiUrl;
  const _ApiDiagnosticsStrip({required this.apiUrl});

  @override
  State<_ApiDiagnosticsStrip> createState() => _ApiDiagnosticsStripState();
}

class _ApiDiagnosticsStripState extends State<_ApiDiagnosticsStrip> {
  bool _loading = false;
  ApiHealthStatus? _status;

  Future<void> _testApi() async {
    setState(() => _loading = true);
    final result = await context.read<AuthCubit>().checkBackendHealth();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _status = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgHover : AppColors.lightBgCard2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.dns_outlined, size: 14, color: context.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.apiUrl,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                ),
              ),
              TextButton.icon(
                onPressed: _loading ? null : _testApi,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  _loading ? Icons.sync_rounded : Icons.network_check_rounded,
                  size: 13,
                ),
                label: Text(_loading ? 'Checking...' : 'Test API',
                    style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
          if (_status != null) ...[
            const SizedBox(height: 4),
            Text(
              _status!.message,
              style: TextStyle(
                fontSize: 10.5,
                color: _status!.isFullyReady
                    ? AppColors.accentGreen
                    : (_status!.reachable ? AppColors.accentAmber : AppColors.accentRose),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
