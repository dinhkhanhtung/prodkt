import 'package:flutter/foundation.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../../data/repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository = OrderRepository();
  
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  String _filterStatus = 'Tất cả';
  String _sortBy = 'date_desc';

  // Getters
  List<Order> get orders => _orders;
  List<Order> get filteredOrders => _filteredOrders;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;
  String get sortBy => _sortBy;

  // Load all orders
  Future<void> loadOrders() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _orders = await _repository.getAllOrders();
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Search orders
  void searchOrders(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter orders by status
  void filterByStatus(String status) {
    _filterStatus = status;
    _applyFilters();
    notifyListeners();
  }

  // Sort orders
  void sortOrders(String sortBy) {
    _sortBy = sortBy;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters and sorting
  void _applyFilters() {
    _filteredOrders = _orders.where((order) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final idMatch = order.id.toString().contains(_searchQuery);
        final customerMatch = order.customer?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        if (!idMatch && !customerMatch) {
          return false;
        }
      }

      // Apply status filter
      if (_filterStatus != 'Tất cả' && order.status != _filterStatus) {
        return false;
      }

      return true;
    }).toList();

    // Apply sorting
    _filteredOrders.sort((a, b) {
      switch (_sortBy) {
        case 'date_asc':
          return a.date.compareTo(b.date);
        case 'date_desc':
          return b.date.compareTo(a.date);
        case 'total_asc':
          return a.total.compareTo(b.total);
        case 'total_desc':
          return b.total.compareTo(a.total);
        default:
          return b.date.compareTo(a.date);
      }
    });
  }

  // Add an order
  Future<bool> addOrder(Order order, List<OrderItem> items) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final id = await _repository.insertOrder(order, items);
      await loadOrders(); // Reload all orders to get the complete order with items
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

  // Update an order
  Future<bool> updateOrder(Order order) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _repository.updateOrder(order);
      
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = order;
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

  // Delete an order
  Future<bool> deleteOrder(int id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _repository.deleteOrder(id);
      _orders.removeWhere((order) => order.id == id);
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

  // Get order by id
  Future<Order?> getOrderById(int id) async {
    try {
      return await _repository.getOrderById(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Get orders by date range
  Future<List<Order>> getOrdersByDateRange(String startDate, String endDate) async {
    try {
      return await _repository.getOrdersByDateRange(startDate, endDate);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Get orders by customer
  Future<List<Order>> getOrdersByCustomer(int customerId) async {
    try {
      return await _repository.getOrdersByCustomer(customerId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Get total sales by date range
  Future<double> getTotalSalesByDateRange(String startDate, String endDate) async {
    try {
      return await _repository.getTotalSalesByDateRange(startDate, endDate);
    } catch (e) {
      _error = e.toString();
      return 0.0;
    }
  }

  // Get total profit by date range
  Future<double> getTotalProfitByDateRange(String startDate, String endDate) async {
    try {
      return await _repository.getTotalProfitByDateRange(startDate, endDate);
    } catch (e) {
      _error = e.toString();
      return 0.0;
    }
  }

  // Get order count by date range
  Future<int> getOrderCountByDateRange(String startDate, String endDate) async {
    try {
      return await _repository.getOrderCountByDateRange(startDate, endDate);
    } catch (e) {
      _error = e.toString();
      return 0;
    }
  }

  // Get top selling products by date range
  Future<List<Map<String, dynamic>>> getTopSellingProductsByDateRange(
    String startDate, 
    String endDate, 
    int limit
  ) async {
    try {
      return await _repository.getTopSellingProductsByDateRange(startDate, endDate, limit);
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
