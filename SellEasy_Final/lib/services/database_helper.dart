import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    try {
      print('Initializing database...');
      _database = await _initDB('selleasy.db');
      print('Database initialized successfully');
      return _database!;
    } catch (e) {
      print('Error initializing database: $e');
      // Nếu có lỗi, thử xóa và tạo lại database
      try {
        print('Attempting to recreate database...');
        await deleteDatabase();
        _database = await _initDB('selleasy.db');
        print('Database recreated successfully');
        return _database!;
      } catch (e) {
        print('Failed to recreate database: $e');
        rethrow;
      }
    }
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      print('Database path: $path');

      final db = await openDatabase(
        path,
        version: 13,
        onCreate: (db, version) async {
          print('Creating new database...');
          await _createDB(db, version);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          print('Upgrading database from $oldVersion to $newVersion');

          if (oldVersion < 13) {
            try {
              // Check if additional_fee columns exist before adding them
              final columns = await db.rawQuery("PRAGMA table_info('orders')");
              bool hasAdditionalFee = columns.any(
                (col) => col['name'] == 'additional_fee',
              );
              bool hasAdditionalFeeDescription = columns.any(
                (col) => col['name'] == 'additional_fee_description',
              );

              // Add missing additional_fee columns
              if (!hasAdditionalFee) {
                print('Adding additional_fee column...');
                await db.execute(
                  "ALTER TABLE orders ADD COLUMN additional_fee REAL DEFAULT 0",
                );
              }
              if (!hasAdditionalFeeDescription) {
                print('Adding additional_fee_description column...');
                await db.execute(
                  "ALTER TABLE orders ADD COLUMN additional_fee_description TEXT",
                );
              }
              print('Added additional_fee columns successfully');
            } catch (e) {
              print('Error during upgrade: $e');
              rethrow;
            }
          }

          if (oldVersion < 12) {
            await updateExistingCustomersCreatedAt();
          }

          if (oldVersion < 4) {
            try {
              final tables = await db.rawQuery(
                "SELECT name FROM sqlite_master WHERE type='table'",
              );

              if (tables.any((t) => t['name'] == 'orders')) {
                final columns = await db.rawQuery(
                  "PRAGMA table_info('orders')",
                );
                bool hasShippingFee = columns.any(
                  (col) => col['name'] == 'shipping_fee',
                );

                if (!hasShippingFee) {
                  print('Adding shipping_fee column...');
                  await db.execute(
                    "ALTER TABLE orders ADD COLUMN shipping_fee REAL DEFAULT 0",
                  );
                  print('Added shipping_fee column successfully');
                }
              }
            } catch (e) {
              print('Error during upgrade: $e');
              rethrow;
            }
          }

          if (oldVersion < 5) {
            try {
              final tables = await db.rawQuery(
                "SELECT name FROM sqlite_master WHERE type='table'",
              );

              if (!tables.any((t) => t['name'] == 'expenses')) {
                await db.execute('''
                  CREATE TABLE expenses (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    date TEXT NOT NULL,
                    amount REAL NOT NULL DEFAULT 0,
                    category TEXT NOT NULL,
                    description TEXT
                  )
                ''');
              }
            } catch (e) {
              print('Error during upgrade: $e');
              rethrow;
            }
          }

          if (oldVersion < 6) {
            try {
              // Check if refund columns exist before adding them
              final columns = await db.rawQuery("PRAGMA table_info('orders')");
              bool hasRefundAmount = columns.any(
                (col) => col['name'] == 'refund_amount',
              );
              bool hasRefundDate = columns.any(
                (col) => col['name'] == 'refund_date',
              );
              bool hasRefundReason = columns.any(
                (col) => col['name'] == 'refund_reason',
              );

              // Add missing refund columns
              if (!hasRefundAmount) {
                print('Adding refund_amount column...');
                await db.execute(
                  "ALTER TABLE orders ADD COLUMN refund_amount REAL DEFAULT 0",
                );
              }
              if (!hasRefundDate) {
                print('Adding refund_date column...');
                await db.execute(
                  "ALTER TABLE orders ADD COLUMN refund_date TEXT",
                );
              }
              if (!hasRefundReason) {
                print('Adding refund_reason column...');
                await db.execute(
                  "ALTER TABLE orders ADD COLUMN refund_reason TEXT",
                );
              }
              print('Added refund columns successfully');
            } catch (e) {
              print('Error during upgrade: $e');
              rethrow;
            }
          }

          if (oldVersion < 7) {
            try {
              // Check if unit column exists before adding it
              final columns =
                  await db.rawQuery("PRAGMA table_info('products')");
              bool hasUnit = columns.any(
                (col) => col['name'] == 'unit',
              );

              if (!hasUnit) {
                print('Adding unit column to products table...');
                await db.execute(
                  "ALTER TABLE products ADD COLUMN unit TEXT DEFAULT 'cái'",
                );
                print('Added unit column successfully');
              }
            } catch (e) {
              print('Error during upgrade: $e');
              rethrow;
            }
          }

          if (oldVersion < 8) {
            try {
              // Check if is_exchanged column exists before adding it
              final columns =
                  await db.rawQuery("PRAGMA table_info('order_items')");
              bool hasIsExchanged = columns.any(
                (col) => col['name'] == 'is_exchanged',
              );

              if (!hasIsExchanged) {
                print('Adding is_exchanged column to order_items table...');
                await db.execute(
                  "ALTER TABLE order_items ADD COLUMN is_exchanged INTEGER NOT NULL DEFAULT 0",
                );
                print('Added is_exchanged column successfully');
              }
            } catch (e) {
              print('Error during upgrade: $e');
              rethrow;
            }
          }

          if (oldVersion < 9) {
            try {
              // Check if attributes column exists
              final columns =
                  await db.rawQuery("PRAGMA table_info('products')");
              bool hasAttributes =
                  columns.any((col) => col['name'] == 'attributes');

              if (!hasAttributes) {
                print('Adding attributes column to products table...');
                await db
                    .execute("ALTER TABLE products ADD COLUMN attributes TEXT");
                print('Added attributes column successfully');
              }
            } catch (e) {
              print('Error during upgrade: $e');
              rethrow;
            }
          }
        },
        onOpen: (db) async {
          print('Database opened successfully');
          // Kiểm tra health check khi mở database
          final isHealthy = await _checkDatabaseHealth(db);
          print('Database health check: ${isHealthy ? 'OK' : 'Failed'}');
          if (!isHealthy) {
            throw Exception('Database health check failed');
          }
        },
      );

      return db;
    } catch (e) {
      print('Error in _initDB: $e');
      rethrow;
    }
  }

  Future<bool> _checkDatabaseHealth(Database db) async {
    try {
      print('Checking database health...');

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
          print('Missing table: $table');
          return false;
        }
      }

      // Kiểm tra cấu trúc bảng orders
      final orderColumns = await db.rawQuery("PRAGMA table_info('orders')");
      final requiredColumns = [
        'id',
        'date',
        'customer_id',
        'total',
        'paid',
        'debt',
        'status',
        'category',
        'tax_percent',
        'discount_amount',
        'shipping_fee',
        'additional_fee',
        'additional_fee_description',
      ];

      for (final column in requiredColumns) {
        if (!orderColumns.any((col) => col['name'] == column)) {
          print('Missing column in orders table: $column');
          return false;
        }
      }

      print('Database health check passed');
      return true;
    } catch (e) {
      print('Database health check failed: $e');
      return false;
    }
  }

  Future<void> deleteDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'selleasy.db');
      print('Deleting database at path: $path');
      await databaseFactory.deleteDatabase(path);
      _database = null;
      print('Database deleted successfully');
    } catch (e) {
      print('Error deleting database: $e');
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const integerType = 'INTEGER';
    const realType = 'REAL';

    try {
      print('Starting database creation...');
      // Kiểm tra xem bảng đã tồn tại chưa trước khi tạo
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final existingTables = tables.map((t) => t['name'] as String).toList();
      print('Existing tables: $existingTables');

      // 1. Tạo bảng settings nếu chưa tồn tại
      if (!existingTables.contains('settings')) {
        print('Creating settings table...');
        await db.execute('''
CREATE TABLE settings (
  id $idType,
  key $textType NOT NULL,
  value $textType
)
''');
        print('Settings table created successfully');

        // Thêm giá trị mặc định cho first_run
        await db.insert('settings', {'key': 'first_run', 'value': '1'});
      }

      // Thêm bảng purchase_orders nếu chưa tồn tại
      if (!existingTables.contains('purchase_orders')) {
        print('Creating purchase_orders table...');
        await db.execute('''
CREATE TABLE purchase_orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  supplier_name TEXT,
  supplier_phone TEXT,
  date TEXT NOT NULL,
  product_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  cost REAL NOT NULL,
  note TEXT,
  FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
)
''');
        print('purchase_orders table created successfully');
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
      } else {
        // Check if email column exists
        final columns = await db.rawQuery("PRAGMA table_info('customers')");
        bool hasEmail = columns.any((col) => col['name'] == 'email');
        bool hasAddress = columns.any((col) => col['name'] == 'address');
        bool hasNormalizedName =
            columns.any((col) => col['name'] == 'normalized_name');

        if (!hasEmail) {
          await db.execute("ALTER TABLE customers ADD COLUMN email TEXT");
        }
        if (!hasAddress) {
          await db.execute("ALTER TABLE customers ADD COLUMN address TEXT");
        }
        if (!hasNormalizedName) {
          await db.execute(
              "ALTER TABLE customers ADD COLUMN normalized_name TEXT NOT NULL DEFAULT ''");
        }
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
      } else {
        // Kiểm tra và thêm cột attributes nếu chưa có
        final columns = await db.rawQuery("PRAGMA table_info('products')");
        bool hasAttributes = columns.any((col) => col['name'] == 'attributes');

        if (!hasAttributes) {
          print('Adding attributes column to products table...');
          await db.execute("ALTER TABLE products ADD COLUMN attributes TEXT");
          print('Added attributes column successfully');
        }
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
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  product_id INTEGER,
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  price REAL NOT NULL,
  cost_price REAL NOT NULL DEFAULT 0,
  original_price REAL,
  exchange_count INTEGER DEFAULT 0,
  attributes TEXT,
  is_temporary INTEGER NOT NULL DEFAULT 0,
  is_exchanged INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (order_id) REFERENCES orders (id),
  FOREIGN KEY (product_id) REFERENCES products (id)
)
''');
      } else {
        // Kiểm tra các cột cần thiết
        final columns = await db.rawQuery("PRAGMA table_info('order_items')");
        bool hasOriginalPrice =
            columns.any((col) => col['name'] == 'original_price');
        bool hasExchangeCount =
            columns.any((col) => col['name'] == 'exchange_count');
        bool hasCostPrice = columns.any((col) => col['name'] == 'cost_price');
        bool hasIsExchanged =
            columns.any((col) => col['name'] == 'is_exchanged');

        if (!hasOriginalPrice) {
          await db.execute(
            "ALTER TABLE order_items ADD COLUMN original_price REAL",
          );
        }

        if (!hasExchangeCount) {
          await db.execute(
            "ALTER TABLE order_items ADD COLUMN exchange_count INTEGER DEFAULT 0",
          );
        }

        if (!hasCostPrice) {
          await db.execute(
            "ALTER TABLE order_items ADD COLUMN cost_price REAL NOT NULL DEFAULT 0",
          );
        }

        if (!hasIsExchanged) {
          await db.execute(
            "ALTER TABLE order_items ADD COLUMN is_exchanged INTEGER NOT NULL DEFAULT 0",
          );
        }
      }

      // 8. Tạo bảng expenses nếu chưa tồn tại
      if (!existingTables.contains('expenses')) {
        await db.execute('''
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  amount REAL NOT NULL DEFAULT 0,
  category TEXT NOT NULL,
  description TEXT,
  product_id INTEGER,
  quantity INTEGER,
  warehouse_id INTEGER,
  FOREIGN KEY (product_id) REFERENCES products (id),
  FOREIGN KEY (warehouse_id) REFERENCES warehouses (id)
)
''');
      } else {
        // Kiểm tra và thêm các cột còn thiếu
        final columns = await db.rawQuery("PRAGMA table_info('expenses')");

        bool hasProductId = columns.any((col) => col['name'] == 'product_id');
        bool hasQuantity = columns.any((col) => col['name'] == 'quantity');
        bool hasWarehouseId = columns.any(
          (col) => col['name'] == 'warehouse_id',
        );

        if (!hasProductId) {
          print('Adding product_id column to expenses table...');
          await db.execute(
            "ALTER TABLE expenses ADD COLUMN product_id INTEGER REFERENCES products (id)",
          );
          print('Added product_id column successfully');
        }

        if (!hasQuantity) {
          print('Adding quantity column to expenses table...');
          await db.execute("ALTER TABLE expenses ADD COLUMN quantity INTEGER");
          print('Added quantity column successfully');
        }

        if (!hasWarehouseId) {
          print('Adding warehouse_id column to expenses table...');
          await db.execute(
            "ALTER TABLE expenses ADD COLUMN warehouse_id INTEGER REFERENCES warehouses (id)",
          );
          print('Added warehouse_id column successfully');
        }
      }

      // 9. Tạo bảng users nếu chưa tồn tại
      if (!existingTables.contains('users')) {
        print('Creating users table...');
        await db.execute('''
CREATE TABLE users (
  id $idType,
  username $textType NOT NULL UNIQUE,
  password $textType NOT NULL,
  name $textType,
  role $textType NOT NULL DEFAULT 'user',
  created_at $textType NOT NULL DEFAULT CURRENT_TIMESTAMP
)
''');
        print('Users table created, creating default admin user...');
        // Tạo tài khoản admin mặc định
        await db.insert('users', {
          'username': 'admin',
          'password': 'admin123',
          'name': 'Administrator',
          'role': 'admin',
        });
        print('Default admin user created successfully');
      }

      // 10. Tạo bảng sync_queue nếu chưa tồn tại
      if (!existingTables.contains('sync_queue')) {
        await db.execute('''
CREATE TABLE sync_queue (
  id $idType,
  table_name $textType NOT NULL,
  operation $textType NOT NULL,
  record_id $integerType NOT NULL,
  data $textType NOT NULL,
  synced $integerType NOT NULL DEFAULT 0,
  created_at $textType NOT NULL DEFAULT CURRENT_TIMESTAMP
)
''');
      }

      // 11. Tạo bảng notifications nếu chưa tồn tại
      if (!existingTables.contains('notifications')) {
        print('Creating notifications table...');
        await db.execute('''
CREATE TABLE notifications (
  id $idType,
  title $textType NOT NULL,
  message $textType NOT NULL,
  type $textType NOT NULL,
  is_read $integerType NOT NULL DEFAULT 0,
  related_id $integerType,
  created_at $textType NOT NULL DEFAULT CURRENT_TIMESTAMP
)
''');
        print('Notifications table created successfully');
      }

      print('Database created/updated successfully');
    } catch (e) {
      print('Error creating/updating database: $e');
      rethrow;
    }
  }

  // Settings methods
  Future<bool> isFirstRun() async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['first_run'],
    );
    return result.isEmpty || result.first['value'] == '1';
  }

  Future<void> setFirstRun(bool value) async {
    final db = await database;
    // Kiểm tra xem key đã tồn tại chưa
    final existing = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['first_run'],
    );

    if (existing.isEmpty) {
      // Nếu chưa tồn tại, thêm mới
      await db.insert('settings', {
        'key': 'first_run',
        'value': value ? '1' : '0',
      });
    } else {
      // Nếu đã tồn tại, cập nhật
      await db.update(
        'settings',
        {'value': value ? '1' : '0'},
        where: 'key = ?',
        whereArgs: ['first_run'],
      );
    }
  }

  Future<void> setIndustry(String industry) async {
    final db = await database;
    // Kiểm tra xem key đã tồn tại chưa
    final existing = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['industry'],
    );

    if (existing.isEmpty) {
      // Nếu chưa tồn tại, thêm mới
      await db.insert('settings', {'key': 'industry', 'value': industry});
    } else {
      // Nếu đã tồn tại, cập nhật
      await db.update(
        'settings',
        {'value': industry},
        where: 'key = ?',
        whereArgs: ['industry'],
      );
    }
  }

  Future<String?> getIndustry() async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['industry'],
    );
    return result.isEmpty ? null : result.first['value'] as String?;
  }

  // Product methods
  Future<List<Map<String, dynamic>>> getProducts({
    String? searchQuery,
    String? filterField,
    String? filterValue,
    int? warehouseId,
  }) async {
    final db = await database;
    try {
      List<String> conditions = [];
      List<dynamic> args = [];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        conditions.add('normalized_name LIKE ?');
        args.add('%${searchQuery.toLowerCase()}%');
      }

      if (filterField != null && filterValue != null) {
        conditions.add('''
          EXISTS (
            SELECT 1 FROM product_attributes pa
            JOIN custom_fields cf ON pa.field_id = cf.id
            WHERE pa.product_id = products.id
            AND cf.name = ?
            AND pa.value = ?
          )
        ''');
        args.addAll([filterField, filterValue]);
      }

      if (warehouseId != null) {
        conditions.add('warehouse_id = ?');
        args.add(warehouseId);
      }

      String whereClause = conditions.isEmpty ? '' : conditions.join(' AND ');

      final results = await db.query(
        'products',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'name ASC',
      );

      // Chuyển đổi attributes từ JSON string sang Map
      return results.map((product) {
        if (product['attributes'] != null) {
          try {
            final attributesJson = product['attributes'] as String;
            final attributesMap = json.decode(attributesJson);
            return {...product, 'attributes': attributesMap};
          } catch (e) {
            print('Error parsing attributes JSON: $e');
            return {...product, 'attributes': null};
          }
        }
        return product;
      }).toList();
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getProduct(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.first;
  }

  Future<int> insertProduct(
    Map<String, dynamic> product, {
    Map<String, String>? attributes,
    String? supplierName,
    String? supplierPhone,
    String? note,
  }) async {
    final db = await database;
    int productId = 0;

    await db.transaction((txn) async {
      // Insert product
      productId = await txn.insert(
        'products',
        {
          ...product,
          'attributes': attributes != null ? json.encode(attributes) : null,
        },
      );

      // If supplier info is provided, create a purchase order
      if (supplierName != null || supplierPhone != null) {
        await txn.insert('purchase_orders', {
          'product_id': productId,
          'date': DateTime.now().toIso8601String(),
          'quantity': product['quantity'] ?? 0,
          'cost': product['cost_price'] ?? 0,
          'supplier_name': supplierName,
          'supplier_phone': supplierPhone,
          'note': note,
        });
      }
    });

    return productId;
  }

  Future<void> updateProduct(
    int id,
    Map<String, dynamic> product, {
    Map<String, String>? attributes,
    String? supplierName,
    String? supplierPhone,
    String? note,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      // Update product
      await txn.update(
        'products',
        {
          ...product,
          'attributes': attributes != null ? json.encode(attributes) : null,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // If supplier info is provided, create a purchase order
      if (supplierName != null || supplierPhone != null) {
        await txn.insert('purchase_orders', {
          'product_id': id,
          'date': DateTime.now().toIso8601String(),
          'quantity': product['quantity'] ?? 0,
          'cost': product['cost_price'] ?? 0,
          'supplier_name': supplierName,
          'supplier_phone': supplierPhone,
          'note': note,
        });
      }
    });
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateProductQuantity(int id, int quantity) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE products SET quantity = quantity + ? WHERE id = ?',
      [quantity, id],
    );
  }

  // Customer methods
  Future<int> updateCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer,
      where: 'id = ?',
      whereArgs: [customer['id']],
    );
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;
    try {
      return await db.query('customers', orderBy: 'created_at DESC');
    } catch (e) {
      print('Error getting customers: $e');
      return [];
    }
  }

  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    return await db.insert('customers', {
      ...customer,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getCustomer(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  // Expense methods
  Future<List<Map<String, dynamic>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final db = await database;
    List<String> conditions = [];
    List<dynamic> args = [];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.toIso8601String());
    }

    if (category != null && category != 'all') {
      conditions.add('category = ?');
      args.add(category);
    }

    String whereClause = conditions.isEmpty ? '' : conditions.join(' AND ');

    try {
      return await db.query(
        'expenses',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'date DESC',
      );
    } catch (e) {
      print('Error getting expenses: $e');
      return [];
    }
  }

  Future<int> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    return await db.insert('expenses', expense);
  }

  Future<void> updateExpense(int id, Map<String, dynamic> expense) async {
    final db = await database;
    await db.update(
      'expenses',
      expense,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteExpenseByDescription(String description) async {
    final db = await database;
    await db
        .delete('expenses', where: 'description = ?', whereArgs: [description]);
  }

  // Custom fields methods
  Future<List<Map<String, dynamic>>> getCustomFields() async {
    final db = await database;
    try {
      return await db.query('custom_fields', orderBy: 'name ASC');
    } catch (e) {
      print('Error getting custom fields: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProductAttributes(int productId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT cf.name, cf.type, pa.value
      FROM product_attributes pa
      JOIN custom_fields cf ON pa.field_id = cf.id
      WHERE pa.product_id = ?
    ''',
      [productId],
    );
  }

  Future<void> insertProductAttribute(Map<String, dynamic> attribute) async {
    final db = await database;
    await db.insert('product_attributes', attribute);
  }

  Future<int> insertCustomField(Map<String, dynamic> field) async {
    final db = await database;
    return await db.insert('custom_fields', field);
  }

  Future<void> updateCustomField(int id, Map<String, dynamic> field) async {
    final db = await database;
    await db.update('custom_fields', field, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCustomField(int id) async {
    final db = await database;
    await db.delete('custom_fields', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCustomer(int id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Order methods
  Future<List<Map<String, dynamic>>> getOrders({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    int? customerId,
  }) async {
    final db = await database;

    // Ensure orders table exists with category column
    await _createOrdersTableIfNotExists();

    List<String> conditions = [];
    List<dynamic> args = [];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.toIso8601String());
    }

    if (category != null && category.toLowerCase() != 'all') {
      conditions.add('category = ?');
      args.add(category);
    }

    if (customerId != null) {
      conditions.add('customer_id = ?');
      args.add(customerId);
    }

    String whereClause = conditions.isEmpty ? '' : conditions.join(' AND ');

    try {
      print('Executing orders query:');
      print('Where clause: $whereClause');
      print('Arguments: $args');

      // Sửa lại query để tính tổng giá trị chính xác
      final results = await db.rawQuery('''
        SELECT
          o.*,
          CASE
            WHEN o.refund_amount > 0 THEN o.total - o.refund_amount  -- Nếu có hoàn tiền thì tổng = tổng ban đầu - số tiền hoàn
            ELSE o.total  -- Ngược lại giữ nguyên tổng
          END as display_total
        FROM orders o
        WHERE ${whereClause.isEmpty ? '1=1' : whereClause}
        ORDER BY date DESC
      ''', args);

      print('Query results count: ${results.length}');
      if (results.isNotEmpty) {
        print('Sample result: ${results.first}');
      }

      // Chuyển display_total thành total để hiển thị
      return results.map((order) {
        return {
          ...order,
          'total': order['display_total'],
        };
      }).toList();
    } catch (e) {
      print('Error getting orders: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  Future<Map<String, dynamic>> getOrder(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.first;
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final db = await database;
    return await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> _createOrdersTableIfNotExists() async {
    final db = await database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='orders'",
    );

    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER,
          date TEXT NOT NULL,
          status TEXT NOT NULL,
          total REAL NOT NULL,
          paid REAL NOT NULL,
          debt REAL NOT NULL,
          shipping_fee REAL NOT NULL DEFAULT 0,
          additional_fee REAL DEFAULT 0,
          additional_fee_description TEXT,
          discount_amount REAL NOT NULL DEFAULT 0,
          tax_percent REAL NOT NULL DEFAULT 0,
          note TEXT,
          category TEXT NOT NULL DEFAULT 'Bán lẻ',
          revenue REAL,
          profit REAL,
          is_exchanged INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL
        )
      ''');
    } else {
      // Kiểm tra và thêm cột nếu chưa có
      final columns = await db.rawQuery("PRAGMA table_info('orders')");

      bool hasRevenue = columns.any((col) => col['name'] == 'revenue');
      bool hasProfit = columns.any((col) => col['name'] == 'profit');
      bool hasAdditionalFee =
          columns.any((col) => col['name'] == 'additional_fee');
      bool hasAdditionalFeeDescription =
          columns.any((col) => col['name'] == 'additional_fee_description');
      bool hasIsExchanged = columns.any((col) => col['name'] == 'is_exchanged');

      if (!hasRevenue) {
        await db.execute("ALTER TABLE orders ADD COLUMN revenue REAL");
      }
      if (!hasProfit) {
        await db.execute("ALTER TABLE orders ADD COLUMN profit REAL");
      }
      if (!hasAdditionalFee) {
        await db.execute(
            "ALTER TABLE orders ADD COLUMN additional_fee REAL DEFAULT 0");
      }
      if (!hasAdditionalFeeDescription) {
        await db.execute(
            "ALTER TABLE orders ADD COLUMN additional_fee_description TEXT");
      }
      if (!hasIsExchanged) {
        await db.execute(
            "ALTER TABLE orders ADD COLUMN is_exchanged INTEGER NOT NULL DEFAULT 0");
      }
    }
  }

  Future<int> insertOrder(Map<String, dynamic> order) async {
    try {
      await _createOrdersTableIfNotExists();
      final db = await database;
      print('Inserting order: $order');
      final id = await db.insert('orders', order);
      print('Order inserted with ID: $id');
      return id;
    } catch (e) {
      print('Error inserting order: $e');
      rethrow;
    }
  }

  Future<void> insertOrderItem(Map<String, dynamic> item) async {
    try {
      final db = await database;
      print('Inserting order item: $item');
      await db.insert('order_items', item);
      print('Order item inserted successfully');
    } catch (e) {
      print('Error inserting order item: $e');
      rethrow;
    }
  }

  Future<void> updateOrder(int id, Map<String, dynamic> order) async {
    final db = await database;
    try {
      // Check if refund columns exist before updating
      final columns = await db.rawQuery("PRAGMA table_info('orders')");
      bool hasRefundColumns =
          columns.any((col) => col['name'] == 'refund_amount') &&
              columns.any((col) => col['name'] == 'refund_date') &&
              columns.any((col) => col['name'] == 'refund_reason');

      if (!hasRefundColumns) {
        // If refund columns don't exist, remove refund-related fields from the update
        order.remove('refund_amount');
        order.remove('refund_date');
        order.remove('refund_reason');
        print(
          'Warning: Refund columns do not exist. Skipping refund data update.',
        );
      } else if (order['status'] == 'Đã hoàn tiền') {
        // Get order items to update inventory
        final orderItems = await getOrderItems(id);

        // Update inventory for each item
        for (var item in orderItems) {
          if (item['product_id'] != null) {
            // Increase product quantity back to inventory
            await db.rawUpdate(
              'UPDATE products SET quantity = quantity + ? WHERE id = ?',
              [item['quantity'], item['product_id']],
            );
            print(
              'Updated inventory for product ${item['product_id']}: +${item['quantity']}',
            );
          }
        }

        // Reset financial values when order is cancelled
        order['total'] = 0;
        order['paid'] = 0;
        order['debt'] = 0;
        order['revenue'] = 0;
        order['profit'] = 0;
      }

      await db.update('orders', order, where: 'id = ?', whereArgs: [id]);
      print('Order updated successfully');
    } catch (e) {
      print('Error updating order: $e');
      rethrow;
    }
  }

  Future<void> deleteOrder(int orderId) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        // Get order details before deletion
        final order = await txn.query(
          'orders',
          where: 'id = ?',
          whereArgs: [orderId],
        );
        if (order.isEmpty) throw Exception('Order not found');

        // Delete shipping fee expense if exists
        final shippingFee =
            (order[0]['shipping_fee'] as num?)?.toDouble() ?? 0.0;
        if (shippingFee > 0) {
          await txn.delete(
            'expenses',
            where: 'description = ?',
            whereArgs: ['Phí vận chuyển đơn hàng #$orderId'],
          );
        }

        // Delete additional fee expense if exists
        final additionalFee =
            (order[0]['additional_fee'] as num?)?.toDouble() ?? 0.0;
        final additionalFeeDescription =
            order[0]['additional_fee_description'] as String? ?? 'Chi phí khác';
        if (additionalFee > 0) {
          await txn.delete(
            'expenses',
            where: 'description = ?',
            whereArgs: ['$additionalFeeDescription - đơn hàng #$orderId'],
          );
        }

        // Delete order items
        await txn.delete(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [orderId],
        );

        // Delete order
        await txn.delete(
          'orders',
          where: 'id = ?',
          whereArgs: [orderId],
        );
      });
    } catch (e) {
      print('Error deleting order: $e');
      rethrow;
    }
  }

  Future<void> deleteOrderItem(int id) async {
    final db = await database;
    await db.delete('order_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateOrderStatus(int id, String status) async {
    final db = await database;
    await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateCustomerDebt(int customerId, double amount) async {
    final db = await database;
    await db.rawUpdate('UPDATE customers SET debt = debt + ? WHERE id = ?', [
      amount,
      customerId,
    ]);
  }

  // Report methods
  Future<Map<String, dynamic>> getReportSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? expenseCategory,
    String? orderCategory,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause = 'o.date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += whereClause.isEmpty ? 'o.date <= ?' : ' AND o.date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (orderCategory != null && orderCategory.toLowerCase() != 'all') {
      whereClause +=
          whereClause.isEmpty ? 'o.category = ?' : ' AND o.category = ?';
      whereArgs.add(orderCategory);
    }

    // Tính tổng doanh thu, giá vốn và hoàn tiền
    final List<Map<String, dynamic>> revenueMaps = await db.rawQuery('''
      WITH OrderTotals AS (
        SELECT
          o.id,
          o.total,
          o.paid,
          o.shipping_fee,
          o.discount_amount,
          o.refund_amount,
          o.status,
          o.category,
          CASE
            WHEN o.total > 0 THEN o.paid / o.total  -- Tỷ lệ thanh toán
            ELSE 0
          END as payment_ratio,
          SUM(oi.quantity * oi.cost_price) as order_cost
        FROM orders o
        LEFT JOIN order_items oi ON o.id = oi.order_id
        WHERE o.status NOT IN ('Đã hoàn tiền', 'Nháp')
        ${whereClause.isEmpty ? '' : 'AND $whereClause'}
        GROUP BY o.id
      )
      SELECT
        SUM(CASE
          WHEN refund_amount > 0 THEN paid - refund_amount  -- Nếu có hoàn tiền thì doanh thu = số tiền đã trả - số tiền hoàn
          ELSE paid  -- Doanh thu chỉ tính theo số tiền đã thanh toán
        END) as total_revenue,
        SUM(shipping_fee * payment_ratio) as total_shipping,  -- Phí ship tính theo tỷ lệ thanh toán
        SUM(discount_amount) as total_discount,
        SUM(CASE WHEN status = 'Đã hoàn tiền' THEN refund_amount ELSE 0 END) as total_refunds,
        SUM(order_cost * payment_ratio) as total_cost  -- Giá vốn tính theo tỷ lệ thanh toán
      FROM OrderTotals
    ''', whereArgs);

    // Tính tổng chi phí
    String expenseWhereClause = whereClause.replaceAll('o.', '');
    List<dynamic> expenseWhereArgs = List.from(whereArgs);
    if (expenseCategory != null && expenseCategory.toLowerCase() != 'all') {
      expenseWhereClause +=
          expenseWhereClause.isEmpty ? 'category = ?' : ' AND category = ?';
      expenseWhereArgs.add(expenseCategory);
    }

    final List<Map<String, dynamic>> expenseMaps = await db.query(
      'expenses',
      columns: ['SUM(amount) as total'],
      where: expenseWhereClause.isEmpty ? null : expenseWhereClause,
      whereArgs: expenseWhereArgs.isEmpty ? null : expenseWhereArgs,
    );

    // Tính tổng công nợ từ đơn hàng chưa hoàn tiền
    final List<Map<String, dynamic>> debtMaps = await db.rawQuery('''
      SELECT SUM(debt) as total
      FROM orders o
      WHERE status NOT IN ('Đã hoàn tiền', 'Nháp')
      ${whereClause.isEmpty ? '' : 'AND $whereClause'}
    ''', whereArgs);

    final double totalRevenue =
        (revenueMaps.first['total_revenue'] as num?)?.toDouble() ?? 0;
    final double totalShipping =
        (revenueMaps.first['total_shipping'] as num?)?.toDouble() ?? 0;
    final double totalDiscount =
        (revenueMaps.first['total_discount'] as num?)?.toDouble() ?? 0;
    final double totalRefunds =
        (revenueMaps.first['total_refunds'] as num?)?.toDouble() ?? 0;
    final double totalCost =
        (revenueMaps.first['total_cost'] as num?)?.toDouble() ?? 0;
    final double totalExpenses =
        (expenseMaps.first['total'] as num?)?.toDouble() ?? 0;
    final double totalDebt = (debtMaps.first['total'] as num?)?.toDouble() ?? 0;

    // Tính lợi nhuận = (Doanh thu thực tế - Chiết khấu theo tỷ lệ + Phí ship theo tỷ lệ) - Chi phí - Giá vốn theo tỷ lệ
    // Lưu ý: Hoàn tiền đã được trừ trong doanh thu nên không cần trừ lại
    final double netProfit = (totalRevenue - totalDiscount + totalShipping) -
        totalExpenses -
        totalCost;

    return {
      'total_revenue': totalRevenue,
      'total_shipping': totalShipping,
      'total_discount': totalDiscount,
      'total_refunds': totalRefunds,
      'total_cost': totalCost,
      'total_expenses': totalExpenses,
      'total_debt': totalDebt,
      'net_profit': netProfit,
    };
  }

  // User methods
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<Map<String, dynamic>?> getUser(
    String username,
    String password,
  ) async {
    final db = await database;
    print('Attempting to login with username: $username');

    try {
      // Kiểm tra xem user có tồn tại không
      final userExists = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      print('User exists check: ${userExists.isNotEmpty}');

      if (userExists.isEmpty) {
        print('User not found: $username');
        return null;
      }

      // Kiểm tra password
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );

      print('Password check result: ${maps.isNotEmpty}');

      if (maps.isNotEmpty) {
        print('Login successful for user: $username');
        return maps.first;
      } else {
        print('Invalid password for user: $username');
        return null;
      }
    } catch (e) {
      print('Error during login: $e');
      rethrow;
    }
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [user['id']],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // Sync queue methods
  Future<int> addToSyncQueue(
    String tableName,
    String operation,
    int recordId,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    return await db.insert('sync_queue', {
      'table_name': tableName,
      'operation': operation,
      'record_id': recordId,
      'data': jsonEncode(data),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markSyncItemAsSynced(int id) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // Warehouse methods
  Future<List<Map<String, dynamic>>> getWarehouses() async {
    final db = await database;
    return await db.query('warehouses');
  }

  Future<Map<String, dynamic>> getWarehouse(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'warehouses',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.first;
  }

  Future<int> insertWarehouse(Map<String, dynamic> warehouse) async {
    final db = await database;
    return await db.insert('warehouses', warehouse);
  }

  Future<int> updateWarehouse(Map<String, dynamic> warehouse) async {
    final db = await database;
    return await db.update(
      'warehouses',
      warehouse,
      where: 'id = ?',
      whereArgs: [warehouse['id']],
    );
  }

  Future<int> deleteWarehouse(int id) async {
    final db = await database;
    return await db.delete('warehouses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getProductOrderHistory(
    int productId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT oi.*, o.date
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE oi.product_id = ?
      ORDER BY o.date DESC
    ''',
      [productId],
    );
  }

  Future<List<Map<String, dynamic>>> getProductExpenseHistory(
    int productId,
  ) async {
    final db = await database;
    return await db.query(
      'expenses',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'date DESC',
    );
  }

  Future<void> resetDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'selleasy.db');
      print('Resetting database at path: $path');

      // Xóa database cũ
      await deleteDatabase();

      // Khởi tạo database mới
      _database = null;
      await database;

      print('Database reset successfully');
    } catch (e) {
      print('Error resetting database: $e');
      rethrow;
    }
  }

  Future<void> logDatabaseError(String operation, dynamic error) async {
    print('Database error during $operation: $error');
    // You can add more error logging logic here
  }

  Future<void> ensureTablesExist() async {
    final db = await database;
    await _createDB(db, 2); // Tạo lại tất cả các bảng nếu chưa tồn tại
  }

  Future<void> deleteProductAttributes(int productId) async {
    final db = await instance.database;
    await db.delete(
      'product_attributes',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> _createPurchaseOrdersTableIfNotExists() async {
    final db = await database;

    // Check if purchase_orders table exists
    final purchaseOrdersTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='purchase_orders'",
    );

    if (purchaseOrdersTable.isEmpty) {
      print('Creating purchase_orders table...');
      await db.execute('''
        CREATE TABLE purchase_orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplier_name TEXT,
          supplier_phone TEXT,
          date TEXT NOT NULL,
          product_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          cost REAL NOT NULL,
          note TEXT,
          FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
        )
      ''');
      print('purchase_orders table created successfully');
    }
  }

  Future<int> insertPurchaseOrder(Map<String, dynamic> data) async {
    await _createPurchaseOrdersTableIfNotExists();
    final db = await instance.database;
    return await db.insert('purchase_orders', data);
  }

  Future<List<Map<String, dynamic>>> getPurchaseOrders(int productId) async {
    await _createPurchaseOrdersTableIfNotExists();
    final db = await instance.database;
    return await db.query(
      'purchase_orders',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getTemporaryItems() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT oi.*, o.date
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE oi.is_temporary = 1
      ORDER BY o.date DESC
    ''');
  }

  Future<void> updateOrderItemStatus(int id, bool isTemporary) async {
    final db = await database;
    await db.update(
      'order_items',
      {'is_temporary': isTemporary ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateOrderItem(
    int id,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        // Get the original order item
        final List<Map<String, dynamic>> originalItems = await txn.query(
          'order_items',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (originalItems.isEmpty) throw Exception('Order item not found');
        final originalItem = originalItems.first;

        // Get the order to update totals
        final List<Map<String, dynamic>> orders = await txn.query(
          'orders',
          where: 'id = ?',
          whereArgs: [originalItem['order_id']],
        );
        if (orders.isEmpty) throw Exception('Order not found');
        final order = orders.first;

        // Lấy giá gốc ban đầu (nếu là lần đổi đầu tiên) hoặc giữ nguyên giá gốc
        final double originalPrice = originalItem['exchange_count'] == 0
            ? originalItem['price']
            : originalItem['original_price'];

        // Tính chênh lệch giá mới so với giá hiện tại
        final double newPrice = data['price'] ?? originalItem['price'];
        final double currentPrice = originalItem['price'];
        final double priceDiff = newPrice - currentPrice;
        final double totalPriceDiff = priceDiff * originalItem['quantity'];

        // Cập nhật thông tin đổi hàng
        final Map<String, dynamic> updateData = {
          ...data,
          'exchange_count': (originalItem['exchange_count'] ?? 0) + 1,
          'is_exchanged': 1,
          'original_price': originalPrice, // Lưu giá gốc ban đầu
        };

        // Update order item
        await txn.update('order_items', updateData,
            where: 'id = ?', whereArgs: [id]);

        // Nếu giá mới thấp hơn giá hiện tại, cập nhật refund
        if (priceDiff < 0) {
          final double refundAmount = -totalPriceDiff; // Chuyển thành số dương
          await txn.update(
            'orders',
            {
              'refund_amount': refundAmount,
              'refund_date': DateTime.now().toIso8601String(),
              'refund_reason': 'Hoàn tiền chênh lệch khi đổi hàng',
              'total': order['total'] + totalPriceDiff,
              'debt': order['debt'] + totalPriceDiff,
            },
            where: 'id = ?',
            whereArgs: [originalItem['order_id']],
          );
        } else {
          // Nếu giá mới cao hơn, cập nhật tổng tiền và công nợ
          await txn.update(
            'orders',
            {
              'total': order['total'] + totalPriceDiff,
              'debt': order['debt'] + totalPriceDiff,
            },
            where: 'id = ?',
            whereArgs: [originalItem['order_id']],
          );
        }

        // Cập nhật số lượng hàng trong kho
        if (originalItem['product_id'] != null) {
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity + ? WHERE id = ?',
            [originalItem['quantity'], originalItem['product_id']],
          );
        }

        if (data['product_id'] != null) {
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity - ? WHERE id = ?',
            [originalItem['quantity'], data['product_id']],
          );
        }
      });
    } catch (e) {
      print('Error updating order item: $e');
      rethrow;
    }
  }

  Future<void> refundOrder(
      int orderId, double refundAmount, String? reason) async {
    final db = await database;
    final order = await getOrder(orderId);

    if (order['paid'] < refundAmount) {
      throw Exception('Số tiền hoàn không được vượt quá số tiền đã thanh toán');
    }

    try {
      // Bắt đầu transaction
      await db.transaction((txn) async {
        // Cập nhật đơn hàng
        await txn.update(
          'orders',
          {
            'status': 'Đã hoàn tiền',
            'refund_amount': refundAmount,
            'refund_date': DateTime.now().toIso8601String(),
            'refund_reason': reason,
            'total': 0,
            'paid': 0,
            'debt': 0,
            'revenue': 0, // Reset revenue
            'profit': 0, // Reset profit
            'shipping_fee': 0, // Reset shipping fee
            'additional_fee': 0, // Reset additional fee
            'additional_fee_description':
                'Chi phí khác', // Reset additional fee description
          },
          where: 'id = ?',
          whereArgs: [orderId],
        );

        // Cập nhật công nợ khách hàng nếu có
        if (order['customer_id'] != null && order['debt'] > 0) {
          await txn.rawUpdate(
            'UPDATE customers SET debt = debt - ? WHERE id = ?',
            [order['debt'], order['customer_id']],
          );
        }

        // Xóa phí ship expense nếu có
        final shippingFee = (order['shipping_fee'] as num?)?.toDouble() ?? 0.0;
        if (shippingFee > 0) {
          await txn.delete(
            'expenses',
            where: 'description = ?',
            whereArgs: ['Phí vận chuyển đơn hàng #$orderId'],
          );
        }

        // Xóa chi phí bổ sung expense nếu có
        final additionalFee =
            (order['additional_fee'] as num?)?.toDouble() ?? 0.0;
        final additionalFeeDescription =
            order['additional_fee_description'] as String? ?? 'Chi phí khác';
        if (additionalFee > 0) {
          await txn.delete(
            'expenses',
            where: 'description = ?',
            whereArgs: ['$additionalFeeDescription - đơn hàng #$orderId'],
          );
        }
      });
    } catch (e) {
      print('Error refunding order: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDefaultTaxAndFees() async {
    final db = await database;
    final taxResult = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['default_tax'],
    );

    final shippingResult = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['default_shipping'],
    );

    return {
      'default_tax':
          double.tryParse(taxResult.firstOrNull?['value'] as String? ?? '0') ??
              0.0,
      'default_shipping': double.tryParse(
              shippingResult.firstOrNull?['value'] as String? ?? '0') ??
          0.0,
    };
  }

  Future<void> setDefaultTax(double tax) async {
    final db = await database;
    await _setSetting('default_tax', tax.toString());
  }

  Future<void> setDefaultShipping(double shipping) async {
    final db = await database;
    await _setSetting('default_shipping', shipping.toString());
  }

  Future<void> _setSetting(String key, String value) async {
    final db = await database;
    final existing = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (existing.isEmpty) {
      await db.insert('settings', {
        'key': key,
        'value': value,
      });
    } else {
      await db.update(
        'settings',
        {'value': value},
        where: 'key = ?',
        whereArgs: [key],
      );
    }
  }

  Future<Map<String, dynamic>> getSecuritySettings() async {
    final db = await database;
    final settings = await db.query(
      'settings',
      where: 'key IN (?, ?)',
      whereArgs: ['pattern_lock', 'pin_lock'],
    );

    return {
      'pattern_lock':
          settings.any((s) => s['key'] == 'pattern_lock' && s['value'] == '1'),
      'pin_lock':
          settings.any((s) => s['key'] == 'pin_lock' && s['value'] == '1'),
    };
  }

  Future<void> setSecuritySetting(String key, bool value) async {
    await _setSetting(key, value ? '1' : '0');
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    final db = await database;
    final settings = await db.query(
      'settings',
      where: 'key IN (?, ?, ?, ?)',
      whereArgs: [
        'low_stock',
        'debt_reminder',
        'low_stock_threshold',
        'debt_reminder_days',
      ],
    );

    return {
      'low_stock':
          settings.any((s) => s['key'] == 'low_stock' && s['value'] == '1'),
      'debt_reminder':
          settings.any((s) => s['key'] == 'debt_reminder' && s['value'] == '1'),
      'low_stock_threshold': int.tryParse(
            settings.firstWhere(
              (s) => s['key'] == 'low_stock_threshold',
              orElse: () => {'value': '5'},
            )['value'] as String,
          ) ??
          5,
      'debt_reminder_days': int.tryParse(
            settings.firstWhere(
              (s) => s['key'] == 'debt_reminder_days',
              orElse: () => {'value': '7'},
            )['value'] as String,
          ) ??
          7,
    };
  }

  Future<void> setNotificationSetting(String key, dynamic value) async {
    await _setSetting(key, value.toString());
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // SKU Settings
  Future<Map<String, dynamic>> getSkuSettings() async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'settings',
        where: "key IN ('sku_prefix', 'allow_manual_sku')",
      );

      final Map<String, dynamic> settings = {
        'sku_prefix': '',
        'allow_manual_sku': true,
      };

      for (final row in result) {
        final key = row['key'] as String;
        final value = row['value'] as String;
        if (key == 'allow_manual_sku') {
          settings[key] = value == 'true';
        } else {
          settings[key] = value;
        }
      }

      return settings;
    } catch (e) {
      print('Error in getSkuSettings: $e');
      return {
        'sku_prefix': '',
        'allow_manual_sku': true,
      };
    }
  }

  Future<void> setSkuSetting(String key, String value) async {
    try {
      final db = await instance.database;
      await db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error in setSkuSetting: $e');
      rethrow;
    }
  }

  Future<String> generateSku() async {
    try {
      final settings = await getSkuSettings();
      final prefix = settings['sku_prefix'] as String;

      // Get the last SKU number
      final db = await instance.database;
      final result = await db.query(
        'products',
        columns: ['code'],
        orderBy: 'id DESC',
        limit: 1,
      );

      int lastNumber = 0;
      if (result.isNotEmpty) {
        final lastSku = result.first['code'] as String?;
        if (lastSku != null) {
          // Extract the number from the SKU
          final match = RegExp(r'\d+$').firstMatch(lastSku);
          if (match != null) {
            lastNumber = int.tryParse(match.group(0) ?? '0') ?? 0;
          }
        }
      }

      // Generate new SKU with increased number
      final newNumber = lastNumber + 1;
      final numberPart = newNumber.toString().padLeft(3, '0');
      return prefix.isEmpty ? numberPart : '$prefix-$numberPart';
    } catch (e) {
      print('Error generating SKU: $e');
      rethrow;
    }
  }

  Future<bool> isSkuExists(String sku) async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'products',
        where: 'code = ?',
        whereArgs: [sku],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error in isSkuExists: $e');
      rethrow;
    }
  }

  // Interface Settings
  Future<Map<String, dynamic>> getInterfaceSettings() async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'settings',
        where: "key IN ('dark_mode', 'theme_color')",
      );

      final Map<String, dynamic> settings = {
        'dark_mode': false,
        'theme_color': 'blue',
      };

      for (final row in result) {
        final key = row['key'] as String;
        final value = row['value'] as String;
        if (key == 'dark_mode') {
          settings['dark_mode'] = value == 'true';
        } else if (key == 'theme_color') {
          settings['theme_color'] = value;
        }
      }

      return settings;
    } catch (e) {
      print('Error in getInterfaceSettings: $e');
      return {
        'dark_mode': false,
        'theme_color': 'blue',
      };
    }
  }

  Future<void> setInterfaceSetting(String key, dynamic value) async {
    try {
      final db = await instance.database;
      await db.insert(
        'settings',
        {
          'key': key,
          'value': value.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error in setInterfaceSetting: $e');
      rethrow;
    }
  }

  // Unit Settings
  Future<Map<String, dynamic>> getUnitSettings() async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'settings',
        where:
            "key IN ('currency', 'default_unit', 'show_unit', 'enable_unit')",
      );

      final Map<String, dynamic> settings = {
        'currency': 'VND',
        'default_unit': 'cái',
        'show_unit': false,
        'enable_unit': true,
      };

      for (final row in result) {
        final key = row['key'] as String;
        final value = row['value'] as String;
        if (key == 'show_unit' || key == 'enable_unit') {
          settings[key] = value == 'true';
        } else {
          settings[key] = value;
        }
      }

      return settings;
    } catch (e) {
      print('Error in getUnitSettings: $e');
      return {
        'currency': 'VND',
        'default_unit': 'cái',
        'show_unit': false,
        'enable_unit': true,
      };
    }
  }

  Future<void> setUnitSetting(String key, String value) async {
    try {
      final db = await instance.database;
      await db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error in setUnitSetting: $e');
      rethrow;
    }
  }

  Future<bool> isProductNameExists(String name, {int? excludeId}) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: excludeId != null
          ? 'normalized_name = ? AND id != ?'
          : 'normalized_name = ?',
      whereArgs: excludeId != null
          ? [name.toLowerCase(), excludeId]
          : [name.toLowerCase()],
    );
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>?> findProductByName(String name,
      {int? excludeId}) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: excludeId != null
          ? 'normalized_name = ? AND id != ?'
          : 'normalized_name = ?',
      whereArgs: excludeId != null
          ? [name.toLowerCase(), excludeId]
          : [name.toLowerCase()],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> forceResetDatabase() async {
    try {
      print('Force resetting database...');

      // Close existing database connection if any
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Delete the database file
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'selleasy.db');
      print('Deleting database at path: $path');
      await databaseFactory.deleteDatabase(path);

      // Initialize new database
      print('Initializing new database...');
      _database = await _initDB('selleasy.db');
      print('Database reset completed successfully');
    } catch (e) {
      print('Error during force reset: $e');
      rethrow;
    }
  }

  Future<void> addProductStock(
    int productId,
    int quantity,
    double cost, {
    String? supplierName,
    String? supplierPhone,
    String? note,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      // Update product quantity
      await txn.rawUpdate(
        'UPDATE products SET quantity = quantity + ? WHERE id = ?',
        [quantity, productId],
      );

      // Create purchase order
      await txn.insert('purchase_orders', {
        'product_id': productId,
        'date': DateTime.now().toIso8601String(),
        'quantity': quantity,
        'cost': cost,
        'supplier_name': supplierName,
        'supplier_phone': supplierPhone,
        'note': note,
      });
    });
  }

  Future<int> getProductSoldCount(int productId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(oi.quantity) as total_sold
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE oi.product_id = ?
      AND o.status != 'Nháp'
    ''', [productId]);

    return (result.first['total_sold'] as num?)?.toInt() ?? 0;
  }

  Future<void> deleteOrderItems(int orderId) async {
    final db = await database;
    await db.delete(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> updateOrderRevenue(
      int orderId, Map<String, dynamic> data) async {
    final db = await database;
    await db.update(
      'orders',
      {
        'revenue': data['revenue'],
        'profit': data['profit'],
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> updateExistingCustomersCreatedAt() async {
    final db = await database;
    try {
      // Kiểm tra xem cột created_at đã tồn tại chưa
      final columns = await db.rawQuery("PRAGMA table_info('customers')");
      bool hasCreatedAt = columns.any((col) => col['name'] == 'created_at');

      if (!hasCreatedAt) {
        // Thêm cột created_at nếu chưa có
        await db.execute(
            "ALTER TABLE customers ADD COLUMN created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP");
      }

      // Cập nhật created_at cho các khách hàng chưa có
      await db.execute('''
        UPDATE customers
        SET created_at = CURRENT_TIMESTAMP
        WHERE created_at IS NULL
      ''');
    } catch (e) {
      print('Error updating existing customers created_at: $e');
    }
  }

  // Notification methods
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final db = await database;
      return await db.query(
        'notifications',
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<int> insertNotification(Map<String, dynamic> notification) async {
    try {
      final db = await database;
      return await db.insert('notifications', notification);
    } catch (e) {
      print('Error inserting notification: $e');
      return -1;
    }
  }

  Future<int> markNotificationAsRead(int id) async {
    try {
      final db = await database;
      return await db.update(
        'notifications',
        {'is_read': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error marking notification as read: $e');
      return 0;
    }
  }

  Future<int> markAllNotificationsAsRead() async {
    try {
      final db = await database;
      return await db.update(
        'notifications',
        {'is_read': 1},
      );
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return 0;
    }
  }

  Future<int> deleteNotification(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting notification: $e');
      return 0;
    }
  }

  Future<int> deleteAllNotifications() async {
    try {
      final db = await database;
      return await db.delete('notifications');
    } catch (e) {
      print('Error deleting all notifications: $e');
      return 0;
    }
  }

  Future<int> getUnreadNotificationsCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notifications WHERE is_read = 0',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting unread notifications count: $e');
      return 0;
    }
  }
}
