import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/custom_field.dart';
import '../services/database_helper.dart';
import 'forms/create_order_form.dart';
import 'forms/add_product_form.dart';
import '../theme/app_theme.dart';
import 'dart:io';
import 'dart:async';
import '../utils/format_utils.dart';
import '../utils/toast_helper.dart';
import 'package:intl/intl.dart';
import '../utils/dialog_helper.dart';
import '../utils/responsive_utils.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allProducts = []; // Store all products
  List<Map<String, dynamic>> _products = []; // Store filtered products
  List<CustomField> _customFields = [];
  bool _isLoading = false;
  bool _showSimpleGrid = true;
  bool _isFirstRun = true;
  bool _showFilterChips = false;
  List<String> _selectedFilters = [];
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minPrice;
  double? _maxPrice;
  int? _minQuantity;
  int? _maxQuantity;
  DateTime? _expiryStartDate;
  DateTime? _expiryEndDate;
  Map<String, String> _selectedAttributes = {};
  Timer? _refreshTimer;
  Timer? _searchDebouncer;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Map<int, int> _productSoldCounts = {}; // Cache for sold counts
  bool _isDisposed = false;
  final _gridKey = GlobalKey<AnimatedGridState>();
  final _listKey = GlobalKey<AnimatedListState>();

  final List<String> _quickFilterOptions = [
    'Tất cả',
    'Còn hàng',
    'Hết hàng',
    'Sắp hết hàng',
    'Hàng mới',
    'Hàng tồn',
  ];

  final List<String> _sortOptions = [
    'Mới nhất',
    'Giá tăng',
    'Giá giảm',
  ];

  String _selectedQuickFilter = 'Tất cả';
  String _selectedSort = 'Mới nhất';

  bool _isNewProduct(String entryDate) {
    final now = DateTime.now();
    final productDate = DateTime.parse(entryDate);
    return now.difference(productDate).inDays <=
        7; // Sản phẩm trong vòng 7 ngày được coi là mới
  }

  bool _isOldProduct(String entryDate) {
    final now = DateTime.now();
    final productDate = DateTime.parse(entryDate);
    return now.difference(productDate).inDays >=
        30; // Sản phẩm tồn kho trên 30 ngày
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final dt = DateTime.parse(dateTime);
      return '${DateFormat('dd/MM/yyyy HH:mm').format(dt)}';
    } catch (e) {
      return dateTime;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    _loadData();

    // Add auto-refresh timer with shorter interval
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && !_isLoading) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    _refreshTimer?.cancel();
    _searchDebouncer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final customFields = await DatabaseHelper.instance.getCustomFields();
      final products = await DatabaseHelper.instance.getProducts(
        searchQuery: _searchQuery,
      );

      // Load sold counts for all products
      final Map<int, int> soldCounts = {};
      for (final product in products) {
        final count =
            await DatabaseHelper.instance.getProductSoldCount(product['id']);
        soldCounts[product['id']] = count;
      }

      if (!mounted) return;

      setState(() {
        _customFields =
            customFields.map((f) => CustomField.fromMap(f)).toList();
        _allProducts = products;
        _productSoldCounts = soldCounts;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  Future<void> _refreshData() async {
    if (_isDisposed || !mounted || _isLoading) return;

    try {
      final products = await DatabaseHelper.instance.getProducts(
        searchQuery: _searchQuery,
      );

      // Only update if there are changes
      if (!_areProductsEqual(_allProducts, products)) {
        // Load sold counts for new/changed products
        final Map<int, int> soldCounts = Map.from(_productSoldCounts);
        final List<Future<void>> futures = [];

        for (final product in products) {
          final id = product['id'];
          if (!_allProducts.any((p) => p['id'] == id)) {
            futures.add(
                DatabaseHelper.instance.getProductSoldCount(id).then((count) {
              soldCounts[id] = count;
            }));
          }
        }

        // Wait for all sold counts to load in parallel
        await Future.wait(futures);

        if (_isDisposed || !mounted) return;

        setState(() {
          _allProducts = products;
          _productSoldCounts = soldCounts;
          _applyFilters();
        });
      }
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }

  bool _areProductsEqual(
      List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i]['id'] != list2[i]['id'] ||
          list1[i]['quantity'] != list2[i]['quantity'] ||
          list1[i]['sell_price'] != list2[i]['sell_price']) {
        return false;
      }
    }
    return true;
  }

  Widget _buildSoldCount(int productId) {
    final soldCount = _productSoldCounts[productId] ?? 0;
    final fontSize = ResponsiveUtils.getAdaptiveFontSize(context, 10);

    return Text(
      'Đã bán: $soldCount',
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: fontSize,
      ),
    );
  }

  void _applyFilters() {
    var filteredProducts = List<Map<String, dynamic>>.from(_allProducts);

    // Apply quick filters
    if (_selectedQuickFilter == 'Còn hàng') {
      filteredProducts =
          filteredProducts.where((p) => p['quantity'] > 0).toList();
    } else if (_selectedQuickFilter == 'Hết hàng') {
      filteredProducts =
          filteredProducts.where((p) => p['quantity'] <= 0).toList();
    } else if (_selectedQuickFilter == 'Sắp hết hàng') {
      filteredProducts = filteredProducts
          .where((p) => p['quantity'] > 0 && p['quantity'] <= 5)
          .toList();
    } else if (_selectedQuickFilter == 'Hàng mới') {
      filteredProducts = filteredProducts
          .where((p) => _isNewProduct(p['entry_date']))
          .toList();
    } else if (_selectedQuickFilter == 'Hàng tồn') {
      filteredProducts = filteredProducts
          .where((p) => _isOldProduct(p['entry_date']) && p['quantity'] > 0)
          .toList();
    }

    // Apply date filters
    if (_startDate != null) {
      filteredProducts = filteredProducts.where((p) {
        final entryDate = DateTime.parse(p['entry_date']);
        return entryDate.isAfter(_startDate!);
      }).toList();
    }
    if (_endDate != null) {
      filteredProducts = filteredProducts.where((p) {
        final entryDate = DateTime.parse(p['entry_date']);
        return entryDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // Apply price filters
    if (_minPrice != null) {
      filteredProducts = filteredProducts
          .where((p) => (p['sell_price'] as double) >= _minPrice!)
          .toList();
    }
    if (_maxPrice != null) {
      filteredProducts = filteredProducts
          .where((p) => (p['sell_price'] as double) <= _maxPrice!)
          .toList();
    }

    // Apply quantity filters
    if (_minQuantity != null) {
      filteredProducts = filteredProducts
          .where((p) => p['quantity'] >= _minQuantity!)
          .toList();
    }
    if (_maxQuantity != null) {
      filteredProducts = filteredProducts
          .where((p) => p['quantity'] <= _maxQuantity!)
          .toList();
    }

    // Apply attribute filters
    if (_selectedAttributes.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        final attributes =
            Map<String, String>.from(product['attributes'] ?? {});
        for (final entry in _selectedAttributes.entries) {
          if (attributes[entry.key] != entry.value) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    // Apply expiry date filters
    if (_expiryStartDate != null || _expiryEndDate != null) {
      filteredProducts = filteredProducts.where((product) {
        final attributes =
            Map<String, String>.from(product['attributes'] ?? {});
        final expiryDate = attributes['Hạn sử dụng'];
        if (expiryDate == null) return false;

        final expiry = DateTime.parse(expiryDate);
        if (_expiryStartDate != null && expiry.isBefore(_expiryStartDate!)) {
          return false;
        }
        if (_expiryEndDate != null &&
            expiry.isAfter(_expiryEndDate!.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      }).toList();
    }

    // Apply sorting
    switch (_selectedSort) {
      case 'Giá tăng':
        filteredProducts.sort((a, b) =>
            (a['sell_price'] as double).compareTo(b['sell_price'] as double));
        break;
      case 'Giá giảm':
        filteredProducts.sort((a, b) =>
            (b['sell_price'] as double).compareTo(a['sell_price'] as double));
        break;
      case 'Mới nhất':
        filteredProducts.sort((a, b) => DateTime.parse(b['entry_date'])
            .compareTo(DateTime.parse(a['entry_date'])));
        break;
    }

    setState(() {
      _products = filteredProducts;
    });
  }

  void _onSearchChanged(String value) {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      if (_searchQuery != value) {
        setState(() {
          _searchQuery = value;
          // Apply local filter first for immediate feedback
          if (value.isEmpty) {
            _products = _allProducts;
          } else {
            final normalizedQuery = value.toLowerCase().trim();
            _products = _allProducts.where((product) {
              final name = (product['name'] as String).toLowerCase();
              final code = (product['code'] as String?)?.toLowerCase() ?? '';
              return name.contains(normalizedQuery) ||
                  code.contains(normalizedQuery);
            }).toList();
          }
        });
        // Then load from database for complete results
        _loadData();
      }
    });
  }

  void _onFilterSelected(bool selected, String filter) {
    if (_selectedQuickFilter != (selected ? filter : 'Tất cả')) {
      setState(() {
        _selectedQuickFilter = selected ? filter : 'Tất cả';
      });
      _applyFilters();
    }
  }

  void _onSortSelected(bool selected, String sort) {
    if (_selectedSort != (selected ? sort : 'Mới nhất')) {
      setState(() {
        _selectedSort = selected ? sort : 'Mới nhất';
      });
      _applyFilters();
    }
  }

  void _toggleFilterChips() {
    setState(() {
      _showFilterChips = !_showFilterChips;
    });
  }

  Future<void> _showProductDetails(Map<String, dynamic> product) async {
    final attributes = await DatabaseHelper.instance.getProductAttributes(
      product['id'] as int,
    );

    if (!mounted) return;

    await DialogHelper.showAnimatedDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: EdgeInsets.zero,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(38),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              // Icon sản phẩm
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Tiêu đề
              Expanded(
                child: Text(
                  product['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              // Nút đóng
              IconButton(
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withAlpha(25),
                ),
              ),
            ],
          ),
        ),
        content: Hero(
          tag: 'product-${product['id']}',
          child: Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.getDialogMaxWidth(context),
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (product['image_path'] != null)
                    SizedBox(
                      height:
                          MediaQuery.of(context).size.width > 600 ? 300 : 200,
                      child: _buildImage(product['image_path']),
                    ),

                  // Thao tác ngay dưới ảnh
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Thao tác',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.add,
                        label: 'Tạo đơn',
                        onTap: product['quantity'] <= 0
                            ? null
                            : () async {
                                Navigator.pop(context);
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateOrderForm(
                                      initialProduct: Product.fromMap(product),
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadData();
                                }
                              },
                      ),
                      _buildActionButton(
                        icon: Icons.edit,
                        label: 'Sửa',
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddProductForm(
                                product: Product(
                                  id: product['id'],
                                  name: product['name'],
                                  normalizedName: product['normalized_name'],
                                  code: product['code'],
                                  quantity: product['quantity'],
                                  sellPrice: product['sell_price'],
                                  costPrice: product['cost_price'],
                                  imagePath: product['image_path'],
                                  entryDate:
                                      DateTime.parse(product['entry_date']),
                                ),
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadData();
                          }
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.history,
                        label: 'Lịch sử',
                        onTap: () {
                          Navigator.pop(context);
                          _showProductHistory(product);
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.delete,
                        label: 'Xóa',
                        onTap: () async {
                          final confirm =
                              await DialogHelper.showAnimatedDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: const Text(
                                  'Bạn có chắc chắn muốn xóa sản phẩm này?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Hủy'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _deleteProduct(product['id'] as int);
                          }
                        },
                      ),
                    ],
                  ),
                  // Thông tin cơ bản
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withAlpha(76),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product['code'] != null &&
                                      product['code'].isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.qr_code,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Mã: ${product['code']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Số lượng: ${product['quantity']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_formatPrice(product['sell_price'] as double)}đ',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                      context, 16),
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Giá vốn: ${_formatPrice(product['cost_price'] as double)}đ',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ngày nhập: ${_formatDateTime(product['entry_date'])}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Thuộc tính sản phẩm
                  if (attributes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withAlpha(76),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Thuộc tính',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          ...attributes.map((attr) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${attr['name']}:',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(attr['value']),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Dải màu nhỏ dưới footer
        insetPadding: EdgeInsets.zero,
        buttonPadding: EdgeInsets.zero,
        actionsPadding: EdgeInsets.zero,
        actions: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withAlpha(128),
                  Theme.of(context).colorScheme.primary.withAlpha(76),
                  Theme.of(context).colorScheme.primary.withAlpha(128),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showProductHistory(Map<String, dynamic> product) async {
    try {
      // Get order history
      final orderItems = await DatabaseHelper.instance
          .getProductOrderHistory(product['id'] as int);

      // Get purchase order history
      final purchaseOrders =
          await DatabaseHelper.instance.getPurchaseOrders(product['id'] as int);

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => DefaultTabController(
          length: 3,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: ResponsiveUtils.getDialogMaxWidth(context),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.primary.withAlpha(38),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                    child: Row(
                      children: [
                        // Icon lịch sử
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.history,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Tiêu đề
                        Expanded(
                          child: Text(
                            'Lịch sử: ${product['name']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Nút đóng
                        IconButton(
                          iconSize: 20,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withAlpha(25),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // TabBar
                  TabBar(
                    labelPadding: EdgeInsets.symmetric(
                        horizontal:
                            ResponsiveUtils.getAdaptiveSpacing(context, 8.0)),
                    labelStyle: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 13),
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 13),
                    ),
                    tabs: const [
                      Tab(text: 'Bán hàng'),
                      Tab(text: 'Nhập hàng'),
                      Tab(text: 'Nhà cung cấp'),
                    ],
                  ),
                  // TabBarView
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab bán hàng
                        orderItems.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Chưa có lịch sử bán hàng',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: orderItems.length,
                                itemBuilder: (context, index) {
                                  final item = orderItems[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Đơn hàng #${item['order_id']}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _formatDateTime(item['date']),
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .shopping_cart_outlined,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                            'Số lượng: ${item['quantity']}'),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.attach_money,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                            'Giá bán: ${_formatPrice(item['price'] as double)}đ'),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                        // Tab nhập hàng
                        purchaseOrders.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_outlined,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Chưa có lịch sử nhập hàng',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: purchaseOrders.length,
                                itemBuilder: (context, index) {
                                  final order = purchaseOrders[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Nhập hàng #${order['id']}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _formatDateTime(order['date']),
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .inventory_2_outlined,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                            'Số lượng: ${order['quantity']}'),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.attach_money,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                            'Giá nhập: ${_formatPrice(order['cost'] as double)}đ'),
                                                      ],
                                                    ),
                                                    if (order['note'] !=
                                                        null) ...[
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.note_outlined,
                                                            size: 16,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Expanded(
                                                            child: Text(
                                                                'Ghi chú: ${order['note']}'),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                        // Tab nhà cung cấp
                        purchaseOrders.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Chưa có thông tin nhà cung cấp',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: purchaseOrders.length,
                                itemBuilder: (context, index) {
                                  final order = purchaseOrders[index];
                                  if (order['supplier_name'] == null &&
                                      order['supplier_phone'] == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                order['supplier_name'] ??
                                                    'Không có tên',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _formatDateTime(order['date']),
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          if (order['supplier_phone'] != null)
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.phone_outlined,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                    'SĐT: ${order['supplier_phone']}'),
                                              ],
                                            ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.inventory_2_outlined,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                  'Số lượng: ${order['quantity']}'),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.attach_money,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                  'Giá nhập: ${_formatPrice(order['cost'] as double)}đ'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                  // Footer với dải màu
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.primary.withAlpha(15),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      // Xử lý lỗi
      _showMessage('Lỗi: ${e.toString()}', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (isError) {
      ToastHelper.showError(context, message);
    } else {
      ToastHelper.showSuccess(context, message);
    }
  }

  Future<void> _deleteProduct(int id) async {
    try {
      await DatabaseHelper.instance.deleteProduct(id);
      if (mounted) {
        Navigator.pop(context);
        _loadData();
        _showMessage('Đã xóa sản phẩm');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Lỗi: ${e.toString()}', isError: true);
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    // Adjust sizes based on screen size
    final iconSize = ResponsiveUtils.getAdaptiveIconSize(context, 24);
    final fontSize = ResponsiveUtils.getAdaptiveFontSize(context, 12);
    final padding = EdgeInsets.symmetric(
      horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 12),
      vertical: ResponsiveUtils.getAdaptiveSpacing(context, 8),
    );
    final spacingHeight = ResponsiveUtils.getAdaptiveSpacing(context, 4);

    return DialogHelper.buildAnimatedTooltip(
      message: onTap == null ? 'Không thể thực hiện thao tác này' : label,
      child: InkWell(
        onTap: onTap ??
            () {
              if (label == 'Tạo đơn') {
                _showMessage(
                  'Không thể tạo đơn vì sản phẩm đã hết hàng',
                  isError: true,
                );
              }
            },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize),
              SizedBox(height: spacingHeight),
              Text(
                label,
                style: TextStyle(fontSize: fontSize),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Removed unused method _addNewProduct

  Future<void> _showFilterDialog() async {
    final priceController = TextEditingController(
      text: _minPrice != null ? _formatPrice(_minPrice!) : null,
    );
    final maxPriceController = TextEditingController(
      text: _maxPrice != null ? _formatPrice(_maxPrice!) : null,
    );
    final quantityController = TextEditingController(
      text: _minQuantity?.toString(),
    );
    final maxQuantityController = TextEditingController(
      text: _maxQuantity?.toString(),
    );

    String formatPriceInput(String text) {
      if (text.isEmpty) return '';
      final number = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));
      if (number == null) return '';
      return number.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );
    }

    double? parsePriceInput(String text) {
      if (text.isEmpty) return null;
      return double.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));
    }

    await DialogHelper.showAnimatedDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.getDialogMaxWidth(context),
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(38),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      // Icon bộ lọc
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.filter_list,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tiêu đề
                      Expanded(
                        child: Text(
                          'Bộ lọc nâng cao',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Nút đóng
                      IconButton(
                        icon: Icon(Icons.close,
                            color: Theme.of(context).colorScheme.onSurface),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withAlpha(25),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ngày nhập
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ngày nhập:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _startDate ?? DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null) {
                                          setModalState(
                                              () => _startDate = date);
                                        }
                                      },
                                      icon: const Icon(Icons.calendar_today,
                                          size: 16),
                                      label: Text(
                                        _startDate != null
                                            ? _startDate!
                                                .toLocal()
                                                .toString()
                                                .split(' ')[0]
                                            : 'Từ ngày',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _endDate ?? DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null) {
                                          setModalState(() => _endDate = date);
                                        }
                                      },
                                      icon: const Icon(Icons.calendar_today,
                                          size: 16),
                                      label: Text(
                                        _endDate != null
                                            ? _endDate!
                                                .toLocal()
                                                .toString()
                                                .split(' ')[0]
                                            : 'Đến ngày',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Giá bán
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Giá bán:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: priceController,
                                      decoration: InputDecoration(
                                        labelText: 'Giá tối thiểu',
                                        labelStyle:
                                            const TextStyle(fontSize: 13),
                                        border: const OutlineInputBorder(),
                                        suffixText: 'đ',
                                        prefixIcon: const Icon(
                                            Icons.attach_money,
                                            size: 18),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[800]
                                                : Colors.grey[50],
                                      ),
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color),
                                      onChanged: (value) {
                                        final formattedValue =
                                            formatPriceInput(value);
                                        if (formattedValue != value) {
                                          priceController.value =
                                              TextEditingValue(
                                            text: formattedValue,
                                            selection: TextSelection.collapsed(
                                              offset: formattedValue.length,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: maxPriceController,
                                      decoration: InputDecoration(
                                        labelText: 'Giá tối đa',
                                        labelStyle:
                                            const TextStyle(fontSize: 13),
                                        border: const OutlineInputBorder(),
                                        suffixText: 'đ',
                                        prefixIcon: const Icon(
                                            Icons.attach_money,
                                            size: 18),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[800]
                                                : Colors.grey[50],
                                      ),
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color),
                                      onChanged: (value) {
                                        final formattedValue =
                                            formatPriceInput(value);
                                        if (formattedValue != value) {
                                          maxPriceController.value =
                                              TextEditingValue(
                                            text: formattedValue,
                                            selection: TextSelection.collapsed(
                                              offset: formattedValue.length,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Số lượng
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Số lượng:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: quantityController,
                                      decoration: InputDecoration(
                                        labelText: 'Số lượng tối thiểu',
                                        labelStyle:
                                            const TextStyle(fontSize: 13),
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.inventory,
                                            size: 18),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[800]
                                                : Colors.grey[50],
                                      ),
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: maxQuantityController,
                                      decoration: InputDecoration(
                                        labelText: 'Số lượng tối đa',
                                        labelStyle:
                                            const TextStyle(fontSize: 13),
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.inventory,
                                            size: 18),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[800]
                                                : Colors.grey[50],
                                      ),
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Hạn sử dụng
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hạn sử dụng:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _expiryStartDate ??
                                              DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (date != null) {
                                          setModalState(
                                              () => _expiryStartDate = date);
                                        }
                                      },
                                      icon: const Icon(Icons.calendar_today,
                                          size: 16),
                                      label: Text(
                                        _expiryStartDate != null
                                            ? _expiryStartDate!
                                                .toLocal()
                                                .toString()
                                                .split(' ')[0]
                                            : 'Từ ngày',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _expiryEndDate ?? DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (date != null) {
                                          setModalState(
                                              () => _expiryEndDate = date);
                                        }
                                      },
                                      icon: const Icon(Icons.calendar_today,
                                          size: 16),
                                      label: Text(
                                        _expiryEndDate != null
                                            ? _expiryEndDate!
                                                .toLocal()
                                                .toString()
                                                .split(' ')[0]
                                            : 'Đến ngày',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer với các nút
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(15),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                            _minPrice = null;
                            _maxPrice = null;
                            _minQuantity = null;
                            _maxQuantity = null;
                            _expiryStartDate = null;
                            _expiryEndDate = null;
                            _selectedAttributes.clear();
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Xóa bộ lọc',
                            style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            _minPrice = parsePriceInput(priceController.text);
                            _maxPrice =
                                parsePriceInput(maxPriceController.text);
                            _minQuantity =
                                int.tryParse(quantityController.text);
                            _maxQuantity =
                                int.tryParse(maxQuantityController.text);
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Áp dụng',
                            style: TextStyle(fontSize: 13)),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withAlpha(13),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Tìm kiếm sản phẩm...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: AnimatedOpacity(
                                    opacity: _searchController.text.isNotEmpty
                                        ? 1.0
                                        : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed:
                                          _searchController.text.isNotEmpty
                                              ? _clearSearch
                                              : null,
                                      splashRadius: 16,
                                      tooltip: 'Xóa',
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow,
                                ),
                                onChanged: _onSearchChanged,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: _toggleFilterChips,
                              icon: Icon(_showFilterChips
                                  ? Icons.filter_alt_off
                                  : Icons.filter_alt),
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onSurface,
                                padding: EdgeInsets.zero,
                                minimumSize: Size(
                                    ResponsiveUtils.getAdaptiveIconSize(
                                        context, 36),
                                    ResponsiveUtils.getAdaptiveIconSize(
                                        context, 36)),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedScale(
                              scale: _selectedFilters.isNotEmpty ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: IconButton(
                                onPressed: _showFilterDialog,
                                icon: const Icon(Icons.filter_list),
                                style: IconButton.styleFrom(
                                  backgroundColor: _selectedFilters.isNotEmpty
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withAlpha(25)
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLow,
                                  foregroundColor: _selectedFilters.isNotEmpty
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(
                                      ResponsiveUtils.getAdaptiveIconSize(
                                          context, 36),
                                      ResponsiveUtils.getAdaptiveIconSize(
                                          context, 36)),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: _showSimpleGrid ? 0 : 0.25,
                              duration: const Duration(milliseconds: 300),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _showSimpleGrid = !_showSimpleGrid;
                                  });
                                },
                                icon: Icon(_showSimpleGrid
                                    ? Icons.view_list
                                    : Icons.grid_view),
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onSurface,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(
                                      ResponsiveUtils.getAdaptiveIconSize(
                                          context, 36),
                                      ResponsiveUtils.getAdaptiveIconSize(
                                          context, 36)),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _showFilterChips ? 56 : 0,
                          margin:
                              EdgeInsets.only(top: _showFilterChips ? 16 : 0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ..._quickFilterOptions.map((filter) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                          begin: 0,
                                          end: _selectedQuickFilter == filter
                                              ? 1
                                              : 0,
                                        ),
                                        duration:
                                            const Duration(milliseconds: 200),
                                        builder: (context, value, child) {
                                          return Transform.scale(
                                            scale: 1.0 + (0.1 * value),
                                            child: FilterChip(
                                              label: Text(
                                                filter,
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              selected: _selectedQuickFilter ==
                                                  filter,
                                              onSelected: (selected) =>
                                                  _onFilterSelected(
                                                      selected, filter),
                                              labelPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 0),
                                              showCheckmark: true,
                                              selectedColor: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withAlpha(51),
                                              checkmarkColor: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          );
                                        },
                                      ),
                                    )),
                                const SizedBox(width: 16),
                                ..._sortOptions.map((sort) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(
                                          sort,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        selected: _selectedSort == sort,
                                        onSelected: (selected) =>
                                            _onSortSelected(selected, sort),
                                        labelPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 0),
                                        showCheckmark: true,
                                        selectedColor: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withAlpha(51),
                                        checkmarkColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _products.isEmpty
                          ? _buildEmptyState()
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _showSimpleGrid
                                  ? _buildProductGrid()
                                  : _buildProductList(),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation.drive(
                                      Tween<double>(begin: 0.95, end: 1.0)
                                          .chain(CurveTween(
                                              curve: Curves.easeOut)),
                                    ),
                                    child: child,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;

    switch (_selectedQuickFilter) {
      case 'Sắp hết hàng':
        title = 'Không có sản phẩm nào sắp hết';
        subtitle = 'Tất cả sản phẩm đều có số lượng tốt';
        break;
      case 'Hết hàng':
        title = 'Tất cả sản phẩm đều còn hàng';
        subtitle = 'Không có sản phẩm nào hết hàng';
        break;
      case 'Hàng tồn':
        title = 'Không có hàng tồn kho';
        subtitle = 'Tất cả sản phẩm đều có doanh số tốt';
        break;
      case 'Còn hàng':
        if (_products.isEmpty) {
          title = 'Tất cả sản phẩm đã hết hàng';
          subtitle = 'Vui lòng nhập thêm hàng';
        } else {
          title = 'Không tìm thấy sản phẩm';
          subtitle = 'Thử tìm kiếm với từ khóa khác';
        }
        break;
      default:
        if (_searchQuery.isEmpty) {
          title = 'Chưa có sản phẩm nào';
          subtitle = 'Nhấn nút + để thêm sản phẩm mới';
        } else {
          title = 'Không tìm thấy sản phẩm';
          subtitle = 'Thử tìm kiếm với từ khóa khác';
        }
    }

    // Thêm thông báo cho bộ lọc sắp xếp
    if (_selectedSort != 'Mới nhất' && _products.isEmpty) {
      switch (_selectedSort) {
        case 'Giá tăng':
          title = 'Không có sản phẩm để sắp xếp';
          subtitle = 'Thêm sản phẩm để xem giá tăng dần';
          break;
        case 'Giá giảm':
          title = 'Không có sản phẩm để sắp xếp';
          subtitle = 'Thêm sản phẩm để xem giá giảm dần';
          break;
      }
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: child,
          ),
        );
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? imagePath) {
    // Adjust icon size based on screen size
    final iconSize = ResponsiveUtils.getAdaptiveIconSize(context, 48);

    if (imagePath == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Icon(
          Icons.image_outlined,
          size: iconSize,
          color:
              Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
        ),
      );
    }

    if (imagePath.startsWith('http')) {
      // Adjust icon size based on screen size
      final iconSize = ResponsiveUtils.getAdaptiveIconSize(context, 48);

      return FadeInImage.assetNetwork(
        placeholder: 'assets/placeholder.png', // Add a placeholder image
        image: imagePath,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 150),
        imageErrorBuilder: (context, error, stackTrace) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Icon(
            Icons.image_not_supported_outlined,
            size: iconSize,
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
        ),
      );
    }

    if (imagePath.startsWith('file://')) {
      // Adjust icon size based on screen size
      final iconSize = ResponsiveUtils.getAdaptiveIconSize(context, 48);

      return Image.file(
        File(imagePath.replaceFirst('file://', '')),
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Icon(
            Icons.image_not_supported_outlined,
            size: iconSize,
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: ResponsiveUtils.getAdaptiveIconSize(context, 48),
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
      ),
    );
  }

  Widget _buildProductGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveUtils.getGridColumnCount(context);
        final childAspectRatio =
            ResponsiveUtils.getProductCardAspectRatio(context);
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        // Adjust spacing based on screen size
        final crossAxisSpacing =
            ResponsiveUtils.getAdaptiveSpacing(context, 16);
        final mainAxisSpacing = ResponsiveUtils.getAdaptiveSpacing(context, 16);

        return GridView.builder(
          key: const PageStorageKey('product_grid'),
          padding: EdgeInsets.only(
            top: 16,
            bottom: 16,
            // Add extra padding in landscape mode on tablets
            left: isLandscape && constraints.maxWidth > 600 ? 8 : 0,
            right: isLandscape && constraints.maxWidth > 600 ? 8 : 0,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];
            return RepaintBoundary(
              child: _buildProductCard(product),
            );
          },
        );
      },
    );
  }

  Widget _buildProductList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;

        // Adjust padding based on screen size
        final horizontalPadding = isTablet ? 16.0 : 0.0;
        final verticalPadding = ResponsiveUtils.getAdaptiveSpacing(context, 8);

        return ListView.builder(
          key: const PageStorageKey('product_list'),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];
            return RepaintBoundary(
              child: _buildListItem(product),
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final quantity = product['quantity'] as int;
    final quantityColor = quantity <= 0
        ? AppTheme.errorColor
        : quantity <= 5
            ? AppTheme.warningColor
            : Colors.green;
    final isNew = _isNewProduct(product['entry_date']);

    // Get responsive font sizes
    final titleFontSize = ResponsiveUtils.getAdaptiveFontSize(context, 13);
    final subtitleFontSize = ResponsiveUtils.getAdaptiveFontSize(context, 11);
    final priceFontSize = ResponsiveUtils.getAdaptiveFontSize(context, 13);

    // Adjust padding based on screen size
    final cardPadding = MediaQuery.of(context).size.width > 600 ? 12.0 : 8.0;

    return Hero(
      tag: 'product-${product['id']}',
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _showProductDetails(product),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: _buildImage(product['image_path']),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.all(cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'],
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mã: ${product['code'] ?? 'N/A'}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: subtitleFontSize,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: quantityColor.withAlpha(25),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'SL: $quantity',
                                      style: TextStyle(
                                        color: quantityColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: subtitleFontSize,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  _buildSoldCount(product['id'] as int),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_formatPrice(product['sell_price'] as double)}đ',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: priceFontSize,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (quantity <= 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Hết hàng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (quantity <= 5)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Sắp hết',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (isNew)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Mới',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> product) {
    final quantity = product['quantity'] as int;
    final quantityColor = quantity <= 0
        ? AppTheme.errorColor
        : quantity <= 5
            ? AppTheme.warningColor
            : Colors.green;
    final isNew = _isNewProduct(product['entry_date']);

    // Get responsive sizes
    final titleFontSize = ResponsiveUtils.getAdaptiveFontSize(context, 13);
    final subtitleFontSize = ResponsiveUtils.getAdaptiveFontSize(context, 11);
    final priceFontSize = ResponsiveUtils.getAdaptiveFontSize(context, 13);

    // Adjust image size based on screen size
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final imageSize = isTablet ? 100.0 : 80.0;
    final cardPadding = isTablet ? 16.0 : 12.0;
    final spacingWidth = isTablet ? 16.0 : 12.0;

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(
          bottom: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: _buildImage(product['image_path']),
                    ),
                  ),
                  SizedBox(width: spacingWidth),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mã: ${product['code'] ?? 'N/A'}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: subtitleFontSize,
                          ),
                        ),
                        SizedBox(height: isTablet ? 8.0 : 4.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: quantityColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'SL: $quantity',
                                    style: TextStyle(
                                      color: quantityColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: subtitleFontSize,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                _buildSoldCount(product['id'] as int),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_formatPrice(product['sell_price'] as double)}đ',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: priceFontSize,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (quantity <= 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Hết hàng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (quantity <= 5)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Sắp hết',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (isNew)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Mới',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
