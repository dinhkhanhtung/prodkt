import 'package:flutter/foundation.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();
  
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  String _filterCategory = 'Tất cả';
  String _sortBy = 'date_desc';

  // Getters
  List<Expense> get expenses => _expenses;
  List<Expense> get filteredExpenses => _filteredExpenses;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get filterCategory => _filterCategory;
  String get sortBy => _sortBy;

  // Load all expenses
  Future<void> loadExpenses() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _expenses = await _repository.getAllExpenses();
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Search expenses
  void searchExpenses(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter expenses by category
  void filterByCategory(String category) {
    _filterCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Sort expenses
  void sortExpenses(String sortBy) {
    _sortBy = sortBy;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters and sorting
  void _applyFilters() {
    _filteredExpenses = _expenses.where((expense) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final descriptionMatch = expense.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        final categoryMatch = expense.category.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!descriptionMatch && !categoryMatch) {
          return false;
        }
      }

      // Apply category filter
      if (_filterCategory != 'Tất cả' && expense.category != _filterCategory) {
        return false;
      }

      return true;
    }).toList();

    // Apply sorting
    _filteredExpenses.sort((a, b) {
      switch (_sortBy) {
        case 'date_asc':
          return a.date.compareTo(b.date);
        case 'date_desc':
          return b.date.compareTo(a.date);
        case 'amount_asc':
          return a.amount.compareTo(b.amount);
        case 'amount_desc':
          return b.amount.compareTo(a.amount);
        default:
          return b.date.compareTo(a.date);
      }
    });
  }

  // Add an expense
  Future<bool> addExpense(Expense expense) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final id = await _repository.insertExpense(expense);
      final addedExpense = expense.copyWith(id: id);
      _expenses.add(addedExpense);
      _applyFilters();
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

  // Update an expense
  Future<bool> updateExpense(Expense expense) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _repository.updateExpense(expense);
      
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
      }
      
      _applyFilters();
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

  // Delete an expense
  Future<bool> deleteExpense(int id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _repository.deleteExpense(id);
      _expenses.removeWhere((expense) => expense.id == id);
      _applyFilters();
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

  // Get expense by id
  Future<Expense?> getExpenseById(int id) async {
    try {
      return await _repository.getExpenseById(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Get expenses by date range
  Future<List<Expense>> getExpensesByDateRange(String startDate, String endDate) async {
    try {
      return await _repository.getExpensesByDateRange(startDate, endDate);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Get total expenses by date range
  Future<double> getTotalExpensesByDateRange(String startDate, String endDate) async {
    try {
      return await _repository.getTotalExpensesByDateRange(startDate, endDate);
    } catch (e) {
      _error = e.toString();
      return 0.0;
    }
  }

  // Get expense categories with total amount by date range
  Future<List<Map<String, dynamic>>> getExpenseCategoriesByDateRange(
    String startDate,
    String endDate,
  ) async {
    try {
      return await _repository.getExpenseCategoriesByDateRange(startDate, endDate);
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
