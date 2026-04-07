class AppConstants {
  // App info
  static const String appName = 'Quick Sell';
  static const String appVersion = '1.0.0';
  static const int appVersionCode = 1;

  // Database
  static const String dbName = 'quick_sell.db';
  static const int dbVersion = 1;

  // Shared Preferences Keys
  static const String keyFirstRun = 'first_run';
  static const String keyThemeMode = 'theme_mode';
  static const String keyThemeColor = 'theme_color';
  static const String keyCurrentTabIndex = 'current_tab_index';
  static const String keyLastManagementScreen = 'last_management_screen';

  // Navigation
  static const int tabOverview = 0;
  static const int tabInventory = 1;
  static const int tabReports = 2;
  static const int tabManagement = 3;
  static const int tabSettings = 4;

  // Management Screens
  static const int managementOrders = 0;
  static const int managementCustomers = 1;
  static const int managementExpenses = 2;

  // Order status
  static const String orderStatusCompleted = 'Hoàn thành';
  static const String orderStatusProcessing = 'Đang xử lý';
  static const String orderStatusUnpaid = 'Chưa thanh toán';
  static const String orderStatusCancelled = 'Đã hủy';

  // Product status
  static const String productStatusInStock = 'in_stock';
  static const String productStatusLowStock = 'low_stock';
  static const String productStatusOutOfStock = 'out_of_stock';

  // Notification types
  static const String notificationTypeInfo = 'info';
  static const String notificationTypeWarning = 'warning';
  static const String notificationTypeError = 'error';
  static const String notificationTypeSuccess = 'success';

  // Default categories
  static const List<String> defaultExpenseCategories = [
    'Tiền thuê',
    'Điện nước',
    'Lương',
    'Vận chuyển',
    'Khác',
  ];

  static const List<String> defaultOrderCategories = [
    'Bán lẻ',
    'Bán buôn',
    'Bán online',
    'Khác',
  ];

  // Date formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String dbDateFormat = 'yyyy-MM-dd';
  static const String dbDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // Default Values
  static const String defaultCurrency = '₫';
  static const String defaultUnit = 'cái';
}
