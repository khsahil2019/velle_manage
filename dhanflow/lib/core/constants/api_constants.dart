class ApiConstants {
  ApiConstants._();

  // Default Vercel PHP API URL — user can override in Cloud Sync settings
  static const String defaultBaseUrl = 'https://dhanflow-api.vercel.app';
  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const String health = '/api/index.php';
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';
  static const String kpis = '/api/dashboard/kpis';
  static const String debtPlan = '/api/debt-engine/plan';
  static const String cards = '/api/cards';
  static String cardById(String id) => '/api/cards/$id';
  static String cardAvlUpdate(String id) => '/api/cards/$id/avl-update';
  static String cardTransactions(String id) => '/api/cards/$id/transactions';
  static const String loans = '/api/loans';
  static String loanById(String id) => '/api/loans/$id';
  static String loanEmiPaid(String id) => '/api/loans/$id/emi-paid';
  static const String payables = '/api/payables';
  static String payableById(String id) => '/api/payables/$id';
  static String payablePay(String id) => '/api/payables/$id/pay';
  static const String recoveries = '/api/recoveries';
  static String recoveryById(String id) => '/api/recoveries/$id';
  static String recoveryRecord(String id) => '/api/recoveries/$id/record';
  static const String bullion = '/api/bullion';
  static const String bullionSummary = '/api/bullion/summary';
  static const String bullionTransactions = '/api/bullion/transactions';
  static const String activity = '/api/activity';
  static const String backupExport = '/api/backup/export';
  static const String backupImport = '/api/backup/import';
  static const String backupReset = '/api/backup/reset-seed';
}
