import 'package:flutter/foundation.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/utils/string_utils.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  String _filterCategory = 'Tất cả';
  String _sortBy = 'name_asc';

  // Getters
  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get filterCategory => _filterCategory;
  String get sortBy => _sortBy;

  // Load all products
  Future<void> loadProducts() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _products = await _repository.getAllProducts();
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter products by category
  void filterByCategory(String category) {
    _filterCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Sort products
  void sortProducts(String sortBy) {
    _sortBy = sortBy;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters and sorting
  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final normalizedQuery = StringUtils.normalize(_searchQuery);
        final nameMatch = product.normalizedName.contains(normalizedQuery);
        final codeMatch = product.code?.toLowerCase().contains(normalizedQuery) ?? false;
        if (!nameMatch && !codeMatch) {
          return false;
        }
      }

      // Apply category filter
      if (_filterCategory != 'Tất cả') {
        // TODO: Implement category filtering when categories are added
        return true;
      }

      return true;
    }).toList();

    // Apply sorting
    _filteredProducts.sort((a, b) {
      switch (_sortBy) {
        case 'name_asc':
          return a.name.compareTo(b.name);
        case 'name_desc':
          return b.name.compareTo(a.name);
        case 'price_asc':
          return a.sellPrice.compareTo(b.sellPrice);
        case 'price_desc':
          return b.sellPrice.compareTo(a.sellPrice);
        case 'quantity_asc':
          return a.quantity.compareTo(b.quantity);
        case 'quantity_desc':
          return b.quantity.compareTo(a.quantity);
        default:
          return a.name.compareTo(b.name);
      }
    });
  }

  // Add a product
  Future<bool> addProduct(Product product) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final normalizedName = StringUtils.normalize(product.name);
      final newProduct = Product(
        name: product.name,
        normalizedName: normalizedName,
        code: product.code,
        quantity: product.quantity,
        sellPrice: product.sellPrice,
        costPrice: product.costPrice,
        imagePath: product.imagePath,
        entryDate: product.entryDate,
        isTemporary: product.isTemporary,
        unit: product.unit,
        attributes: product.attributes,
      );

      final id = await _repository.insertProduct(newProduct);
      final addedProduct = newProduct.copyWith(id: id);
      _products.add(addedProduct);
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

  // Update a product
  Future<bool> updateProduct(Product product) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final normalizedName = StringUtils.normalize(product.name);
      final updatedProduct = product.copyWith(normalizedName: normalizedName);
      
      await _repository.updateProduct(updatedProduct);
      
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
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

  // Delete a product
  Future<bool> deleteProduct(int id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _repository.deleteProduct(id);
      _products.removeWhere((product) => product.id == id);
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

  // Update product quantity
  Future<bool> updateProductQuantity(int id, int quantity) async {
    try {
      await _repository.updateProductQuantity(id, quantity);
      
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = _products[index].copyWith(quantity: quantity);
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

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    try {
      return await _repository.getLowStockProducts();
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Get out of stock products
  Future<List<Product>> getOutOfStockProducts() async {
    try {
      return await _repository.getOutOfStockProducts();
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Get product by id
  Future<Product?> getProductById(int id) async {
    try {
      return await _repository.getProductById(id);
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
