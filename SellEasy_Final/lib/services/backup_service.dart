import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  Future<String> exportToCSV() async {
    final db = await DatabaseHelper.instance.database;
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupDir = Directory('${directory.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create();
    }

    final files = <String, String>{};

    // Export products
    final products = await db.query('products');
    files['products.csv'] = _convertToCSV(products);

    // Export orders
    final orders = await db.query('orders');
    files['orders.csv'] = _convertToCSV(orders);

    // Export order items
    final orderItems = await db.query('order_items');
    files['order_items.csv'] = _convertToCSV(orderItems);

    // Export expenses
    final expenses = await db.query('expenses');
    files['expenses.csv'] = _convertToCSV(expenses);

    // Export customers
    final customers = await db.query('customers');
    files['customers.csv'] = _convertToCSV(customers);

    // Export users
    final users = await db.query('users');
    files['users.csv'] = _convertToCSV(users);

    // Write files
    for (final entry in files.entries) {
      final file = File('${backupDir.path}/${timestamp}_${entry.key}');
      await file.writeAsString(entry.value);
    }

    return backupDir.path;
  }

  String _convertToCSV(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';

    final headers = data.first.keys.toList();
    final rows = data
        .map((row) =>
            headers.map((header) => row[header]?.toString() ?? '').toList())
        .toList();

    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  Future<String> exportToJSON() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create();
      }

      final Map<String, List<Map<String, dynamic>>> data = {};

      // Export all tables
      final tables = [
        'products',
        'orders',
        'order_items',
        'expenses',
        'customers',
        'users',
        'settings',
        'custom_fields',
        'product_attributes',
      ];

      // Kiểm tra các bảng có tồn tại không
      final existingTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final existingTableNames = existingTables
          .map((t) => t['name'] as String)
          .where((name) =>
              !name.startsWith('sqlite_') && !name.startsWith('android_'))
          .toList();

      print('Existing tables: $existingTableNames');

      // Thêm bất kỳ bảng nào tồn tại nhưng không có trong danh sách
      for (final tableName in existingTableNames) {
        if (!tables.contains(tableName)) {
          tables.add(tableName);
        }
      }

      final Map<String, int> exportCounts = {};

      for (final table in tables) {
        try {
          final tableData = await db.query(table);
          data[table] = tableData;
          exportCounts[table] = tableData.length;
          print('Exported $table: ${tableData.length} rows');
        } catch (e) {
          print('Error exporting table $table: $e');
          // Continue with other tables even if one fails
        }
      }

      // Kiểm tra xem có bảng nào không có dữ liệu không
      final emptyTables = exportCounts.entries
          .where((entry) => entry.value == 0)
          .map((entry) => entry.key)
          .toList();

      if (emptyTables.isNotEmpty) {
        print('Warning: The following tables have no data: $emptyTables');
      }

      // Kiểm tra xem các bảng quan trọng có dữ liệu không
      final requiredTables = ['products', 'orders', 'order_items', 'customers'];
      final missingTables = requiredTables
          .where((table) =>
              !exportCounts.containsKey(table) || exportCounts[table] == 0)
          .toList();

      if (missingTables.isNotEmpty) {
        print(
            'Warning: The following important tables have no data: $missingTables');
      }

      // Write JSON file
      final filePath = '${backupDir.path}/${timestamp}_backup.json';
      final file = File(filePath);
      await file.writeAsString(jsonEncode(data));

      return filePath;
    } catch (e) {
      print('Error in exportToJSON: $e');
      rethrow;
    }
  }

  Future<String> exportToLocalBackup() async {
    try {
      final dbPath = await getDatabasesPath();
      final sourceDbPath = path.join(dbPath, 'selleasy.db');
      final sourceDb = File(sourceDbPath);

      if (!await sourceDb.exists()) {
        throw Exception('Database file not found');
      }

      // Create backup directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create();
      }

      // Copy database file
      final backupPath = '${backupDir.path}/${timestamp}_backup.db';
      await sourceDb.copy(backupPath);

      return backupPath;
    } catch (e) {
      print('Error in exportToLocalBackup: $e');
      rethrow;
    }
  }

  Future<bool> importFromJSON(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('Backup file does not exist: $filePath');
        return false;
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Reset database
      await DatabaseHelper.instance.forceResetDatabase();
      final db = await DatabaseHelper.instance.database;

      // Define the order of tables to import to respect foreign key constraints
      final tableOrder = [
        'settings',
        'users',
        'customers',
        'products',
        'product_attributes',
        'custom_fields',
        'orders',
        'order_items',
        'expenses',
      ];

      // Count successful imports for each table
      final Map<String, int> successCounts = {};

      // First pass: Import tables in the correct order
      for (final tableName in tableOrder) {
        if (!data.containsKey(tableName)) {
          print('Table $tableName not found in backup data');
          continue;
        }

        final tableData = List<Map<String, dynamic>>.from(
          (data[tableName] as List)
              .map((item) => Map<String, dynamic>.from(item)),
        );

        print('Importing table $tableName with ${tableData.length} rows');
        int successCount = 0;

        for (final row in tableData) {
          try {
            await db.insert(
              tableName,
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            successCount++;
          } catch (e) {
            print('Error importing row to $tableName: $e');
            print('Row data: $row');
            // Continue with other rows even if one fails
          }
        }

        successCounts[tableName] = successCount;
        print(
            'Successfully imported $successCount/${tableData.length} rows to $tableName');
      }

      // Second pass: Import any remaining tables not in the predefined order
      for (final entry in data.entries) {
        final tableName = entry.key;
        if (tableOrder.contains(tableName)) {
          continue; // Skip already imported tables
        }

        final tableData = List<Map<String, dynamic>>.from(
          (entry.value as List).map((item) => Map<String, dynamic>.from(item)),
        );

        print(
            'Importing additional table $tableName with ${tableData.length} rows');
        int successCount = 0;

        for (final row in tableData) {
          try {
            await db.insert(
              tableName,
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            successCount++;
          } catch (e) {
            print('Error importing row to $tableName: $e');
            // Continue with other rows even if one fails
          }
        }

        successCounts[tableName] = successCount;
        print(
            'Successfully imported $successCount/${tableData.length} rows to $tableName');
      }

      // Log summary of import
      print('Import summary:');
      for (final entry in successCounts.entries) {
        final tableName = entry.key;
        final successCount = entry.value;
        final totalCount = (data[tableName] as List?)?.length ?? 0;
        print(
            '$tableName: $successCount/$totalCount rows imported successfully');
      }

      // Verify data integrity after import
      final isDataValid = await _verifyDataIntegrity(db, successCounts);
      if (!isDataValid) {
        print('Data integrity check failed after import');
        return false;
      }

      return true;
    } catch (e) {
      print('Error in importFromJSON: $e');
      return false;
    }
  }

  Future<List<FileSystemEntity>> getBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create();
        return [];
      }

      final files = await backupDir.list().toList();
      // Sort by modification time (newest first)
      files.sort((a, b) {
        return File(b.path).lastModifiedSync().compareTo(
              File(a.path).lastModifiedSync(),
            );
      });

      return files;
    } catch (e) {
      print('Error in getBackupFiles: $e');
      return [];
    }
  }

  Future<bool> _verifyDataIntegrity(
      Database db, Map<String, int> importedCounts) async {
    try {
      // Kiểm tra các bảng quan trọng đã được import
      final requiredTables = ['products', 'orders', 'order_items', 'customers'];
      for (final table in requiredTables) {
        if (!importedCounts.containsKey(table) || importedCounts[table] == 0) {
          print('Verification failed: Table $table has no imported data');
          return false;
        }
      }

      // Kiểm tra mối quan hệ giữa orders và order_items
      final orderItemsCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM order_items WHERE order_id NOT IN (SELECT id FROM orders)',
      );
      final orphanedItems = Sqflite.firstIntValue(orderItemsCount) ?? 0;
      if (orphanedItems > 0) {
        print(
            'Verification failed: Found $orphanedItems order items without parent orders');
        return false;
      }

      // Kiểm tra mối quan hệ giữa orders và customers
      final ordersWithInvalidCustomers = await db.rawQuery(
        'SELECT COUNT(*) as count FROM orders WHERE customer_id IS NOT NULL AND customer_id NOT IN (SELECT id FROM customers)',
      );
      final invalidCustomerOrders =
          Sqflite.firstIntValue(ordersWithInvalidCustomers) ?? 0;
      if (invalidCustomerOrders > 0) {
        print(
            'Verification failed: Found $invalidCustomerOrders orders with invalid customer references');
        return false;
      }

      // Kiểm tra mối quan hệ giữa order_items và products
      final itemsWithInvalidProducts = await db.rawQuery(
        'SELECT COUNT(*) as count FROM order_items WHERE product_id IS NOT NULL AND product_id NOT IN (SELECT id FROM products)',
      );
      final invalidProductItems =
          Sqflite.firstIntValue(itemsWithInvalidProducts) ?? 0;
      if (invalidProductItems > 0) {
        print(
            'Verification failed: Found $invalidProductItems order items with invalid product references');
        // Đây không phải là lỗi nghiêm trọng vì có thể có các sản phẩm tạm thời
        print(
            'Warning: Some order items reference products that no longer exist');
      }

      return true;
    } catch (e) {
      print('Error during data integrity verification: $e');
      return false;
    }
  }

  Future<void> processSyncQueue() async {
    final db = await DatabaseHelper.instance.database;
    final pendingItems = await DatabaseHelper.instance.getPendingSyncItems();

    for (final item in pendingItems) {
      try {
        final data = jsonDecode(item['data'] as String) as Map<String, dynamic>;
        final tableName = item['table_name'] as String;
        final operation = item['operation'] as String;
        final recordId = item['record_id'] as int;

        switch (operation) {
          case 'insert':
            await db.insert(tableName, data);
            break;
          case 'update':
            await db.update(
              tableName,
              data,
              where: 'id = ?',
              whereArgs: [recordId],
            );
            break;
          case 'delete':
            await db.delete(
              tableName,
              where: 'id = ?',
              whereArgs: [recordId],
            );
            break;
        }

        await DatabaseHelper.instance.markSyncItemAsSynced(item['id'] as int);
      } catch (e) {
        print('Error processing sync item: $e');
        // TODO: Implement retry mechanism or error reporting
      }
    }
  }
}
