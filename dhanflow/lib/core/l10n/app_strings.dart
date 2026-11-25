import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/dhanflow_cubit.dart';

/// Simple, everyday-language English & Hindi (हिन्दी) dictionary for Trustvly.
class AppStrings {
  AppStrings._();

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      // Navigation
      'nav_home': 'Home',
      'nav_debt': 'Debt',
      'nav_kullena': 'Kul Lena',
      'nav_assets': 'Assets',
      'nav_profile': 'Profile',

      // Brand & Status
      'app_tagline': 'Easy Debt, Recovery & Assets',
      'synced': 'Synced',
      'syncing': 'Syncing',
      'retry': 'Retry',
      'local': 'Saved Here',

      // Auth Screen
      'auth_welcome': 'Welcome to Trustvly',
      'auth_subtitle':
          'Sign up or sign in once — your cards, loans, recoveries & assets stay permanently logged in and synced.',
      'auth_permanent_badge': '1-Time Sign In · Permanent Account Lock',
      'auth_signin': 'Sign In',
      'auth_signup': 'Create Account',
      'auth_fullname': 'Your Full Name',
      'auth_email': 'Email Address',
      'auth_password': 'Password (8+ chars)',
      'auth_signin_btn': 'Sign In & Open App',
      'auth_signup_btn': 'Create Account & Start',
      'auth_keep_local': 'Save my current device entries into this new account',
      'auth_keep_local_sub': 'Keeps your active cards, loans & asset entries',
      'auth_load_demo': 'Start with ready-to-edit sample data',
      'auth_api_toggle': 'Server Connection & API Health Check',

      // Overview
      'home_hi': 'Hi',
      'home_subtitle': 'Your daily financial snapshot',
      'ov_positive': 'YOU ARE NET POSITIVE',
      'ov_liability': 'REMAINING NET TO CLEAR',
      'ov_true_net_pos': 'Net Balance (After your assets)',
      'ov_coverage': 'Assets & Recoveries Cover',
      'ov_covered_short': 'covered',
      'ov_pay_due': 'Pay Card',
      'ov_add_spend': 'Add Spend',
      'ov_kullena': 'Kul Lena',
      'ov_add_asset': 'Add Asset',
      'ov_cc_due': 'Credit Cards Due',
      'ov_loans_owed': 'Loans & Owed',
      'ov_loans_owed_sub': 'Active EMIs & personal dues',
      'ov_kul_dena': 'Kul Dena',
      'ov_kul_dena_sub': 'Cards + Loans + Personal Owed',
      'ov_kul_lena': 'Kul Lena',
      'ov_net_before_assets': 'Net Before Assets',
      'ov_net_before_sub': 'Owed minus Coming Back',
      'ov_my_assets': 'My Assets',
      'ov_my_assets_sub': 'Gold, Silver, Diamonds & items',
      'ov_true_net_tile': 'Final Net Position',
      'ov_true_net_sub': 'After all your owned assets',
      'ov_pocket_debt': 'Your Pocket Card Debt',
      'ov_note':
          'Simple Formula: Net Balance = (Money You Owe − Money Coming Back) − Your Total Assets.',
      'ov_strategy_title': 'Debt Freedom Plan',
      'ov_months_left': 'mos to freedom',
      'ov_next_target': 'Next target',
      'ov_saves': 'Saves',
      'ov_all_cleared': 'All tracked debts are completely cleared! You are financially free.',
      'ov_health_title': 'Money Health Score',
      'ov_snapshot_title': 'What You Owe vs What You Own',
      'ov_snapshot_sub': 'Easy comparison in ₹ across cards, loans, recoveries & assets',
      'ov_smart_radar': 'Helpful Alerts & Tips',
      'ov_smart_radar_sub': 'Automatic reminders for high card usage & quick wins',
      'ov_recent_activity': 'Recent Activity',
      'ov_recent_sub': 'Latest payments, spends, recoveries & asset logs',
      'ov_no_activity': 'No recent activity recorded yet.',
      'ov_see_all': 'View All',
      'chart_cc': 'Cards',
      'chart_loans': 'Loans',
      'chart_owed': 'Owed',
      'chart_lena': 'Kul Lena',
      'chart_assets': 'Assets',

