import 'package:flutter/foundation.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String _error = '';
  int _unreadCount = 0;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get unreadCount => _unreadCount;

  // Load all notifications
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _notifications = await _repository.getAllNotifications();
      await _updateUnreadCount();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add a notification
  Future<bool> addNotification(NotificationModel notification) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final id = await _repository.insertNotification(notification);
      final addedNotification = notification.copyWith(id: id);
      _notifications.add(addedNotification);
      await _updateUnreadCount();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(int id) async {
    try {
      await _repository.markNotificationAsRead(id);
      
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
      
      await _updateUnreadCount();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _repository.markAllNotificationsAsRead();
      
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      
      await _updateUnreadCount();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete a notification
  Future<bool> deleteNotification(int id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _repository.deleteNotification(id);
      _notifications.removeWhere((notification) => notification.id == id);
      await _updateUnreadCount();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete all read notifications
  Future<bool> deleteReadNotifications() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _repository.deleteReadNotifications();
      _notifications.removeWhere((notification) => notification.isRead);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update unread count
  Future<void> _updateUnreadCount() async {
    try {
      _unreadCount = await _repository.getUnreadNotificationCount();
    } catch (e) {
      _error = e.toString();
    }
  }

  // Get unread notifications
  Future<List<NotificationModel>> getUnreadNotifications() async {
    try {
      return await _repository.getUnreadNotifications();
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }
}
