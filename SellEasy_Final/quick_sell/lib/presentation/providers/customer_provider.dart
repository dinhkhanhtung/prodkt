import 'package:flutter/foundation.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../core/utils/string_utils.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository = CustomerRepository();
  
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  String _sortBy = 'name_asc';

  // Getters
  List<Customer> get customers => _customers;
  List<Customer> get filteredCustomers => _filteredCustomers;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;

  // Load all customers
  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _customers = await _repository.getAllCustomers();
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Search customers
  void searchCustomers(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Sort customers
  void sortCustomers(String sortBy) {
    _sortBy = sortBy;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters and sorting
  void _applyFilters() {
    _filteredCustomers = _customers.where((customer) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final normalizedQuery = StringUtils.normalize(_searchQuery);
        final nameMatch = customer.normalizedName.contains(normalizedQuery);
        final phoneMatch = customer.phone?.contains(_searchQuery) ?? false;
        final emailMatch = customer.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        if (!nameMatch && !phoneMatch && !emailMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply sorting
    _filteredCustomers.sort((a, b) {
      switch (_sortBy) {
        case 'name_asc':
          return a.name.compareTo(b.name);
        case 'name_desc':
          return b.name.compareTo(a.name);
        case 'debt_asc':
          return a.debt.compareTo(b.debt);
        case 'debt_desc':
          return b.debt.compareTo(a.debt);
        default:
          return a.name.compareTo(b.name);
      }
    });
  }

  // Add a customer
  Future<bool> addCustomer(Customer customer) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final normalizedName = StringUtils.normalize(customer.name);
      final newCustomer = Customer(
        name: customer.name,
        normalizedName: normalizedName,
        phone: customer.phone,
        email: customer.email,
        address: customer.address,
        debt: customer.debt,
        createdAt: customer.createdAt,
      );

      final id = await _repository.insertCustomer(newCustomer);
      final addedCustomer = newCustomer.copyWith(id: id);
      _customers.add(addedCustomer);
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

  // Update a customer
  Future<bool> updateCustomer(Customer customer) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final normalizedName = StringUtils.normalize(customer.name);
      final updatedCustomer = customer.copyWith(normalizedName: normalizedName);
      
      await _repository.updateCustomer(updatedCustomer);
      
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = updatedCustomer;
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

  // Delete a customer
  Future<bool> deleteCustomer(int id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _repository.deleteCustomer(id);
      _customers.removeWhere((customer) => customer.id == id);
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

  // Update customer debt
  Future<bool> updateCustomerDebt(int id, double debt) async {
    try {
      await _repository.updateCustomerDebt(id, debt);
      
      final index = _customers.indexWhere((c) => c.id == id);
      if (index != -1) {
        _customers[index] = _customers[index].copyWith(debt: debt);
      }
      
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get customers with debt
  Future<List<Customer>> getCustomersWithDebt() async {
    try {
      return await _repository.getCustomersWithDebt();
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Get customer by id
  Future<Customer?> getCustomerById(int id) async {
    try {
      return await _repository.getCustomerById(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }
}
