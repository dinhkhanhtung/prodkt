import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/database_helper.dart';
import 'services/app_update_service.dart';
import 'providers/theme_provider.dart';
import 'providers/purchase_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo database khi khởi động ứng dụng
  await DatabaseHelper.instance.database;

  // Kiểm tra cập nhật ứng dụng và tạo bản sao lưu nếu cần
  await AppUpdateService.instance.checkAndHandleUpdate();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _ThemeManager(
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'SellEasy',
            themeMode: themeProvider.themeMode,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            home: FutureBuilder<bool>(
              future: DatabaseHelper.instance.isFirstRun(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final isFirstRun = snapshot.data ?? true;
                if (isFirstRun) {
                  return const WelcomeScreen();
                }

                // Sử dụng currentTabIndex để khôi phục tab hiện tại
                return HomeScreen(initialPage: themeProvider.currentTabIndex);
              },
            ),
            routes: {'/home': (context) => const HomeScreen()},
          );
        },
      ),
    );
  }
}

// Widget quản lý theme và màu sắc
class _ThemeManager extends StatelessWidget {
  final Widget child;

  const _ThemeManager({required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return AnimatedTheme(
          data: themeProvider.themeMode == ThemeMode.light
              ? themeProvider.lightTheme
              : themeProvider.darkTheme,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
    );
  }
}
