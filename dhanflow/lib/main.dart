import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_colors.dart';
import 'core/network/api_client.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/dhanflow_cubit.dart';
import 'repositories/dhanflow_repository.dart';
import 'screens/splash/splash_screen.dart';
import 'services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bgPrimary,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await Hive.initFlutter();
  await LocalStorageService.init();
  final initialAppState = LocalStorageService.loadState();

  final apiClient = ApiClient(baseUrl: initialAppState.settings.apiBaseUrl);
  final repository = DhanflowRepository(apiClient: apiClient);

  runApp(DhanflowApp(apiClient: apiClient, repository: repository));
}

class DhanflowApp extends StatelessWidget {
  final ApiClient apiClient;
  final DhanflowRepository repository;

  const DhanflowApp({
    super.key,
    required this.apiClient,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => AuthCubit(apiClient: apiClient)..loadSession()),
        BlocProvider(create: (_) => DhanflowCubit(repository: repository)),
      ],
      child: BlocBuilder<DhanflowCubit, DhanflowViewState>(
        builder: (context, state) {
          final themeSetting = state.appState.settings.themeMode;
          final themeMode = themeSetting == 'light'
              ? ThemeMode.light
              : themeSetting == 'system'
                  ? ThemeMode.system
                  : ThemeMode.dark;

          return MaterialApp(
            title: 'Trustvly',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: _buildLightTheme(context),
            darkTheme: _buildDarkTheme(context),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme(BuildContext context) {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBgPrimary,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightBgPrimary,
        surfaceContainerHighest: AppColors.lightBgCard2,
        primary: Color(0xFF059669),
        secondary: Color(0xFFD97706),
        error: Color(0xFFDC2626),
        onSurface: AppColors.lightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightBgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      dividerTheme: const DividerThemeData(
          color: AppColors.lightBorder, thickness: 1, space: 0),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightBgCard2,
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightBgCard2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF059669), width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
        hintStyle: const TextStyle(color: AppColors.lightTextTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  ThemeData _buildDarkTheme(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgPrimary,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bgPrimary,
        surfaceContainerHighest: AppColors.bgCard,
        primary: AppColors.accentGreen,
        secondary: AppColors.accentAmber,
        error: AppColors.accentRose,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: Colors.black,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      dividerTheme: const DividerThemeData(
          color: AppColors.border, thickness: 1, space: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgHover,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.accentGreen, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
