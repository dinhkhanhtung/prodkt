import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'inventory_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'notifications_list_screen.dart';
import 'update_notification_screen.dart';
import 'forms/create_order_form.dart';
import 'forms/add_product_form.dart';
import 'forms/add_customer_form.dart';
import 'forms/add_expense_form.dart';
import 'dart:math';
import 'dart:async';
import '../widgets/app_help_dialog.dart';
import '../widgets/inventory_help_dialog.dart';
import '../widgets/reports_help_dialog.dart';
import '../widgets/settings_help_dialog.dart';
import '../utils/dialog_helper.dart';
import '../providers/theme_provider.dart';
import '../utils/responsive_utils.dart';
import '../extensions/app_bar_extensions.dart';
import '../services/app_update_service.dart';

class HomeScreen extends StatefulWidget {
  final int initialPage;

  const HomeScreen({
    super.key,
    this.initialPage = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  bool _isDialOpen = false;
  late final PageController _pageController;
  late final AnimationController _shakeController;
  Timer? _shakeTimer;

  @override
  void initState() {
    super.initState();
    // Khởi tạo với giá trị mặc định trước
    _selectedIndex = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);

    // Sau đó tải vị trí đã lưu và cập nhật nếu cần
    _loadSavedTabIndex();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reset();
        }
      });

    // Tạo timer để rung nút mỗi 10 giây
    _shakeTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isDialOpen && mounted) {
        _shakeController.forward();
      }
    });

    // Kiểm tra và hiển thị thông báo cập nhật nếu cần
    _checkForUpdateNotification();
  }

  Future<void> _checkForUpdateNotification() async {
    // Kiểm tra xem có cần hiển thị thông báo cập nhật không
    final shouldShow = await UpdateNotificationScreen.shouldShowNotification();
    if (shouldShow && mounted) {
      // Đợi một chút để màn hình chính hiển thị trước
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UpdateNotificationScreen(),
            ),
          );
        }
      });
    }
  }

  void _loadSavedTabIndex() {
    // Không cần làm gì vì tab hiện tại đã được khôi phục trong main.dart
    // thông qua HomeScreen(initialPage: themeProvider.currentTabIndex)
  }

  void _saveCurrentTabIndex(int index) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.saveCurrentTabIndex(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shakeController.dispose();
    _shakeTimer?.cancel();
    super.dispose();
  }

  // Hiển thị hộp thoại xác nhận thoát ứng dụng
  Future<bool> _onWillPop() async {
    // Nếu FAB menu đang mở, đóng nó thay vì thoát
    if (_isDialOpen) {
      setState(() => _isDialOpen = false);
      return false;
    }

    // Kiểm tra xem có màn hình nào trong ngăn xếp điều hướng không
    // Nếu có, cho phép quay lại màn hình trước đó mà không hiển thị hộp thoại xác nhận
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      return true; // Cho phép quay lại màn hình trước đó
    }

    // Nếu không có màn hình nào trong ngăn xếp, hiển thị hộp thoại xác nhận thoát
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thoát'),
        content: const Text('Bạn có muốn thoát ứng dụng không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBarExtensions.noColorTinting(
          context: context,
          title: Text(
            'SellEasy - Nhật Ký Bán Hàng Mini',
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          elevation: 2,
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_outlined,
                  size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
              tooltip: 'Thông báo',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsListScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.help_outline,
                  size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
              tooltip: 'Trợ giúp',
              onPressed: () {
                DialogHelper.showAnimatedDialog(
                  context: context,
                  builder: (context) {
                    switch (_selectedIndex) {
                      case 0:
                        return const InventoryHelpDialog();
                      case 1:
                        return const ReportsHelpDialog();
                      case 2:
                        return const SettingsHelpDialog();
                      default:
                        return const AppHelpDialog();
                    }
                  },
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
            InventoryScreen(),
            ReportsScreen(),
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
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 14));
                  }
                  return TextStyle(
                      color: Colors.white70,
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 14));
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return IconThemeData(
                        color: Colors.white,
                        size: ResponsiveUtils.getAdaptiveIconSize(context, 24));
                  }
                  return IconThemeData(
                      color: Colors.white70,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 24));
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
                    icon: Icon(Icons.inventory),
                    selectedIcon: Icon(Icons.inventory),
                    label: 'Kho Hàng',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart),
                    selectedIcon: Icon(Icons.bar_chart),
                    label: 'Báo Cáo',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings),
                    selectedIcon: Icon(Icons.settings),
                    label: 'Cài Đặt',
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: _selectedIndex == 0
            ? AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final sineValue = sin(4 * pi * _shakeController.value);
                  return Transform.translate(
                    offset: Offset(sineValue * 4, 0),
                    child: SpeedDial(
                      icon: Icons.menu,
                      activeIcon: Icons.close,
                      spacing: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                      openCloseDial: ValueNotifier(_isDialOpen),
                      onOpen: () => setState(() => _isDialOpen = true),
                      onClose: () => setState(() => _isDialOpen = false),
                      overlayColor: Colors.black,
                      overlayOpacity: 0.5,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 8.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                      ),
                      spaceBetweenChildren:
                          ResponsiveUtils.getAdaptiveSpacing(context, 12),
                      children: [
                        SpeedDialChild(
                          child: Icon(Icons.receipt_long,
                              size: ResponsiveUtils.getAdaptiveIconSize(
                                  context, 24)),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          label: 'Tạo đơn',
                          labelStyle: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 16)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const CreateOrderForm()),
                          ),
                        ),
                        SpeedDialChild(
                          child: Icon(Icons.inventory_2,
                              size: ResponsiveUtils.getAdaptiveIconSize(
                                  context, 24)),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          label: 'Nhập hàng',
                          labelStyle: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 16)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AddProductForm()),
                          ),
                        ),
                        SpeedDialChild(
                          child: Icon(Icons.person_add,
                              size: ResponsiveUtils.getAdaptiveIconSize(
                                  context, 24)),
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          label: 'Thêm khách hàng',
                          labelStyle: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 16)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AddCustomerForm()),
                          ),
                        ),
                        SpeedDialChild(
                          child: Icon(Icons.payments,
                              size: ResponsiveUtils.getAdaptiveIconSize(
                                  context, 24)),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          label: 'Ghi chi tiêu',
                          labelStyle: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 16)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AddExpenseForm()),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }
}
