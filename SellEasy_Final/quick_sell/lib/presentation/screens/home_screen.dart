import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/extensions/app_bar_extensions.dart';
import '../providers/theme_provider.dart';
import 'overview_screen.dart';
import 'inventory/inventory_screen.dart';
import 'reports/reports_screen.dart';
import 'management/management_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialPage;

  const HomeScreen({super.key, this.initialPage = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Khởi tạo với giá trị mặc định trước
    _selectedIndex = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _saveCurrentTabIndex(int index) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.saveCurrentTabIndex(index);
  }

  // Hiển thị hộp thoại xác nhận thoát ứng dụng
  Future<bool> _onWillPop() async {
    // Kiểm tra xem có màn hình nào trong ngăn xếp điều hướng không
    // Nếu có, cho phép quay lại màn hình trước đó mà không hiển thị hộp thoại xác nhận
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      return true; // Cho phép quay lại màn hình trước đó
    }

    // Nếu không có màn hình nào trong ngăn xếp, hiển thị hộp thoại xác nhận thoát
    final shouldPop = await DialogHelper.showConfirmDialog(
      context: context,
      title: 'Xác nhận thoát',
      content: 'Bạn có muốn thoát ứng dụng không?',
      confirmText: 'Thoát',
      cancelText: 'Hủy',
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final result = await _onWillPop();
        if (result && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBarExtensions.noColorTinting(
          context: context,
          title: Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          elevation: 2,
          actions: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                size: ResponsiveUtils.getAdaptiveIconSize(context, 24),
              ),
              tooltip: 'Thông báo',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.help_outline,
                size: ResponsiveUtils.getAdaptiveIconSize(context, 24),
              ),
              tooltip: 'Trợ giúp',
              onPressed: () {
                // TODO: Implement help dialog
                DialogHelper.showToast(
                  context: context,
                  message: 'Tính năng đang phát triển',
                );
              },
            ),
            SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            setState(() => _selectedIndex = index);
            _saveCurrentTabIndex(index);
          },
          children: const [
            OverviewScreen(),
            InventoryScreen(),
            ReportsScreen(),
            ManagementScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            // Sử dụng theme hiện tại để xác định màu sắc
            final isDark = themeProvider.themeMode == ThemeMode.dark;
            final primaryColor = Theme.of(context).colorScheme.primary;
            // Trong dark mode, sử dụng chính xác màu của appBar (Colors.grey[900])
            final backgroundColor = isDark ? Colors.grey[900] : primaryColor;

            return NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: backgroundColor,
                indicatorColor: Colors.white.withAlpha(51), // 0.2 opacity
                elevation: 2,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(
                        context,
                        14,
                      ),
                    );
                  }
                  return TextStyle(
                    color: Colors.white70,
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return IconThemeData(
                      color: Colors.white,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 24),
                    );
                  }
                  return IconThemeData(
                    color: Colors.white70,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 24),
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOut,
                  );
                  _saveCurrentTabIndex(index);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Tổng quan',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2),
                    label: 'Kho hàng',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart),
                    label: 'Báo cáo',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.business_center_outlined),
                    selectedIcon: Icon(Icons.business_center),
                    label: 'Quản lý',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: 'Cài đặt',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
