import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import 'home_screen.dart';
import '../utils/toast_helper.dart';
import '../providers/theme_provider.dart';
import '../utils/responsive_utils.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() =>
      _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy thông báo từ cơ sở dữ liệu
      final notifications = await DatabaseHelper.instance.getNotifications();

      // Nếu không có thông báo nào, tạo một số thông báo mẫu cho demo
      if (notifications.isEmpty) {
        // Chỉ tạo thông báo mẫu nếu chưa có thông báo nào
        await _createSampleNotifications();
        // Lấy lại thông báo sau khi tạo mẫu
        _notifications = await DatabaseHelper.instance.getNotifications();
      } else {
        _notifications = notifications;
      }
    } catch (e) {
      // Xử lý lỗi nếu có
      if (mounted) {
        ToastHelper.showError(context, 'Không thể tải thông báo: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createSampleNotifications() async {
    // Tạo các thông báo mẫu
    final sampleNotifications = [
      {
        'title': 'Sản phẩm sắp hết hàng',
        'message': 'Sản phẩm "Áo thun nam" chỉ còn 3 đơn vị trong kho',
        'type': 'low_stock',
        'is_read': 0,
        'created_at':
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'related_id': 101,
      },
      {
        'title': 'Nhắc nhở công nợ',
        'message':
            'Khách hàng "Nguyễn Văn A" có khoản nợ 500,000đ quá hạn 7 ngày',
        'type': 'debt_reminder',
        'is_read': 1,
        'created_at':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'related_id': 201,
      },
      {
        'title': 'Đơn hàng mới',
        'message': 'Đơn hàng #1234 đã được tạo thành công',
        'type': 'order',
        'is_read': 0,
        'created_at':
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'related_id': 301,
      },
      {
        'title': 'Cập nhật ứng dụng',
        'message': 'Phiên bản mới 1.0.3 đã sẵn sàng để cập nhật',
        'type': 'system',
        'is_read': 0,
        'created_at':
            DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'related_id': null,
      },
    ];

    // Thêm các thông báo mẫu vào cơ sở dữ liệu
    for (final notification in sampleNotifications) {
      await DatabaseHelper.instance.insertNotification(notification);
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      // Cập nhật trạng thái đã đọc trong cơ sở dữ liệu
      final result = await DatabaseHelper.instance.markNotificationAsRead(id);

      if (result > 0) {
        // Cập nhật UI
        setState(() {
          final index = _notifications
              .indexWhere((notification) => notification['id'] == id);
          if (index != -1) {
            _notifications[index]['is_read'] = 1;
          }
        });

        if (mounted) {
          ToastHelper.showSuccess(context, 'Đã đánh dấu là đã đọc');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Không thể cập nhật trạng thái: $e');
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      // Cập nhật tất cả thông báo là đã đọc trong cơ sở dữ liệu
      final result = await DatabaseHelper.instance.markAllNotificationsAsRead();

      if (result > 0) {
        // Cập nhật UI
        setState(() {
          for (var notification in _notifications) {
            notification['is_read'] = 1;
          }
        });

        if (mounted) {
          ToastHelper.showSuccess(context, 'Đã đánh dấu tất cả là đã đọc');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Không thể cập nhật trạng thái: $e');
      }
    }
  }

  Future<void> _deleteNotification(int id) async {
    try {
      // Xóa thông báo khỏi cơ sở dữ liệu
      final result = await DatabaseHelper.instance.deleteNotification(id);

      if (result > 0) {
        // Cập nhật UI
        setState(() {
          _notifications
              .removeWhere((notification) => notification['id'] == id);
        });

        if (mounted) {
          ToastHelper.showSuccess(context, 'Đã xóa thông báo');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Không thể xóa thông báo: $e');
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      // Xóa tất cả thông báo khỏi cơ sở dữ liệu
      final result = await DatabaseHelper.instance.deleteAllNotifications();

      if (result > 0) {
        // Cập nhật UI
        setState(() {
          _notifications.clear();
        });

        if (mounted) {
          ToastHelper.showSuccess(context, 'Đã xóa tất cả thông báo');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Không thể xóa thông báo: $e');
      }
    }
  }

  String _formatDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'low_stock':
        return Icons.inventory_2;
      case 'debt_reminder':
        return Icons.money_off;
      case 'order':
        return Icons.receipt;
      case 'system':
        return Icons.system_update;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'low_stock':
        return Colors.orange;
      case 'debt_reminder':
        return Colors.red;
      case 'order':
        return Colors.green;
      case 'system':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông báo',
            style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 20))),
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  _markAllAsRead();
                } else if (value == 'clear_all') {
                  _clearAllNotifications();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all,
                          size:
                              ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                      SizedBox(
                          width:
                              ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                      Text('Đánh dấu tất cả là đã đọc',
                          style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 14))),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep,
                          size:
                              ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                      SizedBox(
                          width:
                              ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                      Text('Xóa tất cả thông báo',
                          style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 14))),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: ResponsiveUtils.getAdaptiveIconSize(context, 64),
                        color: Colors.grey[400],
                      ),
                      SizedBox(
                          height:
                              ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                      Text(
                        'Không có thông báo nào',
                        style: TextStyle(
                          fontSize:
                              ResponsiveUtils.getAdaptiveFontSize(context, 18),
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(
                          height:
                              ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                      Text(
                        'Bạn sẽ nhận được thông báo khi có sự kiện mới',
                        style: TextStyle(
                          fontSize:
                              ResponsiveUtils.getAdaptiveFontSize(context, 14),
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['is_read'] == 1;
                      final type = notification['type'] as String;

                      return Dismissible(
                        key: Key(notification['id'].toString()),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _deleteNotification(notification['id']);
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(
                            horizontal:
                                ResponsiveUtils.getAdaptiveSpacing(context, 8),
                            vertical:
                                ResponsiveUtils.getAdaptiveSpacing(context, 4),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _getNotificationColor(type).withAlpha(50),
                              child: Icon(
                                _getNotificationIcon(type),
                                size: ResponsiveUtils.getAdaptiveIconSize(
                                    context, 24),
                                color: _getNotificationColor(type),
                              ),
                            ),
                            title: Text(
                              notification['title'],
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                    context, 16),
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['message'],
                                  style: TextStyle(
                                      fontSize:
                                          ResponsiveUtils.getAdaptiveFontSize(
                                              context, 14)),
                                ),
                                SizedBox(
                                    height: ResponsiveUtils.getAdaptiveSpacing(
                                        context, 4)),
                                Text(
                                  _formatDateTime(notification['created_at']),
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveUtils.getAdaptiveFontSize(
                                            context, 12),
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: isRead
                                ? IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        size:
                                            ResponsiveUtils.getAdaptiveIconSize(
                                                context, 24)),
                                    onPressed: () =>
                                        _deleteNotification(notification['id']),
                                  )
                                : IconButton(
                                    icon: Icon(Icons.done,
                                        size:
                                            ResponsiveUtils.getAdaptiveIconSize(
                                                context, 24)),
                                    onPressed: () =>
                                        _markAsRead(notification['id']),
                                  ),
                            onTap: () {
                              // Đánh dấu là đã đọc khi nhấn vào
                              if (!isRead) {
                                _markAsRead(notification['id']);
                              }

                              // Trong tương lai, sẽ điều hướng đến màn hình liên quan
                              // dựa vào type và related_id
                            },
                            isThreeLine: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getAdaptiveSpacing(
                                  context, 16),
                              vertical: ResponsiveUtils.getAdaptiveSpacing(
                                  context, 8),
                            ),
                          ),
                        ),
                      );
                    },
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
              selectedIndex: 0, // Không có tab được chọn
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(initialPage: index),
                  ),
                );
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
}
