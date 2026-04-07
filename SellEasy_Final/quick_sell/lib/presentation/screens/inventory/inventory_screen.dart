import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../widgets/inventory/product_list_item.dart';
import '../../widgets/inventory/product_filter_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _isLoading = true;
  bool _isDialOpen = false;
  List<Map<String, dynamic>> _products = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterCategory = 'Tất cả';
  String _sortBy = 'name_asc';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    // Giả lập tải dữ liệu
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    setState(() {
      _products = [
        {
          'id': 1,
          'name': 'Áo thun nam',
          'code': 'ATN001',
          'quantity': 45,
          'sell_price': 150000.0,
          'cost_price': 100000.0,
          'image_path': null,
          'category': 'Áo',
          'status': 'in_stock',
        },
        {
          'id': 2,
          'name': 'Quần jean nữ',
          'code': 'QJN001',
          'quantity': 8,
          'sell_price': 300000.0,
          'cost_price': 200000.0,
          'image_path': null,
          'category': 'Quần',
          'status': 'low_stock',
        },
        {
          'id': 3,
          'name': 'Giày thể thao',
          'code': 'GTT001',
          'quantity': 3,
          'sell_price': 500000.0,
          'cost_price': 300000.0,
          'image_path': null,
          'category': 'Giày',
          'status': 'low_stock',
        },
        {
          'id': 4,
          'name': 'Áo khoác',
          'code': 'AK001',
          'quantity': 0,
          'sell_price': 450000.0,
          'cost_price': 300000.0,
          'image_path': null,
          'category': 'Áo',
          'status': 'out_of_stock',
        },
      ];
      
      _isLoading = false;
    });
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoading = true;
    });
    await _loadProducts();
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    return _products.where((product) {
      // Lọc theo tìm kiếm
      final nameMatch = product['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final codeMatch = product['code'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final searchMatch = nameMatch || codeMatch;
      
      // Lọc theo danh mục
      final categoryMatch = _filterCategory == 'Tất cả' || product['category'] == _filterCategory;
      
      return searchMatch && categoryMatch;
    }).toList()..sort((a, b) {
      // Sắp xếp
      switch (_sortBy) {
        case 'name_asc':
          return a['name'].toString().compareTo(b['name'].toString());
        case 'name_desc':
          return b['name'].toString().compareTo(a['name'].toString());
        case 'price_asc':
          return (a['sell_price'] as double).compareTo(b['sell_price'] as double);
        case 'price_desc':
          return (b['sell_price'] as double).compareTo(a['sell_price'] as double);
        case 'quantity_asc':
          return (a['quantity'] as int).compareTo(b['quantity'] as int);
        case 'quantity_desc':
          return (b['quantity'] as int).compareTo(a['quantity'] as int);
        default:
          return a['name'].toString().compareTo(b['name'].toString());
      }
    });
  }

  void _showFilterDialog() {
    DialogHelper.showSlideDialog(
      context: context,
      builder: (context) => ProductFilterDialog(
        initialCategory: _filterCategory,
        initialSortBy: _sortBy,
        onApply: (category, sortBy) {
          setState(() {
            _filterCategory = category;
            _sortBy = sortBy;
          });
        },
      ),
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
    // TODO: Implement product details dialog
    DialogHelper.showToast(
      context: context,
      message: 'Chi tiết sản phẩm: ${product['name']}',
    );
  }

  void _addNewProduct() {
    // TODO: Implement add new product
    DialogHelper.showToast(
      context: context,
      message: 'Thêm sản phẩm mới',
    );
  }

  void _scanBarcode() {
    // TODO: Implement barcode scanning
    DialogHelper.showToast(
      context: context,
      message: 'Quét mã vạch',
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();
    
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                // Filter and sort bar
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hiển thị ${filteredProducts.length} sản phẩm',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showFilterDialog,
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Lọc'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Product list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            Text(
                              'Không tìm thấy sản phẩm',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshProducts,
                        child: ListView.builder(
                          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return ProductListItem(
                              product: product,
                              onTap: () => _showProductDetails(product),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: ResponsiveUtils.getAdaptiveSpacing(context, 8),
        openCloseDial: ValueNotifier(_isDialOpen),
        onOpen: () => setState(() => _isDialOpen = true),
        onClose: () => setState(() => _isDialOpen = false),
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 8.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        ),
        spaceBetweenChildren:
            ResponsiveUtils.getAdaptiveSpacing(context, 12),
        children: [
          SpeedDialChild(
            child: Icon(Icons.add_circle_outline,
                size: ResponsiveUtils.getAdaptiveIconSize(
                    context, 24)),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            label: 'Thêm sản phẩm',
            labelStyle: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                    context, 16)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getAdaptiveSpacing(context, 8)),
            ),
            onTap: _addNewProduct,
          ),
          SpeedDialChild(
            child: Icon(Icons.qr_code_scanner,
                size: ResponsiveUtils.getAdaptiveIconSize(
                    context, 24)),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Quét mã vạch',
            labelStyle: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                    context, 16)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getAdaptiveSpacing(context, 8)),
            ),
            onTap: _scanBarcode,
          ),
        ],
      ),
    );
  }
}
