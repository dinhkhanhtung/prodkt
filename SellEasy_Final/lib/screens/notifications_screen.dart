import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../utils/toast_helper.dart';
import '../utils/responsive_utils.dart';
import 'home_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getNotificationSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    await DatabaseHelper.instance.setNotificationSetting(key, value);
    if (mounted) {
      setState(() {
        _settings[key] = value;
      });
      ToastHelper.showSuccess(context, 'Đã cập nhật cài đặt thông báo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông báo',
            style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 20))),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: ListView(
                padding: EdgeInsets.all(
                    ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                children: [
                  _buildNotificationSettingsSection(),
                ],
              ),
            ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900] // Match exactly with appBar color
              : Theme.of(context).colorScheme.primary,
          indicatorColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.primary.withAlpha(51)
              : Colors.white.withAlpha(51),
          elevation: 2,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                  color: isDark
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white);
            }
            return TextStyle(color: isDark ? Colors.grey[400] : Colors.white70);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(
                  color: isDark
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white);
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
      ),
    );
  }

  Widget _buildNotificationSettingsSection() {
    return Card(
      child: Padding(
        padding:
            EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cài đặt thông báo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            Text(
              'Quản lý các thông báo bạn muốn nhận',
              style: TextStyle(
                color: Colors.grey,
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),

            // Thông báo hết hàng
            SwitchListTile(
              title: Text('Thông báo hết hàng',
                  style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 16))),
              subtitle: Text(
                'Nhận thông báo khi sản phẩm còn dưới ${_settings['low_stock_threshold']} đơn vị',
                style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14)),
              ),
              value: _settings['low_stock'] as bool,
              onChanged: (value) => _updateSetting('low_stock', value),
            ),
            if (_settings['low_stock'] as bool)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveUtils.getAdaptiveSpacing(context, 16),
                  0,
                  ResponsiveUtils.getAdaptiveSpacing(context, 16),
                  ResponsiveUtils.getAdaptiveSpacing(context, 16),
                ),
                child: TextFormField(
                  initialValue: _settings['low_stock_threshold'].toString(),
                  decoration: InputDecoration(
                    labelText: 'Ngưỡng cảnh báo hết hàng',
                    border: const OutlineInputBorder(),
                    helperText: 'Số lượng tối thiểu trước khi thông báo',
                    labelStyle: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 16)),
                    helperStyle: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 12)),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final threshold = int.tryParse(value) ?? 5;
                    _updateSetting('low_stock_threshold', threshold);
                  },
                ),
              ),

            // Thông báo công nợ
            SwitchListTile(
              title: Text('Thông báo công nợ',
                  style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 16))),
              subtitle: Text(
                'Nhận thông báo khi khách hàng nợ quá ${_settings['debt_reminder_days']} ngày',
                style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14)),
              ),
              value: _settings['debt_reminder'] as bool,
              onChanged: (value) => _updateSetting('debt_reminder', value),
            ),
            if (_settings['debt_reminder'] as bool)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveUtils.getAdaptiveSpacing(context, 16),
                  0,
                  ResponsiveUtils.getAdaptiveSpacing(context, 16),
                  ResponsiveUtils.getAdaptiveSpacing(context, 16),
                ),
                child: TextFormField(
                  initialValue: _settings['debt_reminder_days'].toString(),
                  decoration: InputDecoration(
                    labelText: 'Số ngày nhắc nhở công nợ',
                    border: const OutlineInputBorder(),
                    helperText: 'Số ngày sau khi khách hàng có công nợ',
                    labelStyle: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 16)),
                    helperStyle: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 12)),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final days = int.tryParse(value) ?? 7;
                    _updateSetting('debt_reminder_days', days);
                  },
                ),
              ),

            // Thông báo đơn hàng mới
            SwitchListTile(
              title: Text('Thông báo đơn hàng mới',
                  style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 16))),
              subtitle: Text(
                'Nhận thông báo khi có đơn hàng mới được tạo',
                style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14)),
              ),
              value: _settings['new_order_notification'] as bool? ?? false,
              onChanged: (value) =>
                  _updateSetting('new_order_notification', value),
            ),

            // Thông báo hết hạn sản phẩm
            SwitchListTile(
              title: Text('Thông báo hết hạn sản phẩm',
                  style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 16))),
              subtitle: Text(
                'Nhận thông báo khi sản phẩm sắp hết hạn sử dụng',
                style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14)),
              ),
              value: _settings['expiry_notification'] as bool? ?? false,
              onChanged: (value) =>
                  _updateSetting('expiry_notification', value),
            ),

            // Thông báo cập nhật ứng dụng
            SwitchListTile(
              title: Text('Thông báo cập nhật ứng dụng',
                  style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 16))),
              subtitle: Text(
                'Nhận thông báo khi có phiên bản mới của ứng dụng',
                style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14)),
              ),
              value: _settings['update_notification'] as bool? ?? true,
              onChanged: (value) =>
                  _updateSetting('update_notification', value),
            ),
          ],
        ),
      ),
    );
  }
}
