import '../models/customer_model.dart';
import '../../services/database_helper.dart';

class CustomerRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    
    return List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
  }

  // Get customer by id
  Future<Customer?> getCustomerById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    
    return null;
  }

  // Search customers
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'normalized_name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    
    return List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
  }

  // Insert a customer
  Future<int> insertCustomer(Customer customer) async {
    final db = await _databaseHelper.database;
    return await db.insert('customers', customer.toMap());
  }

  // Update a customer
  Future<int> updateCustomer(Customer customer) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  // Delete a customer
  Future<int> deleteCustomer(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update customer debt
  Future<int> updateCustomerDebt(int id, double debt) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'customers',
      {'debt': debt},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get customers with debt
  Future<List<Customer>> getCustomersWithDebt() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'debt > 0',
    );
    
    return List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
  }

  // Get total customer debt
  Future<double> getTotalCustomerDebt() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(debt) as total_debt FROM customers',
    );
    
    return result.first['total_debt'] as double? ?? 0.0;
  }

  // Get customer count
  Future<int> getCustomerCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get customer total spent
  Future<double> getCustomerTotalSpent(int customerId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(total) as total_spent FROM orders WHERE customer_id = ?',
      [customerId],
    );
    
    return result.first['total_spent'] as double? ?? 0.0;
  }

  // Get customer order count
  Future<int> getCustomerOrderCount(int customerId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE customer_id = ?',
      [customerId],
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
