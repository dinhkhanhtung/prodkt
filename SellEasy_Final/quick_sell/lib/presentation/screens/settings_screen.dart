import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../../core/utils/responsive_utils.dart';
import '../../services/database_helper.dart';
import 'settings/backup_restore_screen.dart';
import 'settings/app_settings_screen.dart';
import 'settings/about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        children: [
          _buildSection(
            context,
            'Giao diện',
            [
              _buildSwitchTile(
                context,
                'Chế độ tối',
                'Thay đổi giao diện sáng/tối',
                Icons.dark_mode,
                themeProvider.themeMode == ThemeMode.dark,
                (value) {
                  themeProvider.themeMode = value ? ThemeMode.dark : ThemeMode.light;
                },
              ),
              _buildColorPickerTile(
                context,
                'Màu chủ đạo',
                'Thay đổi màu sắc ứng dụng',
                Icons.color_lens,
                themeProvider.themeColor,
                () {
                  _showColorPickerDialog(context, themeProvider);
                },
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          _buildSection(
            context,
            'Dữ liệu',
            [
              _buildNavigationTile(
                context,
                'Sao lưu & Khôi phục',
                'Sao lưu hoặc khôi phục dữ liệu',
                Icons.backup,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BackupRestoreScreen(),
                    ),
                  );
                },
              ),
              _buildNavigationTile(
                context,
                'Xóa tất cả dữ liệu',
                'Xóa toàn bộ dữ liệu ứng dụng',
                Icons.delete_forever,
                () {
                  _showDeleteConfirmationDialog(context);
                },
                isDestructive: true,
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          _buildSection(
            context,
            'Ứng dụng',
            [
              _buildNavigationTile(
                context,
                'Cài đặt ứng dụng',
                'Thay đổi cài đặt ứng dụng',
                Icons.settings,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppSettingsScreen(),
                    ),
                  );
                },
              ),
              _buildNavigationTile(
                context,
                'Giới thiệu',
                'Thông tin về ứng dụng',
                Icons.info,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 16),
            vertical: ResponsiveUtils.getAdaptiveSpacing(context, 8),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildColorPickerTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
          color: Colors.grey[600],
        ),
      ),
      trailing: Container(
        width: ResponsiveUtils.getAdaptiveWidth(context, 24),
        height: ResponsiveUtils.getAdaptiveWidth(context, 24),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildNavigationTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showColorPickerDialog(BuildContext context, ThemeProvider themeProvider) {
    final List<Color> colors = [
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.green,
      Colors.teal,
      Colors.indigo,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn màu chủ đạo'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((color) {
            return InkWell(
              onTap: () {
                themeProvider.themeColor = color;
                Navigator.pop(context);
              },
              child: Container(
                width: ResponsiveUtils.getAdaptiveWidth(context, 40),
                height: ResponsiveUtils.getAdaptiveWidth(context, 40),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: themeProvider.themeColor == color
                        ? Colors.white
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: themeProvider.themeColor == color
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả dữ liệu?'),
        content: const Text(
          'Hành động này sẽ xóa tất cả dữ liệu bao gồm sản phẩm, đơn hàng, khách hàng và chi tiêu. Dữ liệu đã xóa không thể khôi phục trừ khi bạn đã sao lưu trước đó.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllData(context);
            },
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang xóa dữ liệu...'),
            ],
          ),
        ),
      );
      
      // Delete database
      await DatabaseHelper.instance.deleteDatabase();
      
      // Reinitialize database
      await DatabaseHelper.instance.database;
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success message
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Đã xóa tất cả dữ liệu thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
