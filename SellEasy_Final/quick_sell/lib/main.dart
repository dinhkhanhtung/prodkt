import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/auth/welcome_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/providers/providers.dart';
import 'core/constants/app_constants.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo database khi khởi động ứng dụng
  await DatabaseHelper.instance.database;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
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
            title: AppConstants.appName,
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
          data:
              themeProvider.themeMode == ThemeMode.light
                  ? themeProvider.lightTheme
                  : themeProvider.darkTheme,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
    );
  }
}
