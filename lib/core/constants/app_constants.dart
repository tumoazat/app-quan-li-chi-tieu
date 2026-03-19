class AppConstants {
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingBase = 16.0;
  static const double spacingLg = 20.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;
  static const double spacing3xl = 40.0;
  static const double spacing4xl = 48.0;

  // Border radius
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 16.0;
  static const double borderRadiusXl = 20.0;
  static const double borderRadiusXxl = 24.0;
  static const double borderRadiusFull = 999.0;

  // Animation durations (in milliseconds)
  static const int animationFast = 150;
  static const int animationNormal = 300;
  static const int animationSlow = 500;
  static const int animationVerySlow = 800;

  // Sizes
  static const double iconSizeSm = 16.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;

  static const double avatarSizeSm = 32.0;
  static const double avatarSizeMd = 44.0;
  static const double avatarSizeLg = 64.0;
  static const double avatarSizeXl = 80.0;

  // Button sizes
  static const double buttonHeightSm = 40.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 52.0;
  static const double buttonHeightXl = 56.0;

  // FAB
  static const double fabSize = 56.0;
  static const double fabIconSize = 28.0;

  // Bottom navigation
  static const double bottomNavHeight = 64.0;

  // List item
  static const double listItemHeight = 72.0;
  static const double listItemIconSize = 44.0;

  // Card
  static const double cardElevation = 2.0;
  static const double cardPadding = 20.0;

  // Max content width for tablets/web
  static const double maxContentWidth = 600.0;

  // Transaction types
  static const String transactionTypeExpense = 'expense';
  static const String transactionTypeIncome = 'income';

  // Default currency
  static const String defaultCurrency = 'VND';
  static const String currencySymbol = '₫';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String transactionsCollection = 'transactions';

  // Shared preferences keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingKey = 'onboarding_completed';

  // Notification
  static const String notificationChannelId = 'smart_expense_notifications';
  static const String notificationChannelName = 'Smart Expense Notifications';
  static const String notificationChannelDescription = 'Notifications for expense reminders and budget alerts';

  // Date formats
  static const String dateFormatFull = 'dd/MM/yyyy';
  static const String dateFormatShort = 'dd/MM';
  static const String dateFormatMonth = 'MM/yyyy';
  static const String dateFormatYear = 'yyyy';

  // Limits
  static const int maxTransactionsPerPage = 50;
  static const int recentTransactionsCount = 5;
  static const double maxTransactionAmount = 999999999999.0; // 1 trillion
}
