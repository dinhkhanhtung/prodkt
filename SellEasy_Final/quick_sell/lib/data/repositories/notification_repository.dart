import '../models/notification_model.dart';
import '../../services/database_helper.dart';

class NotificationRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Get all notifications
  Future<List<NotificationModel>> getAllNotifications() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      orderBy: 'date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return NotificationModel.fromMap(maps[i]);
    });
  }

  // Get notification by id
  Future<NotificationModel?> getNotificationById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return NotificationModel.fromMap(maps.first);
    }
    
    return null;
  }

  // Insert a notification
  Future<int> insertNotification(NotificationModel notification) async {
    final db = await _databaseHelper.database;
    return await db.insert('notifications', notification.toMap());
  }

  // Update a notification
  Future<int> updateNotification(NotificationModel notification) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'notifications',
      notification.toMap(),
      where: 'id = ?',
      whereArgs: [notification.id],
    );
  }

  // Delete a notification
  Future<int> deleteNotification(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mark notification as read
  Future<int> markNotificationAsRead(int id) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mark all notifications as read
  Future<int> markAllNotificationsAsRead() async {
    final db = await _databaseHelper.database;
    return await db.update(
      'notifications',
      {'is_read': 1},
    );
  }

  // Get unread notifications
  Future<List<NotificationModel>> getUnreadNotifications() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'is_read = ?',
      whereArgs: [0],
      orderBy: 'date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return NotificationModel.fromMap(maps[i]);
    });
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE is_read = 0',
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Delete all notifications
  Future<int> deleteAllNotifications() async {
    final db = await _databaseHelper.database;
    return await db.delete('notifications');
  }

  // Delete read notifications
  Future<int> deleteReadNotifications() async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'notifications',
      where: 'is_read = ?',
      whereArgs: [1],
    );
  }
}
