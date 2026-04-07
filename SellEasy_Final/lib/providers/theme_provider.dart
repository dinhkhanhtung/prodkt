import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'dart:async';

enum ThemeModeOption { light, dark, system, auto }

class ThemeProvider with ChangeNotifier {
  static const String _themeModeOptionKey = 'theme_mode_option';
  static const String _themeColorKey = 'theme_color';
  static const String _currentTabKey = 'current_tab_index';
  static const String _scrollPositionKey = 'settings_scroll_position';

  ThemeMode _themeMode = ThemeMode.light;
  ThemeModeOption _themeModeOption = ThemeModeOption.light;
  String _themeColor = 'blue';
  int _currentTabIndex = 0;
  double _scrollPosition = 0.0;
  Timer? _autoThemeTimer;

  // Thời gian bắt đầu và kết thúc chế độ tối tự động (giờ trong ngày)
  int _darkModeStartHour = 18; // 6 PM
  int _darkModeEndHour = 6; // 6 AM

  // Thêm các biến để lưu trữ theme hiện tại
  ThemeData _lightTheme = AppTheme.lightTheme;
  ThemeData _darkTheme = AppTheme.darkTheme;

  ThemeProvider() {
    // Khởi tạo theme mặc định
    AppTheme.currentTheme = 'blue';
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  ThemeModeOption get themeModeOption => _themeModeOption;
  String get themeColor => _themeColor;
  int get currentTabIndex => _currentTabIndex;
  double get scrollPosition => _scrollPosition;
  int get darkModeStartHour => _darkModeStartHour;
  int get darkModeEndHour => _darkModeEndHour;

  // Getter cho theme hiện tại
  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;

  // Cập nhật theme dựa trên màu sắc
  void _updateThemes(String color) {
    // Đặt màu chủ đạo mới
    AppTheme.currentTheme = color;
    // Tạo theme mới
    _lightTheme = AppTheme.lightTheme;
    _darkTheme = AppTheme.darkTheme;
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeOptionIndex = prefs.getInt(_themeModeOptionKey) ?? 0;
      final color = prefs.getString(_themeColorKey) ?? 'blue';
      final tabIndex = prefs.getInt(_currentTabKey) ?? 0;
      final scrollPos = prefs.getDouble(_scrollPositionKey) ?? 0.0;

      _themeModeOption = ThemeModeOption.values[themeModeOptionIndex];
      _themeColor = color;
      _currentTabIndex = tabIndex;
      _scrollPosition = scrollPos;

      _updateThemes(color);
      _updateThemeMode();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  // Cập nhật chế độ theme dựa trên tùy chọn đã chọn
  void _updateThemeMode() {
    switch (_themeModeOption) {
      case ThemeModeOption.light:
        _themeMode = ThemeMode.light;
        _cancelAutoThemeTimer();
        break;
      case ThemeModeOption.dark:
        _themeMode = ThemeMode.dark;
        _cancelAutoThemeTimer();
        break;
      case ThemeModeOption.system:
        _themeMode = ThemeMode.system;
        _cancelAutoThemeTimer();
        break;
      case ThemeModeOption.auto:
        _setupAutoThemeTimer();
        break;
    }
  }

  // Thiết lập timer để tự động thay đổi theme theo thời gian
  void _setupAutoThemeTimer() {
    _cancelAutoThemeTimer(); // Hủy timer cũ nếu có

    // Cập nhật theme ngay lập tức dựa trên thời gian hiện tại
    _updateAutoThemeBasedOnTime();

    // Thiết lập timer để kiểm tra mỗi phút
    _autoThemeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateAutoThemeBasedOnTime();
    });
  }

  // Hủy timer tự động thay đổi theme
  void _cancelAutoThemeTimer() {
    _autoThemeTimer?.cancel();
    _autoThemeTimer = null;
  }

  // Cập nhật theme dựa trên thời gian hiện tại
  void _updateAutoThemeBasedOnTime() {
    final now = DateTime.now();
    final hour = now.hour;

    // Kiểm tra xem có phải là thời gian cho chế độ tối không
    final isDarkTime = _isDarkTime(hour);

    // Cập nhật theme nếu cần
    final newThemeMode = isDarkTime ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode != newThemeMode) {
      _themeMode = newThemeMode;
      notifyListeners();
    }
  }

  // Kiểm tra xem giờ hiện tại có phải là thời gian cho chế độ tối không
  bool _isDarkTime(int hour) {
    // Nếu thời gian bắt đầu < thời gian kết thúc (ví dụ: 18h - 6h)
    if (_darkModeStartHour < _darkModeEndHour) {
      return hour >= _darkModeStartHour || hour < _darkModeEndHour;
    }
    // Nếu thời gian bắt đầu > thời gian kết thúc (ví dụ: 22h - 6h)
    else {
      return hour >= _darkModeStartHour && hour < _darkModeEndHour;
    }
  }

  Future<void> toggleTheme() async {
    try {
      // Chuyển đổi giữa chế độ sáng và tối
      if (_themeModeOption == ThemeModeOption.light) {
        await setThemeModeOption(ThemeModeOption.dark);
      } else {
        await setThemeModeOption(ThemeModeOption.light);
      }
    } catch (e) {
      debugPrint('Error toggling theme: $e');
    }
  }

  Future<void> setThemeModeOption(ThemeModeOption option) async {
    try {
      _themeModeOption = option;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeOptionKey, option.index);

      _updateThemeMode();
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme mode option: $e');
    }
  }

  // Cập nhật thời gian bắt đầu chế độ tối tự động
  Future<void> setDarkModeStartHour(int hour) async {
    try {
      _darkModeStartHour = hour;
      if (_themeModeOption == ThemeModeOption.auto) {
        _updateAutoThemeBasedOnTime();
      }
    } catch (e) {
      debugPrint('Error setting dark mode start hour: $e');
    }
  }

  // Cập nhật thời gian kết thúc chế độ tối tự động
  Future<void> setDarkModeEndHour(int hour) async {
    try {
      _darkModeEndHour = hour;
      if (_themeModeOption == ThemeModeOption.auto) {
        _updateAutoThemeBasedOnTime();
      }
    } catch (e) {
      debugPrint('Error setting dark mode end hour: $e');
    }
  }

  Future<void> setThemeColor(String color) async {
    try {
      if (AppTheme.themeColors.containsKey(color)) {
        _themeColor = color;
        _updateThemes(color);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_themeColorKey, color);

        // Chỉ thông báo cho các widget con của ThemeManager
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting theme color: $e');
    }
  }

  Future<void> saveCurrentTabIndex(int index) async {
    try {
      _currentTabIndex = index;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_currentTabKey, index);
    } catch (e) {
      debugPrint('Error saving tab index: $e');
    }
  }

  Future<void> saveScrollPosition(double position) async {
    try {
      _scrollPosition = position;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_scrollPositionKey, position);
    } catch (e) {
      debugPrint('Error saving scroll position: $e');
    }
  }
}
