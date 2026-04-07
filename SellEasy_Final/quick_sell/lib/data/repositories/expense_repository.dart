import '../models/expense_model.dart';
import '../../services/database_helper.dart';

class ExpenseRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Get all expenses
  Future<List<Expense>> getAllExpenses() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  // Get expense by id
  Future<Expense?> getExpenseById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    
    return null;
  }

  // Insert an expense
  Future<int> insertExpense(Expense expense) async {
    final db = await _databaseHelper.database;
    return await db.insert('expenses', expense.toMap());
  }

  // Update an expense
  Future<int> updateExpense(Expense expense) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Delete an expense
  Future<int> deleteExpense(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get expenses by date range
  Future<List<Expense>> getExpensesByDateRange(String startDate, String endDate) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  // Get expenses by category
  Future<List<Expense>> getExpensesByCategory(String category) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  // Get total expenses by date range
  Future<double> getTotalExpensesByDateRange(String startDate, String endDate) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total_expenses FROM expenses WHERE date BETWEEN ? AND ?',
      [startDate, endDate],
    );
    
    return result.first['total_expenses'] as double? ?? 0.0;
  }

  // Get total expenses by category and date range
  Future<double> getTotalExpensesByCategoryAndDateRange(
    String category,
    String startDate,
    String endDate,
  ) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total_expenses FROM expenses WHERE category = ? AND date BETWEEN ? AND ?',
      [category, startDate, endDate],
    );
    
    return result.first['total_expenses'] as double? ?? 0.0;
  }

  // Get expense categories with total amount by date range
  Future<List<Map<String, dynamic>>> getExpenseCategoriesByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as amount FROM expenses WHERE date BETWEEN ? AND ? GROUP BY category ORDER BY amount DESC',
      [startDate, endDate],
    );
    
    return result;
  }

  // Get expense count
  Future<int> getExpenseCount() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM expenses');
    
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
