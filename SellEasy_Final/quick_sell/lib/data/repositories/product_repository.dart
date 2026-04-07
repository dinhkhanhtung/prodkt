import '../models/product_model.dart';
import '../../services/database_helper.dart';

class ProductRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Get all products
  Future<List<Product>> getAllProducts() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    
    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  // Get product by id
  Future<Product?> getProductById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    
    return null;
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'normalized_name LIKE ? OR code LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    
    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  // Insert a product
  Future<int> insertProduct(Product product) async {
    final db = await _databaseHelper.database;
    return await db.insert('products', product.toMap());
  }

  // Update a product
  Future<int> updateProduct(Product product) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // Delete a product
  Future<int> deleteProduct(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update product quantity
  Future<int> updateProductQuantity(int id, int quantity) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'products',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'quantity <= 5 AND quantity > 0',
    );
    
    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  // Get out of stock products
  Future<List<Product>> getOutOfStockProducts() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'quantity <= 0',
    );
    
    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  // Get total product value
  Future<double> getTotalProductValue() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity * cost_price) as total_value FROM products',
    );
    
    return result.first['total_value'] as double? ?? 0.0;
  }

  // Get product count
  Future<int> getProductCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
