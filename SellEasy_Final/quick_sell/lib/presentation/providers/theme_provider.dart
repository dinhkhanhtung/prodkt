import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _themeColor = 'green';
  int _currentTabIndex = 0;
  int _lastManagementScreen = 0;

  ThemeMode get themeMode => _themeMode;
  String get themeColor => _themeColor;
  int get currentTabIndex => _currentTabIndex;
  int get lastManagementScreen => _lastManagementScreen;

  ThemeData get lightTheme => AppTheme.lightTheme;
  ThemeData get darkTheme => AppTheme.darkTheme;

  ThemeProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme mode
    final themeModeString = prefs.getString(AppConstants.keyThemeMode) ?? 'light';
    _themeMode = themeModeString == 'dark' ? ThemeMode.dark : ThemeMode.light;
    
    // Load theme color
    _themeColor = prefs.getString(AppConstants.keyThemeColor) ?? 'green';
    AppTheme.currentTheme = _themeColor;
    
    // Load current tab index
    _currentTabIndex = prefs.getInt(AppConstants.keyCurrentTabIndex) ?? 0;
    
    // Load last management screen
    _lastManagementScreen = prefs.getInt(AppConstants.keyLastManagementScreen) ?? 0;
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.keyThemeMode, 
      mode == ThemeMode.dark ? 'dark' : 'light'
    );
    notifyListeners();
  }

  Future<void> setThemeColor(String color) async {
    _themeColor = color;
    AppTheme.currentTheme = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeColor, color);
    notifyListeners();
  }

  Future<void> saveCurrentTabIndex(int index) async {
    _currentTabIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyCurrentTabIndex, index);
    notifyListeners();
  }

  Future<void> saveLastManagementScreen(int index) async {
    _lastManagementScreen = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyLastManagementScreen, index);
    notifyListeners();
  }

  bool isDarkMode() {
    return _themeMode == ThemeMode.dark;
  }

  void toggleThemeMode() {
    setThemeMode(_themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }
}
