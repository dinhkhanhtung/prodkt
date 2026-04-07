import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart';
import '../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    try {
      _database = await _initDB(AppConstants.dbName);
      return _database!;
    } catch (e) {
      // Nếu có lỗi, thử xóa và tạo lại database
      try {
        await deleteDatabase();
        _database = await _initDB(AppConstants.dbName);
        return _database!;
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await sqflite.getDatabasesPath();
      final path = join(dbPath, filePath);

      final db = await sqflite.openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: (db, version) async {
          await _createDB(db, version);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Xử lý nâng cấp database ở đây
        },
        onOpen: (db) async {
          // Kiểm tra health check khi mở database
          final isHealthy = await _checkDatabaseHealth(db);
          if (!isHealthy) {
            throw Exception('Database health check failed');
          }
        },
      );

      return db;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> _checkDatabaseHealth(Database db) async {
    try {
      // Kiểm tra các bảng cần thiết
      final tables = [
        'settings',
        'customers',
        'products',
        'custom_fields',
        'product_attributes',
        'orders',
        'order_items',
        'expenses',
        'notifications',
      ];

      for (final table in tables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [table],
        );
        if (result.isEmpty) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteDatabase() async {
    try {
      final dbPath = await sqflite.getDatabasesPath();
      final path = join(dbPath, AppConstants.dbName);
      await sqflite.deleteDatabase(path);
      _database = null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const integerType = 'INTEGER';
    const realType = 'REAL';

    try {
      // Kiểm tra xem bảng đã tồn tại chưa trước khi tạo
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final existingTables = tables.map((t) => t['name'] as String).toList();

      // 1. Tạo bảng settings nếu chưa tồn tại
      if (!existingTables.contains('settings')) {
        await db.execute('''
CREATE TABLE settings (
  id $idType,
  key $textType NOT NULL,
  value $textType
)
''');

        // Thêm giá trị mặc định cho first_run
        await db.insert('settings', {'key': 'first_run', 'value': '1'});
      }

      // 2. Tạo bảng customers nếu chưa tồn tại
      if (!existingTables.contains('customers')) {
        await db.execute('''
CREATE TABLE customers (
  id $idType,
  name $textType NOT NULL,
  phone $textType,
  email $textType,
  address $textType,
  normalized_name $textType NOT NULL,
  debt $realType NOT NULL DEFAULT 0,
  created_at $textType NOT NULL DEFAULT CURRENT_TIMESTAMP
)
''');
      }

      // 3. Tạo bảng products nếu chưa tồn tại
      if (!existingTables.contains('products')) {
        await db.execute('''
CREATE TABLE products (
  id $idType,
  name $textType NOT NULL,
  normalized_name $textType NOT NULL,
  code $textType,
  quantity $integerType NOT NULL DEFAULT 0,
  sell_price $realType NOT NULL DEFAULT 0,
  cost_price $realType NOT NULL DEFAULT 0,
  image_path $textType,
  entry_date $textType NOT NULL,
  is_temporary $integerType NOT NULL DEFAULT 0,
  unit $textType DEFAULT 'cái',
  attributes $textType
)
''');
      }

      // 4. Tạo bảng custom_fields nếu chưa tồn tại
      if (!existingTables.contains('custom_fields')) {
        await db.execute('''
CREATE TABLE custom_fields (
  id $idType,
  name $textType NOT NULL,
  type $textType NOT NULL
)
''');
      }

      // 5. Tạo bảng product_attributes nếu chưa tồn tại
      if (!existingTables.contains('product_attributes')) {
        await db.execute('''
CREATE TABLE product_attributes (
  id $idType,
  product_id $integerType NOT NULL,
  field_id $integerType NOT NULL,
  value $textType NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
  FOREIGN KEY (field_id) REFERENCES custom_fields (id) ON DELETE CASCADE
)
''');
      }

      // 6. Tạo bảng orders nếu chưa tồn tại
      if (!existingTables.contains('orders')) {
        await db.execute('''
CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  customer_id INTEGER,
  total REAL NOT NULL,
  paid REAL NOT NULL,
  debt REAL NOT NULL,
  status TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'Bán lẻ',
  tax_percent REAL DEFAULT 0,
  discount_percent REAL DEFAULT 0,
  discount_amount REAL DEFAULT 0,
  shipping_fee REAL DEFAULT 0,
  additional_fee REAL DEFAULT 0,
  additional_fee_description TEXT,
  refund_amount REAL DEFAULT 0,
  refund_date TEXT,
  refund_reason TEXT,
  note TEXT,
  FOREIGN KEY (customer_id) REFERENCES customers (id)
)
''');
      }

      // 7. Tạo bảng order_items nếu chưa tồn tại
      if (!existingTables.contains('order_items')) {
        await db.execute('''
CREATE TABLE order_items (
  id $idType,
  order_id $integerType NOT NULL,
  product_id $integerType NOT NULL,
  quantity $integerType NOT NULL,
  price $realType NOT NULL,
  cost $realType NOT NULL DEFAULT 0,
  is_exchanged $integerType NOT NULL DEFAULT 0,
  FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products (id)
)
''');
      }

      // 8. Tạo bảng expenses nếu chưa tồn tại
      if (!existingTables.contains('expenses')) {
        await db.execute('''
CREATE TABLE expenses (
  id $idType,
  date $textType NOT NULL,
  amount $realType NOT NULL DEFAULT 0,
  category $textType NOT NULL,
  description $textType
)
''');
      }

      // 9. Tạo bảng notifications nếu chưa tồn tại
      if (!existingTables.contains('notifications')) {
        await db.execute('''
CREATE TABLE notifications (
  id $idType,
  title $textType NOT NULL,
  message $textType NOT NULL,
  date $textType NOT NULL,
  type $textType NOT NULL,
  is_read $integerType NOT NULL DEFAULT 0
)
''');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Kiểm tra xem có phải lần đầu chạy ứng dụng không
  Future<bool> isFirstRun() async {
    try {
      final db = await database;
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['first_run'],
      );

      if (result.isEmpty) {
        return true;
      }

      return result.first['value'] == '1';
    } catch (e) {
      return true;
    }
  }

  // Đánh dấu đã hoàn thành lần chạy đầu tiên
  Future<void> setFirstRunCompleted() async {
    try {
      final db = await database;
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['first_run'],
      );

      if (result.isEmpty) {
        await db.insert('settings', {'key': 'first_run', 'value': '0'});
      } else {
        await db.update(
          'settings',
          {'value': '0'},
          where: 'key = ?',
          whereArgs: ['first_run'],
        );
      }
    } catch (e) {
      // Ignore error
    }
  }
}
