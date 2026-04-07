import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cài đặt',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 24),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
            
            // Appearance section
            _buildSectionHeader('Giao diện'),
            _buildThemeModeSelector(),
            _buildThemeColorSelector(),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            
            // Data section
            _buildSectionHeader('Dữ liệu'),
            _buildSettingItem(
              icon: Icons.backup,
              title: 'Sao lưu dữ liệu',
              subtitle: 'Sao lưu dữ liệu của bạn để phòng trường hợp mất dữ liệu',
              onTap: () {
                // TODO: Implement backup functionality
                DialogHelper.showToast(
                  context: context,
                  message: 'Tính năng đang phát triển',
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.restore,
              title: 'Khôi phục dữ liệu',
              subtitle: 'Khôi phục dữ liệu từ bản sao lưu',
              onTap: () {
                // TODO: Implement restore functionality
                DialogHelper.showToast(
                  context: context,
                  message: 'Tính năng đang phát triển',
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.delete_outline,
              title: 'Xóa tất cả dữ liệu',
              subtitle: 'Xóa tất cả dữ liệu và đặt lại ứng dụng',
              onTap: () {
                _showDeleteConfirmation();
              },
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            
            // Notifications section
            _buildSectionHeader('Thông báo'),
            _buildNotificationSettings(),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            
            // About section
            _buildSectionHeader('Thông tin'),
            _buildSettingItem(
              icon: Icons.info_outline,
              title: 'Phiên bản',
              subtitle: AppConstants.appVersion,
              onTap: null,
            ),
            _buildSettingItem(
              icon: Icons.star_outline,
              title: 'Đánh giá ứng dụng',
              subtitle: 'Đánh giá ứng dụng trên Google Play',
              onTap: () {
                // TODO: Implement app rating
                DialogHelper.showToast(
                  context: context,
                  message: 'Tính năng đang phát triển',
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.help_outline,
              title: 'Trợ giúp & Hỗ trợ',
              subtitle: 'Liên hệ với chúng tôi nếu bạn cần hỗ trợ',
              onTap: () {
                // TODO: Implement help & support
                DialogHelper.showToast(
                  context: context,
                  message: 'Tính năng đang phát triển',
                );
              },
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.getAdaptiveSpacing(context, 8),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.getAdaptiveSpacing(context, 8),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeModeSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          margin: EdgeInsets.only(
            bottom: ResponsiveUtils.getAdaptiveSpacing(context, 8),
          ),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chế độ giao diện',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeModeOption(
                        title: 'Sáng',
                        icon: Icons.light_mode,
                        isSelected: themeProvider.themeMode == ThemeMode.light,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                    Expanded(
                      child: _buildThemeModeOption(
                        title: 'Tối',
                        icon: Icons.dark_mode,
                        isSelected: themeProvider.themeMode == ThemeMode.dark,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeModeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 12)),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withAlpha(50),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeColorSelector() {
    final colors = [
      {'name': 'green', 'color': const Color(0xFF2E7D32)},
      {'name': 'blue', 'color': const Color(0xFF1976D2)},
      {'name': 'purple', 'color': const Color(0xFF6A1B9A)},
      {'name': 'orange', 'color': const Color(0xFFF57C00)},
      {'name': 'red', 'color': const Color(0xFFD32F2F)},
      {'name': 'pink', 'color': const Color(0xFFD81B60)},
    ];

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          margin: EdgeInsets.only(
            bottom: ResponsiveUtils.getAdaptiveSpacing(context, 8),
          ),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Màu sắc chủ đạo',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                Wrap(
                  spacing: ResponsiveUtils.getAdaptiveSpacing(context, 12),
                  runSpacing: ResponsiveUtils.getAdaptiveSpacing(context, 12),
                  children: colors.map((colorData) {
                    final colorName = colorData['name'] as String;
                    final color = colorData['color'] as Color;
                    final isSelected = themeProvider.themeColor == colorName;

                    return InkWell(
                      onTap: () => themeProvider.setThemeColor(colorName),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withAlpha(100),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.getAdaptiveSpacing(context, 8),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cài đặt thông báo',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            _buildSwitchItem(
              title: 'Thông báo hàng sắp hết',
              value: true,
              onChanged: (value) {
                // TODO: Implement notification settings
              },
            ),
            _buildSwitchItem(
              title: 'Thông báo đơn hàng mới',
              value: true,
              onChanged: (value) {
                // TODO: Implement notification settings
              },
            ),
            _buildSwitchItem(
              title: 'Thông báo báo cáo hàng ngày',
              value: false,
              onChanged: (value) {
                // TODO: Implement notification settings
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.getAdaptiveSpacing(context, 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    DialogHelper.showConfirmDialog(
      context: context,
      title: 'Xóa tất cả dữ liệu',
      content: 'Bạn có chắc chắn muốn xóa tất cả dữ liệu? Hành động này không thể hoàn tác.',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
    ).then((confirmed) {
      if (confirmed == true) {
        // TODO: Implement data deletion
        DialogHelper.showToast(
          context: context,
          message: 'Đã xóa tất cả dữ liệu',
        );
      }
    });
  }
}