      // Debt Tab
      'debt_cards': 'Cards',
      'debt_loans_payables': 'Loans & Owed',
      'debt_payoff_plan': 'Payoff Plan',
      'debt_wallet': 'Your Credit Cards',
      'debt_tap_hint': 'Tap any card to quickly update available limit, pay bill, or edit tag',
      'debt_add_card': 'Add Card',
      'debt_total_due': 'TOTAL DUE',
      'debt_avl_limit': 'AVAILABLE LIMIT',
      'debt_used': 'USED %',
      'debt_filter_all': 'All',
      'debt_filter_active': 'Pending',
      'debt_filter_cleared': 'Cleared',
      'debt_loans_title': 'Active EMI Loans',
      'debt_payables_title': 'Money Owed to People',
      'debt_add_loan': 'Add Loan',
      'debt_add_payable': 'Add Owed',
      'debt_mark_emi': 'Mark 1 EMI Paid',
      'debt_record_pay': 'Record Payment',

      // Kul Lena Tab
      'rec_badge': 'KUL LENA · MONEY COMING BACK',
      'rec_total_pending': 'Total Money People Owe You',
      'rec_add_person': 'Add Person',
      'rec_progress': 'Collected So Far',
      'rec_active': 'Pending',
      'rec_settled': 'Cleared',
      'rec_recovered': 'Collected',
      'rec_filter_all': 'All',
      'rec_filter_active': 'Pending',
      'rec_filter_settled': 'Cleared',
      'rec_got_payment': 'Got Payment',
      'rec_lend_more': 'Give More',
      'rec_info':
          'Safe tracking: Money people owe you stays separate from Credit Cards unless you link a received payment directly to a card.',

      // Assets Tab
      'ast_badge': 'MY ASSETS VAULT',
      'ast_total': 'Total Value of Things You Own',
      'ast_sub': 'Gold, Silver, Diamonds, Property, Cash & Personal Items',
      'ast_add': 'Add Asset',
      'ast_items_title': 'Diamonds, Jewelry & Things You Own',
      'ast_items_sub': 'Tap any card to update value or edit details',
      'ast_metals_title': 'Gold & Silver (By Weight)',
      'ast_metals_sub': 'Track exact grams & check live market value',

