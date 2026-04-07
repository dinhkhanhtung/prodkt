import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/string_utils.dart';
import '../../core/utils/dialog_helper.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    await notificationProvider.loadNotifications();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _isLoading = true;
    });

    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final success = await notificationProvider.markAllAsRead();

    setState(() {
      _isLoading = false;
    });

    if (!success && mounted) {
      DialogHelper.showErrorToast(
        context: context,
        message: 'Không thể đánh dấu tất cả là đã đọc: ${notificationProvider.error}',
      );
    }
  }

  Future<void> _deleteReadNotifications() async {
    final confirmed = await DialogHelper.showConfirmDialog(
      context: context,
      title: 'Xóa thông báo đã đọc',
      content: 'Bạn có chắc chắn muốn xóa tất cả thông báo đã đọc không?',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final success = await notificationProvider.deleteReadNotifications();

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      DialogHelper.showSuccessToast(
        context: context,
        message: 'Đã xóa thông báo đã đọc',
      );
    } else if (mounted) {
      DialogHelper.showErrorToast(
        context: context,
        message: 'Không thể xóa thông báo đã đọc: ${notificationProvider.error}',
      );
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    await notificationProvider.markAsRead(notification.id!);
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final confirmed = await DialogHelper.showConfirmDialog(
      context: context,
      title: 'Xóa thông báo',
      content: 'Bạn có chắc chắn muốn xóa thông báo này không?',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final success = await notificationProvider.deleteNotification(notification.id!);

    setState(() {
      _isLoading = false;
    });

    if (!success && mounted) {
      DialogHelper.showErrorToast(
        context: context,
        message: 'Không thể xóa thông báo: ${notificationProvider.error}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Đánh dấu tất cả là đã đọc',
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Xóa thông báo đã đọc',
            onPressed: _deleteReadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                final notifications = notificationProvider.notifications;
                
                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: ResponsiveUtils.getAdaptiveIconSize(context, 64),
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        Text(
                          'Không có thông báo nào',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                    ),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final Color color = _getNotificationColor(notification.type);
    final IconData icon = _getNotificationIcon(notification.type);

    return Dismissible(
      key: Key('notification_${notification.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteNotification(notification),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _markAsRead(notification),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: notification.isRead ? null : color.withOpacity(0.05),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: ResponsiveUtils.getAdaptiveWidth(context, 40),
                  height: ResponsiveUtils.getAdaptiveWidth(context, 40),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 20),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                      Text(
                        StringUtils.formatDateTime(notification.date),
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'success':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'info':
        return Icons.info;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'success':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }
}
