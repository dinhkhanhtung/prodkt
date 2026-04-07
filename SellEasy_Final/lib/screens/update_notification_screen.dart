import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/responsive_utils.dart';
import 'backup_restore_screen.dart';

class UpdateNotificationScreen extends StatelessWidget {
  static const String _updateNotificationShownKey =
      'update_notification_shown_1.0.2+11';

  const UpdateNotificationScreen({Key? key}) : super(key: key);

  static Future<bool> shouldShowNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_updateNotificationShownKey) ?? false);
  }

  static Future<void> markNotificationAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_updateNotificationShownKey, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo cập nhật'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding:
            EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
            _buildUpdateInfo(context),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
            _buildDataProtectionInfo(context),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 32)),
            _buildBackupButton(context),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            _buildCloseButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.system_update_outlined,
          size: ResponsiveUtils.getAdaptiveIconSize(context, 48),
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        Text(
          'Ứng dụng đã được cập nhật',
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 24),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        Text(
          'Phiên bản 1.0.2+11',
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cập nhật này bao gồm:',
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
        _buildUpdateItem(
          context,
          'Cải thiện bảo vệ dữ liệu khi cập nhật ứng dụng',
          'Ứng dụng giờ đây sẽ tự động sao lưu dữ liệu khi phát hiện cập nhật.',
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        _buildUpdateItem(
          context,
          'Sửa lỗi mất dữ liệu khi cập nhật',
          'Chúng tôi đã khắc phục vấn đề mất dữ liệu khi cập nhật ứng dụng qua Google Play.',
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        _buildUpdateItem(
          context,
          'Cải thiện hiệu suất',
          'Tối ưu hóa hiệu suất và sửa các lỗi nhỏ.',
        ),
      ],
    );
  }

  Widget _buildUpdateItem(
      BuildContext context, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(
        left: ResponsiveUtils.getAdaptiveSpacing(context, 8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: ResponsiveUtils.getAdaptiveIconSize(context, 20),
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                    height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataProtectionInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: ResponsiveUtils.getAdaptiveIconSize(context, 24),
              ),
              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
              Text(
                'Bảo vệ dữ liệu của bạn',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
          Text(
            'Mặc dù chúng tôi đã cải thiện việc bảo vệ dữ liệu, chúng tôi vẫn khuyến nghị bạn nên sao lưu dữ liệu thường xuyên, đặc biệt là trước khi cập nhật ứng dụng.',
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
          Text(
            'Nhấn nút "Sao lưu ngay" bên dưới để tạo bản sao lưu mới.',
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BackupRestoreScreen(),
            ),
          );
        },
        icon: const Icon(Icons.backup),
        label: Text(
          'Sao lưu ngay',
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.getAdaptiveSpacing(context, 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await markNotificationAsShown();
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
        child: Text(
          'Đóng',
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.getAdaptiveSpacing(context, 16),
          ),
        ),
      ),
    );
  }
}
