import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'backup_service.dart';

class AppUpdateService {
  static final AppUpdateService instance = AppUpdateService._internal();
  static const String _lastVersionKey = 'last_app_version';
  static const String _lastBackupKey = 'last_backup_timestamp';
  static const int _backupIntervalHours = 24; // Minimum hours between auto backups

  AppUpdateService._internal();

  /// Kiểm tra và xử lý cập nhật ứng dụng
  /// Gọi hàm này khi ứng dụng khởi động
  Future<bool> checkAndHandleUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final lastVersion = prefs.getString(_lastVersionKey) ?? '';
      
      debugPrint('Current app version: $currentVersion, Last version: $lastVersion');
      
      // Nếu phiên bản hiện tại khác với phiên bản đã lưu, có thể đã có cập nhật
      if (lastVersion.isNotEmpty && lastVersion != currentVersion) {
        debugPrint('App update detected: $lastVersion -> $currentVersion');
        
        // Lưu phiên bản mới
        await prefs.setString(_lastVersionKey, currentVersion);
        
        // Kiểm tra xem có cần khôi phục dữ liệu không
        return await _handleAppUpdate();
      } else if (lastVersion.isEmpty) {
        // Lần đầu cài đặt ứng dụng
        await prefs.setString(_lastVersionKey, currentVersion);
        // Tạo bản sao lưu ban đầu
        await _createBackupIfNeeded();
      }
      
      return false; // Không có cập nhật
    } catch (e) {
      debugPrint('Error checking app update: $e');
      return false;
    }
  }

  /// Xử lý khi phát hiện cập nhật ứng dụng
  Future<bool> _handleAppUpdate() async {
    try {
      // Tạo bản sao lưu sau khi cập nhật
      final backupPath = await _createBackupIfNeeded();
      debugPrint('Created post-update backup at: $backupPath');
      
      return true;
    } catch (e) {
      debugPrint('Error handling app update: $e');
      return false;
    }
  }

  /// Tạo bản sao lưu nếu cần thiết
  Future<String?> _createBackupIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackupTimestamp = prefs.getInt(_lastBackupKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Kiểm tra xem đã đủ thời gian để tạo bản sao lưu mới chưa
      if (now - lastBackupTimestamp > _backupIntervalHours * 3600 * 1000) {
        final backupPath = await BackupService.instance.exportToJSON();
        await prefs.setInt(_lastBackupKey, now);
        return backupPath;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      return null;
    }
  }

  /// Tạo bản sao lưu ngay lập tức, bỏ qua kiểm tra thời gian
  Future<String?> createImmediateBackup() async {
    try {
      final backupPath = await BackupService.instance.exportToJSON();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBackupKey, DateTime.now().millisecondsSinceEpoch);
      return backupPath;
    } catch (e) {
      debugPrint('Error creating immediate backup: $e');
      return null;
    }
  }
}