      // Profile & Menu
      'prof_menu_tab': 'Profile & Menu',
      'prof_activity_tab': 'Activity Log',
      'prof_section_quick': 'Account & Logs',
      'prof_section_pref': 'Easy Settings & Language',
      'prof_section_sync': 'Backup & Cloud Vault',
      'prof_section_more': 'Privacy, Security & Help',
      'prof_activity_tile': 'Activity & History Logs',
      'prof_activity_sub': 'View all card, loan, asset, recovery & local JSON logs',
      'prof_lang_tile': 'App Language',
      'prof_lang_sub': 'English / हिन्दी (Hindi)',
      'prof_theme_tile': 'Appearance Theme',
      'prof_theme_dark': 'Dark Mode Active (Tap for White Mode)',
      'prof_theme_light': 'White Mode Active (Tap for Dark Mode)',
      'prof_mask_tile': 'Hide Rupee Figures',
      'prof_mask_sub': 'Mask ₹ balances on home & cards for privacy',
      'prof_payoff_tile': 'Debt Freedom Strategy & Budget',
      'prof_cloud_tile': 'Cloud Sync & Server Diagnostics',
      'prof_json_tile': 'Local JSON Export, Import & Reset',
      'prof_privacy_policy': 'Privacy Policy',
      'prof_privacy_sub': 'How your data is stored privately with zero tracking',
      'prof_terms': 'Terms & Financial Disclaimer',
      'prof_terms_sub': 'Simple rules, CIBIL note & delete safety protection',
      'prof_security': 'Security & Protected Delete Lock',
      'prof_security_sub': '1-time permanent login & typed DELETE safeguard',
      'prof_help': 'How to Use Trustvly (Easy Guide)',
      'prof_help_sub': 'Step-by-step plain guide for every screen',
      'prof_about': 'About Trustvly',
      'prof_about_sub': 'App version, mission & cloud-ready architecture',
      'prof_signout': 'Sign Out of Account',
      'prof_signout_sub': 'Returns to the mandatory Sign In screen',
    },
    'hi': {
      // Navigation
      'nav_home': 'होम',
      'nav_debt': 'कर्ज़',
      'nav_kullena': 'कुल लेना',
      'nav_assets': 'संपत्ति',
      'nav_profile': 'प्रोफ़ाइल',

      // Brand & Status
      'app_tagline': 'कर्ज़, उधार और संपत्ति का आसान हिसाब',
      'synced': 'सिंक है',
      'syncing': 'सिंक जारी',
      'retry': 'पुनः प्रयास',
      'local': 'सेव है',

      // Auth Screen
      'auth_welcome': 'Trustvly में आपका स्वागत है',
      'auth_subtitle':
          'एक बार साइन इन या नया खाता बनाएं — आपका डेटा और लॉगिन हमेशा सुरक्षित और स्थायी रहेगा।',
      'auth_permanent_badge': 'एक बार लॉगिन · हमेशा साइन इन रहेगा',
      'auth_signin': 'साइन इन',
      'auth_signup': 'नया खाता बनाएं',
      'auth_fullname': 'आपका पूरा नाम',
      'auth_email': 'ईमेल पता',
      'auth_password': 'पासवर्ड (कम से कम 8 अक्षर)',
      'auth_signin_btn': 'साइन इन करें और ऐप खोलें',
      'auth_signup_btn': 'खाता बनाएं और शुरू करें',
      'auth_keep_local': 'इस फ़ोन का मौजूदा डेटा नए खाते में सेव करें',
      'auth_keep_local_sub': 'आपके कार्ड, लोन और संपत्ति का डेटा बना रहेगा',
      'auth_load_demo': 'तैयार सैंपल डेटा के साथ शुरू करें',
      'auth_api_toggle': 'सर्वर कनेक्शन और API जांचें',

      // Overview
      'home_hi': 'नमस्ते',
      'home_subtitle': 'आपके पैसों का पूरा हिसाब',
      'ov_positive': 'आप फायदे में हैं (संपत्ति ज़्यादा)',
      'ov_liability': 'कुल बाकी चुकाने वाला कर्ज़',
      'ov_true_net_pos': 'असली नेट हिसाब (संपत्ति घटाने के बाद)',
      'ov_coverage': 'संपत्ति और वसूली से कवर',
      'ov_covered_short': 'कवर',
      'ov_pay_due': 'कार्ड भरें',
      'ov_add_spend': 'खर्च लिखें',
      'ov_kullena': 'कुल लेना',
      'ov_add_asset': 'संपत्ति जोड़ें',
      'ov_cc_due': 'क्रेडिट कार्ड बकाया',
      'ov_loans_owed': 'लोन और उधार',
      'ov_loans_owed_sub': 'बाकी EMI और निजी उधार',
      'ov_kul_dena': 'कुल देना',
      'ov_kul_dena_sub': 'कार्ड + लोन + उधार बाकी',
      'ov_kul_lena': 'कुल लेना',
      'ov_net_before_assets': 'संपत्ति से पहले नेट',
      'ov_net_before_sub': 'कुल देना घटाव कुल लेना',
      'ov_my_assets': 'मेरी संपत्ति',
      'ov_my_assets_sub': 'सोना, चांदी, हीरा और आपका सामान',
      'ov_true_net_tile': 'अंतिम नेट स्थिति',
      'ov_true_net_sub': 'सभी संपत्तियों को जोड़ने के बाद',
      'ov_pocket_debt': 'आपका जेब वाला कार्ड कर्ज़',
      'ov_note':
          'आसान नियम: असली नेट हिसाब = (कुल देना − कुल लेना) − आपकी कुल संपत्ति।',
      'ov_strategy_title': 'कर्ज़ मुक्ति प्लान',
      'ov_months_left': 'महीने में मुक्ति',
      'ov_next_target': 'पहला लक्ष्य',
      'ov_saves': 'बचत',
      'ov_all_cleared': 'आपका पूरा ट्रैक किया गया कर्ज़ साफ़ हो चुका है!',
      'ov_health_title': 'वित्तीय सेहत स्कोर',
      'ov_snapshot_title': 'कर्ज़ बनाम संपत्ति चार्ट',
      'ov_snapshot_sub': 'कार्ड, लोन, वसूली और संपत्ति की आसान तुलना (₹)',
      'ov_smart_radar': 'जरूरी सुझाव और अलर्ट',
      'ov_smart_radar_sub': 'ज़्यादा उपयोग वाले कार्ड और बचत के सुझाव',
      'ov_recent_activity': 'हाल की गतिविधियाँ',
      'ov_recent_sub': 'ताज़ा पेमेंट, खर्च, वसूली और संपत्ति का रिकॉर्ड',
      'ov_no_activity': 'अभी तक कोई गतिविधि दर्ज नहीं हुई है।',
      'ov_see_all': 'सभी देखें',
      'chart_cc': 'कार्ड',
      'chart_loans': 'लोन',
      'chart_owed': 'उधार',
      'chart_lena': 'लेना',
      'chart_assets': 'संपत्ति',

      // Debt Tab
      'debt_cards': 'कार्ड',
      'debt_loans_payables': 'लोन और उधार',
      'debt_payoff_plan': 'मुक्ति प्लान',
      'debt_wallet': 'आपके क्रेडिट कार्ड',
      'debt_tap_hint': 'लिमिट, खर्च या पेमेंट बदलने के लिए किसी भी कार्ड पर टैप करें',
      'debt_add_card': 'कार्ड जोड़ें',
      'debt_total_due': 'कुल बकाया',
      'debt_avl_limit': 'उपलब्ध लिमिट',
      'debt_used': 'उपयोग %',
      'debt_filter_all': 'सभी',
      'debt_filter_active': 'बाकी',
      'debt_filter_cleared': 'साफ़',
      'debt_loans_title': 'चालू EMI लोन',
      'debt_payables_title': 'लोगों को देना बाकी',
      'debt_add_loan': 'लोन जोड़ें',
      'debt_add_payable': 'उधार जोड़ें',
      'debt_mark_emi': '1 EMI भरी गई',
      'debt_record_pay': 'पेमेंट लिखें',

      // Kul Lena Tab
      'rec_badge': 'कुल लेना · वापस आने वाले पैसे',
      'rec_total_pending': 'लोगों से कुल पैसे लेने बाकी',
      'rec_add_person': 'नाम जोड़ें',
      'rec_progress': 'अब तक वसूली',
      'rec_active': 'बाकी लोग',
      'rec_settled': 'पूरा मिला',
      'rec_recovered': 'वसूल हुआ',
      'rec_filter_all': 'सभी',
      'rec_filter_active': 'बाकी',
      'rec_filter_settled': 'पूरा मिला',
      'rec_got_payment': 'पेमेंट मिला',
      'rec_lend_more': 'और दिए',
      'rec_info':
          'सुरक्षित हिसाब: लोगों से आने वाला पैसा क्रेडिट कार्ड से अलग रहता है, जब तक आप खुद उसे कार्ड में न जोड़ें।',

      // Assets Tab
      'ast_badge': 'मेरी संपत्ति वॉल्ट',
      'ast_total': 'आपकी सभी संपत्तियों की कुल कीमत',
      'ast_sub': 'सोना, चांदी, हीरा, प्रॉपर्टी, नकद और आपका सामान',
      'ast_add': 'संपत्ति जोड़ें',
      'ast_items_title': 'हीरा, गहने और अन्य सामान',
      'ast_items_sub': 'कीमत बदलने या संपादित करने के लिए किसी भी कार्ड पर टैप करें',
      'ast_metals_title': 'वज़न के हिसाब से सोना और चांदी',
      'ast_metals_sub': 'सही ग्राम वज़न और बाज़ार भाव का हिसाब रखें',

      // Profile & Menu
      'prof_menu_tab': 'प्रोफ़ाइल और मेनू',
      'prof_activity_tab': 'गतिविधि लॉग',
      'prof_section_quick': 'खाता और गतिविधि',
      'prof_section_pref': 'भाषा और आसान सेटिंग्स',
      'prof_section_sync': 'क्लाउड और लोकल बैकअप',
      'prof_section_more': 'गोपनीयता, सुरक्षा और मदद',
      'prof_activity_tile': 'सभी गतिविधि और इतिहास लॉग',
      'prof_activity_sub': 'कार्ड, लोन, संपत्ति, वसूली और लोकल JSON लॉग देखें',
      'prof_lang_tile': 'ऐप की भाषा (Language)',
      'prof_lang_sub': 'हिन्दी / English चुनें',
      'prof_theme_tile': 'थीम बदलें (सफ़ेद / डार्क)',
      'prof_theme_dark': 'डार्क मोड चालू है (सफ़ेद के लिए दबाएं)',
      'prof_theme_light': 'सफ़ेद मोड चालू है (डार्क के लिए दबाएं)',
      'prof_mask_tile': 'रुपये छुपाएं (गोपनीयता)',
      'prof_mask_sub': 'स्क्रीन पर ₹ की रकम छुपाने या दिखाने के लिए',
      'prof_payoff_tile': 'कर्ज़ चुकाने का प्लान और बजट',
      'prof_cloud_tile': 'क्लाउड सिंक और सर्वर जांच',
      'prof_json_tile': 'लोकल JSON बैकअप और रिस्टोर',
      'prof_privacy_policy': 'गोपनीयता नीति (Privacy Policy)',
      'prof_privacy_sub': 'आपका डेटा कैसे सुरक्षित और निजी रहता है',
      'prof_terms': 'नियम और शर्तें (Terms)',
      'prof_terms_sub': 'ऐप के नियम, CIBIL नोट और डिलीट सुरक्षा',
      'prof_security': 'डेटा सुरक्षा और लॉक सिस्टम',
      'prof_security_sub': 'स्थायी लॉगिन और DELETE सुरक्षा कवच',
      'prof_help': 'ऐप चलाने का आसान तरीका (Help)',
      'prof_help_sub': 'हर स्क्रीन को इस्तेमाल करने की सरल जानकारी',
      'prof_about': 'Trustvly ऐप के बारे में',
      'prof_about_sub': 'ऐप वर्ज़न और मुख्य विशेषताएं',
      'prof_signout': 'साइन आउट करें',
      'prof_signout_sub': 'साइन-इन स्क्रीन पर वापस जाने के लिए',
    },
  };

  static String get(String key, String langCode) {
    final map = _strings[langCode] ?? _strings['en']!;
    return map[key] ?? _strings['en']![key] ?? key;
  }
}

extension L10nExt on BuildContext {
  String get langCode {
    try {
      return BlocProvider.of<DhanflowCubit>(this, listen: true)
          .state
          .appState
          .settings
          .languageCode;
    } catch (_) {
      return 'en';
    }
  }

  bool get isHindi => langCode == 'hi';
  String tr(String key) => AppStrings.get(key, langCode);
}
