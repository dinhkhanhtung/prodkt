import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../utils/dialog_helper.dart';
import '../utils/toast_helper.dart';
import '../providers/theme_provider.dart';
import '../utils/responsive_utils.dart';
import 'home_screen.dart';

class SecurityNotificationsScreen extends StatefulWidget {
  const SecurityNotificationsScreen({super.key});

  @override
  State<SecurityNotificationsScreen> createState() =>
      _SecurityNotificationsScreenState();
}

class _SecurityNotificationsScreenState
    extends State<SecurityNotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  Map<String, dynamic> _securitySettings = {};
  Map<String, dynamic> _notificationSettings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final securitySettings =
        await DatabaseHelper.instance.getSecuritySettings();
    final notificationSettings =
        await DatabaseHelper.instance.getNotificationSettings();

    if (mounted) {
      setState(() {
        _securitySettings = securitySettings;
        _notificationSettings = notificationSettings;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSecuritySetting(String key, bool value) async {
    await DatabaseHelper.instance.setSecuritySetting(key, value);
    if (mounted) {
      setState(() {
        _securitySettings[key] = value;
      });
      ToastHelper.showSuccess(context, 'Đã cập nhật cài đặt bảo mật');
    }
  }

  Future<void> _updateNotificationSetting(String key, dynamic value) async {
    await DatabaseHelper.instance.setNotificationSetting(key, value);
    if (mounted) {
      setState(() {
        _notificationSettings[key] = value;
      });
      ToastHelper.showSuccess(context, 'Đã cập nhật cài đặt thông báo');
    }
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding:
            EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bảo mật',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      SwitchListTile(
                        title: Text('Khóa vẽ hình',
                            style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                    context, 16))),
                        subtitle: Text('Yêu cầu vẽ hình để mở ứng dụng',
                            style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                    context, 14))),
                        value:
                            _securitySettings['pattern_lock'] as bool? ?? false,
                        onChanged: (value) async {
                          if (value) {
                            // Hiển thị màn hình cài đặt khóa vẽ hình
                            await DialogHelper.showAnimatedDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Tính năng đang phát triển',
                                    style: TextStyle(
                                        fontSize:
                                            ResponsiveUtils.getAdaptiveFontSize(
                                                context, 18))),
                                content: Text(
                                  'Tính năng này sẽ được cập nhật trong phiên bản tới.',
                                  style: TextStyle(
                                      fontSize:
                                          ResponsiveUtils.getAdaptiveFontSize(
                                              context, 16)),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Đóng',
                                        style: TextStyle(
                                            fontSize: ResponsiveUtils
                                                .getAdaptiveFontSize(
                                                    context, 14))),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            await _updateSecuritySetting('pattern_lock', false);
                          }
                        },
                      ),
                      SwitchListTile(
                        title: Text('Mã PIN',
                            style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                    context, 16))),
                        subtitle: Text('Yêu cầu mã PIN để mở ứng dụng',
                            style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                    context, 14))),
                        value: _securitySettings['pin_lock'] as bool? ?? false,
                        onChanged: (value) async {
                          if (value) {
                            // Hiển thị màn hình cài đặt PIN
                            await DialogHelper.showAnimatedDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Tính năng đang phát triển',
                                    style: TextStyle(
                                        fontSize:
                                            ResponsiveUtils.getAdaptiveFontSize(
                                                context, 18))),
                                content: Text(
                                  'Tính năng này sẽ được cập nhật trong phiên bản tới.',
                                  style: TextStyle(
                                      fontSize:
                                          ResponsiveUtils.getAdaptiveFontSize(
                                              context, 16)),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Đóng',
                                        style: TextStyle(
                                            fontSize: ResponsiveUtils
                                                .getAdaptiveFontSize(
                                                    context, 14))),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            await _updateSecuritySetting('pin_lock', false);
                          }
                        },
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Card(
      child: Padding(
        padding:
            EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông báo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      SwitchListTile(
                        title: Text('Thông báo hết hàng',
                            style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                    context, 16))),
                        subtitle: Text(
                          'Nhận thông báo khi sản phẩm còn dưới ${_notificationSettings['low_stock_threshold']} đơn vị',
                          style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 14)),
                        ),
                        value: _notificationSettings['low_stock'] as bool? ??
                            false,
                        onChanged: (value) =>
                            _updateNotificationSetting('low_stock', value),
                      ),
                      if (_notificationSettings['low_stock'] as bool? ?? false)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            ResponsiveUtils.getAdaptiveSpacing(context, 16),
                            0,
                            ResponsiveUtils.getAdaptiveSpacing(context, 16),
                            ResponsiveUtils.getAdaptiveSpacing(context, 16),
                          ),
                          child: TextFormField(
                            initialValue:
                                _notificationSettings['low_stock_threshold']
                                    .toString(),
                            decoration: InputDecoration(
                              labelText: 'Ngưỡng cảnh báo hết hàng',
                              border: const OutlineInputBorder(),
                              helperText:
                                  'Số lượng tối thiểu trước khi thông báo',
                              labelStyle: TextStyle(
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                      context, 16)),
                              helperStyle: TextStyle(
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                      context, 12)),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final threshold = int.tryParse(value) ?? 5;
                              _updateNotificationSetting(
                                  'low_stock_threshold', threshold);
                            },
                          ),
                        ),
                      SwitchListTile(
                        title: const Text('Thông báo công nợ'),
                        subtitle: Text(
                          'Nhận thông báo khi khách hàng nợ quá ${_notificationSettings['debt_reminder_days']} ngày',
                        ),
                        value:
                            _notificationSettings['debt_reminder'] as bool? ??
                                false,
                        onChanged: (value) =>
                            _updateNotificationSetting('debt_reminder', value),
                      ),
                      if (_notificationSettings['debt_reminder'] as bool? ??
                          false)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: TextFormField(
                            initialValue:
                                _notificationSettings['debt_reminder_days']
                                    .toString(),
                            decoration: const InputDecoration(
                              labelText: 'Số ngày nhắc nhở công nợ',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Số ngày sau khi tạo đơn hàng để nhắc nhở công nợ',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final days = int.tryParse(value) ?? 7;
                              _updateNotificationSetting(
                                  'debt_reminder_days', days);
                            },
                          ),
                        ),
                      SwitchListTile(
                        title: const Text('Thông báo đơn hàng mới'),
                        subtitle: const Text(
                          'Nhận thông báo khi có đơn hàng mới được tạo',
                        ),
                        value: _notificationSettings['new_order_notification']
                                as bool? ??
                            false,
                        onChanged: (value) => _updateNotificationSetting(
                            'new_order_notification', value),
                      ),
                      SwitchListTile(
                        title: const Text('Thông báo hết hạn sản phẩm'),
                        subtitle: const Text(
                          'Nhận thông báo khi sản phẩm sắp hết hạn sử dụng',
                        ),
                        value: _notificationSettings['expiry_notification']
                                as bool? ??
                            false,
                        onChanged: (value) => _updateNotificationSetting(
                            'expiry_notification', value),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảo mật & Thông báo'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSecuritySection(),
                  const SizedBox(height: 16),
                  _buildNotificationsSection(),
                ],
              ),
            ),
      bottomNavigationBar: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Sử dụng theme hiện tại để xác định màu sắc
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final primaryColor = Theme.of(context).colorScheme.primary;
          // Trong dark mode, sử dụng chính xác màu của appBar (Colors.grey[900])
          final backgroundColor = isDark ? Colors.grey[900] : primaryColor;

          return NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: backgroundColor,
              indicatorColor: isDark
                  ? primaryColor.withAlpha(51)
                  : Colors.white.withAlpha(51), // 0.2 opacity
              elevation: 2,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(color: isDark ? primaryColor : Colors.white);
                }
                return TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.white70);
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return IconThemeData(
                      color: isDark ? primaryColor : Colors.white);
                }
                return IconThemeData(
                    color: isDark ? Colors.grey[400] : Colors.white70);
              }),
            ),
            child: NavigationBar(
              selectedIndex: 2, // Settings tab selected
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) {
                if (index != 2) {
                  // If not the current tab
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return HomeScreen(initialPage: index);
                      },
                    ),
                  );
                } else {
                  Navigator.pop(context); // Return to main settings
                }
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
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
