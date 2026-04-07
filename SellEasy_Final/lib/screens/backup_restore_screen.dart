import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../services/backup_service.dart';
import '../utils/dialog_helper.dart';
import '../utils/toast_helper.dart';
import '../utils/responsive_utils.dart';
import 'home_screen.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isLoading = false;
  List<FileSystemEntity> _backupFiles = [];

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await BackupService.instance.getBackupFiles();
      if (mounted) {
        setState(() {
          _backupFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Lỗi khi tải danh sách sao lưu: $e', isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      ToastHelper.showError(context, message);
    } else {
      ToastHelper.showSuccess(context, message);
    }
  }

  Future<void> _createLocalBackup() async {
    setState(() => _isLoading = true);
    try {
      final backupPath = await BackupService.instance.exportToJSON();
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Đã sao lưu dữ liệu thành công tại: $backupPath');
        _loadBackupFiles();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage(
          'Không thể sao lưu dữ liệu. Vui lòng kiểm tra quyền truy cập và thử lại sau.',
          isError: true,
        );
      }
    }
  }

  Future<void> _restoreFromBackup(String filePath) async {
    final confirmed = await DialogHelper.showAnimatedDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận khôi phục'),
        content: const Text(
          'Khôi phục sẽ xóa tất cả dữ liệu hiện tại và thay thế bằng dữ liệu từ bản sao lưu. Bạn có chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await BackupService.instance.importFromJSON(filePath);
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          _showMessage('Đã khôi phục dữ liệu thành công');
          // Restart app or navigate to home screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else {
          _showMessage('Không thể khôi phục dữ liệu từ tệp này', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Lỗi khi khôi phục dữ liệu: $e', isError: true);
      }
    }
  }

  Future<void> _showRestoreDialog() async {
    // Filter only JSON backup files
    final jsonBackups = _backupFiles
        .where((file) => path.basename(file.path).endsWith('.json'))
        .toList();

    if (jsonBackups.isEmpty) {
      _showMessage('Không tìm thấy bản sao lưu JSON nào', isError: true);
      return;
    }

    // Sort by modification time (newest first)
    jsonBackups.sort((a, b) {
      return File(b.path)
          .lastModifiedSync()
          .compareTo(File(a.path).lastModifiedSync());
    });

    // Show dialog with list of backups
    final selectedBackup = await DialogHelper.showAnimatedDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn bản sao lưu để khôi phục'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: jsonBackups.length,
            itemBuilder: (context, index) {
              final file = File(jsonBackups[index].path);
              final fileName = path.basename(file.path);
              final fileSize = _formatFileSize(file.lengthSync());
              final modifiedDate = _formatDateTime(file.lastModifiedSync());

              return ListTile(
                title: Text(fileName),
                subtitle: Text('$modifiedDate - $fileSize'),
                onTap: () => Navigator.pop(context, file.path),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (selectedBackup != null) {
      _restoreFromBackup(selectedBackup);
    }
  }

  Future<void> _deleteBackup(String filePath) async {
    final confirmed = await DialogHelper.showAnimatedDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa bản sao lưu này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _showMessage('Đã xóa bản sao lưu');
        _loadBackupFiles();
      }
    } catch (e) {
      _showMessage('Không thể xóa bản sao lưu: $e', isError: true);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }

  Widget _buildBackupItem(FileSystemEntity entity) {
    final file = File(entity.path);
    final fileName = path.basename(entity.path);
    final fileSize = file.lengthSync();
    final modifiedDate = file.lastModifiedSync();
    final isJsonBackup = fileName.endsWith('.json');

    return Card(
      child: ListTile(
        title: Text(fileName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kích thước: ${_formatFileSize(fileSize)}'),
            Text('Ngày tạo: ${_formatDateTime(modifiedDate)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isJsonBackup)
              IconButton(
                icon: const Icon(Icons.restore),
                tooltip: 'Khôi phục',
                onPressed: () => _restoreFromBackup(entity.path),
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Xóa',
              onPressed: () => _deleteBackup(entity.path),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalBackupSection() {
    return Card(
      child: Padding(
        padding:
            EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sao lưu cục bộ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            Text(
              'Sao lưu dữ liệu vào bộ nhớ thiết bị. Bạn có thể khôi phục dữ liệu từ các bản sao lưu này sau này.',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14)),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
            // First row with Sao lưu JSON button
            SizedBox(
              height: ResponsiveUtils.getAdaptiveSpacing(context, 48),
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _createLocalBackup,
                icon: Icon(Icons.save,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                label: Text('Sao lưu JSON',
                    style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 16))),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
            // Khôi phục button
            SizedBox(
              height: ResponsiveUtils.getAdaptiveSpacing(context, 48),
              child: FilledButton.icon(
                onPressed: _isLoading || _backupFiles.isEmpty
                    ? null
                    : () => _showRestoreDialog(),
                icon: Icon(Icons.restore,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                label: Text('Khôi phục',
                    style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 16))),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleBackupSection() {
    return Card(
      child: Padding(
        padding:
            EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sao lưu Google',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            Text(
              'Đăng nhập Google để sao lưu và đồng bộ dữ liệu lên đám mây. Dữ liệu của bạn sẽ được an toàn ngay cả khi mất thiết bị.',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14)),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
            // First row with Đăng nhập Google button
            SizedBox(
              height: ResponsiveUtils.getAdaptiveSpacing(context, 48),
              child: FilledButton.icon(
                onPressed: () {
                  DialogHelper.showAnimatedDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Đăng nhập Google'),
                      content: const Text(
                        'Tính năng này đang được phát triển. Vui lòng thử lại sau.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Đăng nhập Google'),
              ),
            ),
            const SizedBox(height: 12),
            // Second row with Đăng xuất button
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        DialogHelper.showAnimatedDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Tính năng đang phát triển'),
                            content: const Text(
                              'Tính năng đăng xuất sẽ được triển khai sau khi hoàn thành tính năng đồng bộ Google.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      },
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupHistorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử sao lưu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_backupFiles.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Chưa có bản sao lưu nào. Hãy tạo bản sao lưu đầu tiên của bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: _backupFiles
                    .map((entity) => _buildBackupItem(entity))
                    .toList(),
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
        title: const Text('Sao lưu & Khôi phục'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading && _backupFiles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBackupFiles,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildLocalBackupSection(),
                  const SizedBox(height: 16),
                  _buildGoogleBackupSection(),
                  const SizedBox(height: 16),
                  _buildBackupHistorySection(),
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
              : Colors.white.withAlpha(51), // 0.2 opacity
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
}
