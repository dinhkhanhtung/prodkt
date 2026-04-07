import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dart:io';
import 'dart:math';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../models/product.dart';
import '../../models/customer.dart';
import '../../models/custom_field.dart';
import '../../services/database_helper.dart';
import '../../utils/format_utils.dart';
import 'dart:convert';
import '../../utils/calculation_utils.dart';
import '../../widgets/help_dialog.dart';
import '../../widgets/toast_overlay.dart';
import 'add_product_form.dart';
import '../../utils/dialog_helper.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/toast_helper.dart';
import '../../utils/responsive_utils.dart';
import '../home_screen.dart';

class CreateOrderForm extends StatefulWidget {
  final Product? initialProduct;
  final Map<String, dynamic>? initialOrder;
  final bool isExchange;
  final double? oldOrderTotal;

  const CreateOrderForm({
    super.key,
    this.initialProduct,
    this.initialOrder,
    this.isExchange = false,
    this.oldOrderTotal,
  });

  @override
  State<CreateOrderForm> createState() => _CreateOrderFormState();
}

class _CreateOrderFormState extends State<CreateOrderForm> {
  final _formKey = GlobalKey<FormState>();
  final List<OrderItem> _items = [];
  Customer? _selectedCustomer;
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerNameFocusNode = FocusNode();
  final _addProductFocusNode = FocusNode();
  final _taxController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _shippingController = TextEditingController(text: '0');
  String _discountType = 'percent'; // 'percent' or 'amount'
  String _orderCategory = 'Bán lẻ'; // 'Bán lẻ' or 'Bán sỉ'
  List<Customer> _customers = [];
  List<Product> _products = [];
  List<CustomField> _customFields = [];
  double _taxPercent = 0;
  double _discountPercent = 0;
  double _discountAmount = 0;
  bool _isFirstRun = true;
  bool _isLoading = false;
  final _paymentController = TextEditingController(text: '0');
  double _paymentAmount = 0;
  bool _isNewCustomer = true;
  double _shippingFee = 0;
  double _additionalFee = 0; // Chi phí bổ sung
  String _additionalFeeDescription = 'Chi phí khác'; // Mô tả chi phí bổ sung
  final _additionalFeeController = TextEditingController(text: '0');
  String _paymentMethod = 'cash';
  String _deliveryMethod = 'pickup';
  String _orderNote = '';
  bool _hasUserEditedPayment = false;

  // Lưu ID của đơn hàng cũ khi load lại đơn hàng
  int? _existingOrderId;
  // Lưu trạng thái ban đầu của đơn hàng để so sánh khi lưu
  Map<String, dynamic>? _initialOrderState;
  // Lưu danh sách sản phẩm ban đầu để so sánh khi lưu
  List<OrderItem>? _initialItems;
  // Đánh dấu đơn hàng được load là đơn đổi hàng
  bool _isExchangeOrder = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-focus on the add product button instead of customer name field
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_addProductFocusNode.canRequestFocus) {
        _addProductFocusNode.requestFocus();
      }
    });
    if (widget.initialProduct != null) {
      _addProductItem(widget.initialProduct!);
    }
    if (widget.initialOrder != null) {
      _initializeFromOrder(widget.initialOrder!);
    }
    if (widget.isExchange) {
      _orderCategory = 'Đổi hàng';
      if (widget.oldOrderTotal != null) {
        _paymentAmount = widget.oldOrderTotal!;
        _paymentController.text =
            FormatUtils.formatCurrency(widget.oldOrderTotal!);
        _hasUserEditedPayment = true;
      }
      _shippingFee = 0;
      _shippingController.text = '0';
    }
  }

  Future<void> _initializeFromOrder(Map<String, dynamic> order) async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      // Lưu ID của đơn hàng cũ
      _existingOrderId = order['id'];
      // Lưu trạng thái ban đầu của đơn hàng
      _initialOrderState = Map<String, dynamic>.from(order);

      // Kiểm tra xem đơn hàng có phải là đơn đổi hàng hay không
      _isExchangeOrder = order['category'] == 'Đổi hàng';

      // Load customer info
      if (order['customer_id'] != null) {
        final customerData =
            await DatabaseHelper.instance.getCustomer(order['customer_id']);
        if (customerData != null) {
          _selectedCustomer = Customer.fromMap(customerData);
          _customerNameController.text = _selectedCustomer!.name;
          _customerPhoneController.text = _selectedCustomer!.phone ?? '';
          _isNewCustomer = false;
        }
      }

      // Load order items - handle both direct items and items that need to be fetched
      if (order['items'] != null) {
        // Items are provided directly
        final items = order['items'] as List<dynamic>;
        for (final item in items) {
          _items.add(OrderItem(
            id: item['id'],
            orderId: item['order_id'],
            productId: item['product_id'],
            name: item['name'],
            quantity: item['quantity'],
            price: item['price'],
            costPrice: item['cost_price'],
            attributes: jsonDecode(item['attributes'] ?? '{}'),
          ));
        }
      } else if (order['id'] != null) {
        // Need to fetch items from database
        final items = await DatabaseHelper.instance.getOrderItems(order['id']);
        for (final item in items) {
          _items.add(OrderItem(
            id: item['id'],
            orderId: item['order_id'],
            productId: item['product_id'],
            name: item['name'],
            quantity: item['quantity'],
            price: item['price'],
            costPrice: item['cost_price'],
            attributes: jsonDecode(item['attributes'] ?? '{}'),
          ));
        }
      }

      // Set other order details with null safety
      _taxPercent = order['tax_percent']?.toDouble() ?? 0.0;
      _taxController.text = _taxPercent.toString();
      _discountAmount = order['discount_amount']?.toDouble() ?? 0.0;
      _discountController.text = FormatUtils.formatCurrency(_discountAmount);
      _shippingFee = order['shipping_fee']?.toDouble() ?? 0.0;
      _shippingController.text = FormatUtils.formatCurrency(_shippingFee);
      _additionalFee = order['additional_fee']?.toDouble() ?? 0.0;
      _additionalFeeController.text =
          FormatUtils.formatCurrency(_additionalFee);
      _additionalFeeDescription =
          order['additional_fee_description'] ?? 'Chi phí khác';
      _orderNote = order['note'] ?? '';
      _orderCategory = order['category'] ?? 'Bán lẻ';

      // Handle payment amount
      if (!_hasUserEditedPayment) {
        _paymentAmount = order['paid']?.toDouble() ?? 0.0;
        _paymentController.text = FormatUtils.formatCurrency(_paymentAmount);
      }

      // If it's a draft order, set payment amount to total
      if (order['status'] == 'Nháp') {
        final total = _items.fold<double>(0, (sum, item) => sum + item.total);
        if (!_hasUserEditedPayment) {
          _paymentAmount = total;
          _paymentController.text = FormatUtils.formatCurrency(total);
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Lỗi: ${e.toString()}', isError: true);
    }
  }

  Future<void> _loadData() async {
    final customers = await DatabaseHelper.instance.getCustomers();
    final products = await DatabaseHelper.instance.getProducts();
    final customFields = await DatabaseHelper.instance.getCustomFields();
    final defaultSettings =
        await DatabaseHelper.instance.getDefaultTaxAndFees();

    if (mounted) {
      setState(() {
        _customers = customers.map((c) => Customer.fromMap(c)).toList();
        _products = products.map((p) => Product.fromMap(p)).toList();
        _customFields =
            customFields.map((f) => CustomField.fromMap(f)).toList();
        _isFirstRun = false;

        // Áp dụng giá trị mặc định
        _taxPercent = defaultSettings['default_tax'] ?? 0;
        _taxController.text = _taxPercent.toString();
        _shippingFee = defaultSettings['default_shipping'] ?? 0;
        _shippingController.text = FormatUtils.formatCurrency(_shippingFee);
        _additionalFee = defaultSettings['default_additional_fee'] ?? 0;
        _additionalFeeController.text =
            FormatUtils.formatCurrency(_additionalFee);
        _additionalFeeDescription =
            defaultSettings['default_additional_fee_description'] ??
                'Chi phí khác';
      });
    }
  }

  void _addProductItem(Product product) {
    setState(() {
      // Kiểm tra số lượng trong kho
      if (product.quantity <= 0) {
        _showMessage('Sản phẩm đã hết hàng', isError: true);
        return;
      }

      // Thêm sản phẩm vào đơn với số lượng mặc định là 1
      _items.insert(
        0,
        OrderItem(
          productId: product.id,
          name: product.name,
          quantity: 1,
          price: product.sellPrice,
          costPrice: product.costPrice,
          attributes: {},
        ),
      );
    });
  }

  Future<void> _addTemporaryItem() async {
    // Hiển thị dialog xác nhận
    final confirm = await DialogHelper.showAnimatedDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận nhập hàng'),
        content: const Text(
          'Bạn có chắc chắn đã nhận hàng và muốn nhập vào kho không?\n\n'
          'Lưu ý: Hàng nhập vào sẽ được thêm vào đơn hàng hiện tại.',
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.cancel),
            label: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_circle),
            label: const Text('Đã nhận hàng'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Lấy danh sách sản phẩm hiện tại để so sánh sau
    final currentProducts = await DatabaseHelper.instance.getProducts();

    // Mở form Nhập hàng
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductForm(),
      ),
    );

    // Nếu có sản phẩm mới được thêm vào
    if (result == true) {
      // Lấy danh sách sản phẩm mới
      final newProducts = await DatabaseHelper.instance.getProducts();

      // Tìm các sản phẩm mới được thêm vào
      final addedProducts = newProducts.where((newProduct) {
        return !currentProducts
            .any((currentProduct) => currentProduct['id'] == newProduct['id']);
      }).toList();

      if (addedProducts.isEmpty) return;

      // Chuyển đổi sản phẩm mới thành Product objects
      final newProductObjects =
          addedProducts.map((p) => Product.fromMap(p)).toList();

      // Cập nhật state một lần duy nhất
      setState(() {
        // Cập nhật danh sách sản phẩm
        _products.addAll(newProductObjects);

        // Thêm tất cả sản phẩm vừa nhập vào đơn hàng
        for (final product in newProductObjects) {
          // Tìm sản phẩm trong đơn hàng nếu đã có
          final existingItemIndex = _items.indexWhere(
            (item) => item.productId == product.id,
          );

          if (existingItemIndex != -1) {
            // Nếu sản phẩm đã có trong đơn hàng, tăng số lượng
            final existingItem = _items[existingItemIndex];
            final newQuantity = existingItem.quantity + 1;

            // Kiểm tra số lượng tồn kho
            if (newQuantity > product.quantity) {
              _showMessage(
                'Chỉ còn ${product.quantity} sản phẩm trong kho',
                isError: true,
              );
              continue;
            }

            // Cập nhật số lượng trong đơn hàng
            _items[existingItemIndex] = existingItem.copyWith(
              quantity: newQuantity,
            );
            _showMessage('Đã cập nhật số lượng ${product.name}');
          } else {
            // Nếu là sản phẩm mới, thêm vào đơn hàng
            _items.insert(
              0,
              OrderItem(
                productId: product.id,
                name: product.name,
                quantity: 1,
                price: product.sellPrice,
                costPrice: product.costPrice,
                attributes: {},
              ),
            );
            _showMessage('Đã thêm ${product.name} vào đơn hàng');
          }
        }
      });
    }
  }

  Future<void> _addItem() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn sản phẩm'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              final isOutOfStock = product.quantity <= 0;
              return Card(
                child: ListTile(
                  enabled: !isOutOfStock,
                  leading: product.imagePath != null &&
                          product.imagePath!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(
                                product.imagePath!.replaceFirst('file://', '')),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return Container(
                                width: ResponsiveUtils.getAdaptiveIconSize(
                                    context, 48),
                                height: ResponsiveUtils.getAdaptiveIconSize(
                                    context, 48),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: ResponsiveUtils.getAdaptiveIconSize(
                                      context, 24),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.3),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          width:
                              ResponsiveUtils.getAdaptiveIconSize(context, 48),
                          height:
                              ResponsiveUtils.getAdaptiveIconSize(context, 48),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: ResponsiveUtils.getAdaptiveIconSize(
                                context, 24),
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.3),
                          ),
                        ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(product.name),
                      ),
                      if (product.code != null && product.code!.isNotEmpty)
                        Text(
                          '#${product.code}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    'Tồn kho: ${product.quantity} | Giá: ${FormatUtils.formatCurrency(product.sellPrice)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: isOutOfStock
                      ? Text(
                          'Hết hàng',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                        )
                      : null,
                  onTap: isOutOfStock
                      ? () {
                          _showMessage('Sản phẩm đã hết hàng', isError: true);
                        }
                      : () {
                          setState(() {
                            // Tìm sản phẩm trong đơn hàng
                            final existingItemIndex = _items.indexWhere(
                              (item) => item.productId == product.id,
                            );

                            if (existingItemIndex != -1) {
                              // Nếu sản phẩm đã có trong đơn hàng
                              final existingItem = _items[existingItemIndex];
                              final newQuantity = existingItem.quantity + 1;

                              // Kiểm tra số lượng tồn kho
                              if (newQuantity > product.quantity) {
                                _showMessage(
                                  'Chỉ còn ${product.quantity} sản phẩm trong kho',
                                  isError: true,
                                );
                                Navigator.pop(context);
                                return;
                              }

                              // Cập nhật số lượng trong đơn hàng
                              _items[existingItemIndex] = existingItem.copyWith(
                                quantity: newQuantity,
                              );
                              _showMessage(
                                  'Đã cập nhật số lượng ${product.name}');
                            } else {
                              // Nếu là sản phẩm mới
                              _items.insert(
                                0,
                                OrderItem(
                                  productId: product.id,
                                  name: product.name,
                                  quantity: 1,
                                  price: product.sellPrice,
                                  costPrice: product.costPrice,
                                  attributes: {},
                                ),
                              );
                              _showMessage(
                                  'Đã thêm ${product.name} vào đơn hàng');
                            }
                          });
                          Navigator.pop(context);
                        },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _updateItemQuantity(OrderItem item, int delta) {
    setState(() {
      final index = _items.indexOf(item);
      if (index != -1) {
        final newQuantity = item.quantity + delta;
        if (item.productId != null) {
          final productIndex =
              _products.indexWhere((p) => p.id == item.productId);
          if (productIndex != -1) {
            final product = _products[productIndex];

            // Kiểm tra số lượng trong kho khi tăng
            if (delta > 0 && newQuantity > product.quantity) {
              _showMessage(
                'Chỉ còn ${product.quantity} sản phẩm trong kho',
                isError: true,
              );
              return;
            }
          }
        }

        if (newQuantity > 0) {
          _items[index] = item.copyWith(quantity: newQuantity);
          _showMessage('Đã cập nhật số lượng ${item.name}');
        } else {
          _items.removeAt(index);
          _showMessage('Đã xóa ${item.name} khỏi đơn hàng');
        }
      }
    });
  }

  void _removeItem(OrderItem item) {
    setState(() {
      _items.remove(item);
      _showMessage('Đã xóa ${item.name} khỏi đơn hàng');
    });
  }

  Future<void> _showOptions() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tùy chọn'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thông tin đơn hàng
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        'Thông tin đơn hàng',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: _orderCategory,
                      decoration: const InputDecoration(
                        labelText: 'Loại đơn hàng',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'Bán lẻ',
                          child: Text('Bán lẻ'),
                        ),
                        const DropdownMenuItem(
                          value: 'Bán sỉ',
                          child: Text('Bán sỉ'),
                        ),
                        if (widget.isExchange)
                          const DropdownMenuItem(
                            value: 'Đổi hàng',
                            child: Text('Đổi hàng'),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() => _orderCategory = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        border: OutlineInputBorder(),
                        helperText: 'Thông tin thêm về đơn hàng',
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                      onChanged: (value) {
                        setState(() => _orderNote = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Giá và chiết khấu
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        'Giá và chiết khấu',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    TextField(
                      controller: _taxController,
                      decoration: const InputDecoration(
                        labelText: 'Thuế (%)',
                        border: OutlineInputBorder(),
                        helperText:
                            'Phần trăm thuế áp dụng trên tổng giá trị đơn hàng',
                        prefixIcon: Icon(Icons.percent),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(
                            () => _taxPercent = double.tryParse(value) ?? 0);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _discountController,
                      decoration: const InputDecoration(
                        labelText: 'Chiết khấu (đ)',
                        border: OutlineInputBorder(),
                        helperText:
                            'Số tiền giảm trừ trực tiếp vào tổng đơn hàng',
                        prefixIcon: Icon(Icons.discount),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final numericValue =
                            value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (numericValue.isNotEmpty) {
                          final amount = double.tryParse(numericValue) ?? 0;
                          setState(() {
                            _discountAmount = amount;
                            _discountController.text =
                                FormatUtils.formatCurrency(amount);
                            _discountController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset: _discountController.text.length),
                            );
                          });
                        } else {
                          setState(() {
                            _discountAmount = 0;
                            _discountController.text = '0';
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Giao hàng và thanh toán
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        'Giao hàng và thanh toán',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    TextField(
                      controller: _shippingController,
                      decoration: const InputDecoration(
                        labelText: 'Phí ship (đ)',
                        border: OutlineInputBorder(),
                        helperText: 'Chi phí vận chuyển cho đơn hàng',
                        prefixIcon: Icon(Icons.local_shipping),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final numericValue =
                            value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (numericValue.isNotEmpty) {
                          final amount = double.tryParse(numericValue) ?? 0;
                          setState(() {
                            _shippingFee = amount;
                            _shippingController.text =
                                FormatUtils.formatCurrency(amount);
                            _shippingController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset: _shippingController.text.length),
                            );
                          });
                        } else {
                          setState(() {
                            _shippingFee = 0;
                            _shippingController.text = '0';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _additionalFeeController,
                      decoration: InputDecoration(
                        labelText: 'Chi phí khác (đ)',
                        border: const OutlineInputBorder(),
                        helperText: 'Chi phí bổ sung cho đơn hàng',
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Chỉnh sửa mô tả',
                          onPressed: () async {
                            final controller = TextEditingController(
                                text: _additionalFeeDescription);
                            final result = await showDialog<String>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Mô tả chi phí'),
                                content: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    labelText: 'Mô tả',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLength: 50,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Hủy'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, controller.text),
                                    child: const Text('Lưu'),
                                  ),
                                ],
                              ),
                            );
                            if (result != null && result.isNotEmpty) {
                              setState(() {
                                _additionalFeeDescription = result;
                              });
                            }
                          },
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final numericValue =
                            value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (numericValue.isNotEmpty) {
                          final amount = double.tryParse(numericValue) ?? 0;
                          setState(() {
                            _additionalFee = amount;
                            _additionalFeeController.text =
                                FormatUtils.formatCurrency(amount);
                            _additionalFeeController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset: _additionalFeeController.text.length),
                            );
                          });
                        } else {
                          setState(() {
                            _additionalFee = 0;
                            _additionalFeeController.text = '0';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Hình thức thanh toán',
                        border: OutlineInputBorder(),
                        helperText: 'Phương thức thanh toán cho đơn hàng',
                        prefixIcon: Icon(Icons.payment),
                      ),
                      value: _paymentMethod,
                      items: const [
                        DropdownMenuItem(
                          value: 'cash',
                          child: Text('Tiền mặt'),
                        ),
                        DropdownMenuItem(
                          value: 'transfer',
                          child: Text('Chuyển khoản'),
                        ),
                        DropdownMenuItem(
                          value: 'card',
                          child: Text('Thẻ'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _paymentMethod = value ?? 'cash');
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Hình thức giao hàng',
                        border: OutlineInputBorder(),
                        helperText: 'Phương thức giao hàng cho đơn hàng',
                        prefixIcon: Icon(Icons.delivery_dining),
                      ),
                      value: _deliveryMethod,
                      items: const [
                        DropdownMenuItem(
                          value: 'pickup',
                          child: Text('Lấy tại cửa hàng'),
                        ),
                        DropdownMenuItem(
                          value: 'delivery',
                          child: Text('Giao hàng'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _deliveryMethod = value ?? 'pickup');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đóng',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewCustomer() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm khách hàng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên khách hàng *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                _showMessage('Vui lòng nhập tên khách hàng', isError: true);
                return;
              }

              final customerId = await DatabaseHelper.instance.insertCustomer({
                'name': nameController.text,
                'phone': phoneController.text,
                'normalized_name': nameController.text.toLowerCase(),
              });

              if (!mounted) return;

              final newCustomer = Customer(
                id: customerId,
                name: nameController.text,
                phone: phoneController.text,
                address: addressController.text,
                normalizedName: nameController.text.toLowerCase(),
              );

              setState(() {
                _customers.add(newCustomer);
                _selectedCustomer = newCustomer;
              });

              Navigator.pop(context, true);
            },
            icon: Icon(
              Icons.person_add_outlined,
              size: ResponsiveUtils.getAdaptiveIconSize(context, 18),
            ),
            label: const Text(
              'Thêm',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      _showMessage('Đã thêm khách hàng mới');
    }
  }

  double get _subtotal {
    return _items.fold(0, (sum, item) => sum + item.total);
  }

  double get _tax {
    final taxPercent = double.tryParse(_taxController.text) ?? 0;
    return _subtotal * (taxPercent / 100);
  }

  double get _discount {
    return _discountAmount;
  }

  double get _total {
    return _subtotal + _tax - _discount + _shippingFee + _additionalFee;
  }

  void _updatePaymentAmount() {
    final subtotal = _items.fold<double>(0, (sum, item) => sum + item.total);
    final tax = subtotal * _taxPercent / 100;
    final total =
        subtotal + tax - _discountAmount + _shippingFee + _additionalFee;

    setState(() {
      _paymentAmount = total;
      _paymentController.text = FormatUtils.formatCurrency(total);
    });
  }

  Future<void> _saveOrder(bool isNewOrder) async {
    if (_items.isEmpty) {
      _showMessage('Vui lòng thêm mặt hàng', isError: true);
      return;
    }

    // Kiểm tra số lượng trong kho trước khi lưu
    for (final item in _items) {
      if (item.productId != null) {
        final product = _products.firstWhere((p) => p.id == item.productId);
        if (item.quantity > product.quantity) {
          _showMessage(
            'Sản phẩm "${item.name}" chỉ còn ${product.quantity} trong kho',
            isError: true,
          );
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper.instance;
      int? customerId;

      // Save customer if new
      if (_isNewCustomer && _customerNameController.text.isNotEmpty) {
        customerId = await db.insertCustomer({
          'name': _customerNameController.text,
          'phone': _customerPhoneController.text,
          'normalized_name': _customerNameController.text.toLowerCase(),
        });
      } else if (_selectedCustomer != null) {
        customerId = _selectedCustomer!.id;
      }

      final subtotal = _items.fold<double>(0, (sum, item) => sum + item.total);
      final tax = subtotal * _taxPercent / 100;
      final discount = _discountAmount;
      final total = subtotal + tax - discount + _shippingFee;

      // Kiểm tra xem đây có phải là đơn hàng đã tồn tại hay không
      int orderId;

      // Lưu trữ danh sách sản phẩm cũ và số lượng của chúng
      final Map<int, int> oldProductQuantities = {};

      if (_existingOrderId != null) {
        // Cập nhật đơn hàng đã tồn tại
        orderId = _existingOrderId!;

        // Lấy trạng thái đơn hàng hiện tại
        final currentOrder = await db.getOrder(orderId);
        final bool isCurrentOrderExchange =
            currentOrder['category'] == 'Đổi hàng' ||
                (currentOrder['is_exchanged'] != null &&
                    currentOrder['is_exchanged'] == 1);

        // Cập nhật đơn hàng
        await db.updateOrder(
          orderId,
          {
            'customer_id': customerId,
            'status': _paymentAmount >= total ? 'Hoàn tất' : 'Còn nợ',
            'total': total,
            'paid': _paymentAmount,
            'debt': total - _paymentAmount,
            'shipping_fee': _shippingFee,
            'additional_fee': _additionalFee,
            'additional_fee_description': _additionalFeeDescription,
            'discount_amount': discount,
            'tax_percent': _taxPercent,
            'note': _orderNote,
            'category': (widget.isExchange ||
                    _isExchangeOrder ||
                    isCurrentOrderExchange)
                ? 'Đổi hàng'
                : _orderCategory,
            'is_exchanged': (widget.isExchange ||
                    _isExchangeOrder ||
                    isCurrentOrderExchange)
                ? 1
                : 0,
          },
        );

        // Xóa các mặt hàng cũ trong đơn hàng
        final oldItems = await db.getOrderItems(orderId);

        // Lưu trữ thông tin sản phẩm cũ để so sánh sau này
        for (final oldItem in oldItems) {
          if (oldItem['product_id'] != null) {
            final int productId = oldItem['product_id'];
            final int quantity = oldItem['quantity'];

            // Lưu trữ số lượng sản phẩm cũ
            oldProductQuantities[productId] =
                (oldProductQuantities[productId] ?? 0) + quantity;

            // Cộng lại số lượng sản phẩm vào kho trước khi xóa
            await db.updateProductQuantity(productId, quantity);
          }

          // Xóa mặt hàng cũ
          await db.deleteOrderItem(oldItem['id']);
        }

        _showMessage('Cập nhật đơn hàng thành công');
      } else {
        // Tạo đơn hàng mới
        final Map<String, dynamic> orderData = {
          'customer_id': customerId,
          'date': DateTime.now().toIso8601String(),
          'status': _paymentAmount >= total ? 'Hoàn tất' : 'Còn nợ',
          'total': total,
          'paid': _paymentAmount,
          'debt': total - _paymentAmount,
          'shipping_fee': _shippingFee,
          'additional_fee': _additionalFee,
          'additional_fee_description': _additionalFeeDescription,
          'discount_amount': discount,
          'tax_percent': _taxPercent,
          'note': _orderNote,
          'category': widget.isExchange ? 'Đổi hàng' : _orderCategory,
        };

        // Đánh dấu đơn hàng là đơn đổi hàng nếu cần
        if (widget.isExchange) {
          orderData['is_exchanged'] = 1;
        }

        orderId = await db.insertOrder(orderData);
      }

      // Thêm các mặt hàng mới vào đơn hàng
      for (final item in _items) {
        // Thêm mặt hàng vào đơn hàng
        final Map<String, dynamic> orderItemData = {
          'order_id': orderId,
          'product_id': item.productId,
          'name': item.name,
          'quantity': item.quantity,
          'price': item.price,
          'cost_price': item.costPrice,
          'attributes': jsonEncode(item.attributes),
        };

        // Đánh dấu sản phẩm đã được đổi nếu đây là đơn đổi hàng
        if (widget.isExchange || _isExchangeOrder) {
          orderItemData['is_exchanged'] = 1;
          orderItemData['exchange_count'] = 1;
          orderItemData['original_price'] = item.price; // Lưu giá gốc ban đầu
        }

        await db.insertOrderItem(orderItemData);

        // Cập nhật số lượng sản phẩm trong kho
        if (item.productId != null) {
          // Tính toán số lượng cần trừ từ kho
          int quantityToDeduct = item.quantity;

          // Nếu sản phẩm này đã có trong đơn hàng cũ, chỉ trừ số lượng chênh lệch
          if (oldProductQuantities.containsKey(item.productId)) {
            final int oldQuantity = oldProductQuantities[item.productId]!;
            final int quantityDiff = item.quantity - oldQuantity;

            // Chỉ cập nhật kho nếu có sự thay đổi về số lượng
            if (quantityDiff != 0) {
              await db.updateProductQuantity(item.productId!, -quantityDiff);
            }

            // Xóa sản phẩm đã xử lý khỏi danh sách cũ
            oldProductQuantities.remove(item.productId);
          } else {
            // Sản phẩm mới, trừ toàn bộ số lượng
            await db.updateProductQuantity(item.productId!, -quantityToDeduct);
          }
        }
      }

      // Xử lý các sản phẩm cũ đã bị xóa khỏi đơn hàng
      // (các sản phẩm còn lại trong oldProductQuantities)
      if (oldProductQuantities.isNotEmpty) {
        // Các sản phẩm này đã được cộng lại vào kho ở bước trước, không cần làm gì thêm
        _showMessage(
            '${oldProductQuantities.length} sản phẩm đã bị xóa khỏi đơn hàng');
      }

      // Tự động tạo khoản chi tiêu vận chuyển nếu có phí ship
      // Chỉ tạo khoản chi tiêu mới nếu là đơn hàng mới hoặc đơn hàng cũ không có phí ship
      if (_shippingFee > 0 &&
          (_existingOrderId == null ||
              (_initialOrderState != null &&
                  (_initialOrderState!['shipping_fee'] ?? 0) == 0))) {
        final expense = {
          'date': DateTime.now().toIso8601String(),
          'description': 'Phí vận chuyển đơn hàng #$orderId',
          'amount': _shippingFee,
          'category': 'Phí vận chuyển',
        };
        await db.insertExpense(expense);
      }

      // Tự động tạo khoản chi tiêu cho chi phí bổ sung nếu có
      // Chỉ tạo khoản chi tiêu mới nếu là đơn hàng mới hoặc đơn hàng cũ không có chi phí bổ sung
      if (_additionalFee > 0 &&
          (_existingOrderId == null ||
              (_initialOrderState != null &&
                  (_initialOrderState!['additional_fee'] ?? 0) == 0))) {
        final expense = {
          'date': DateTime.now().toIso8601String(),
          'description': '$_additionalFeeDescription - đơn hàng #$orderId',
          'amount': _additionalFee,
          'category': 'Chi phí khác',
        };
        await db.insertExpense(expense);
      }

      // Cập nhật công nợ khách hàng nếu cần
      if (customerId != null) {
        if (_existingOrderId != null && _initialOrderState != null) {
          // Nếu là đơn hàng đã tồn tại, cập nhật chênh lệch công nợ
          final oldDebt = _initialOrderState!['debt'] ?? 0.0;
          final newDebt = total - _paymentAmount;
          final debtDiff = newDebt - oldDebt;

          if (debtDiff != 0) {
            await db.updateCustomerDebt(customerId, debtDiff);
          }
        } else if (total - _paymentAmount > 0) {
          // Nếu là đơn hàng mới và có nợ
          await db.updateCustomerDebt(customerId, total - _paymentAmount);
        }
      }

      // Xử lý đặc biệt cho đơn hàng đổi
      if (widget.isExchange || _isExchangeOrder) {
        final oldOrderTotal =
            widget.oldOrderTotal ?? (_initialOrderState?['total'] ?? 0.0);
        final newOrderTotal = total;
        final paidAmount = _paymentAmount;

        // Tính toán chênh lệch giá trị giữa đơn hàng mới và đơn hàng cũ
        final double priceDifference = newOrderTotal - oldOrderTotal;

        // Xử lý các trường hợp khác nhau dựa trên chênh lệch giá trị
        if (priceDifference > 0) {
          // Trường hợp 1: Đơn hàng mới có giá trị cao hơn đơn hàng cũ
          // Khách hàng cần thanh toán thêm

          // Tính tỷ lệ thanh toán của đơn hàng cũ
          final double paymentRatio =
              oldOrderTotal > 0 ? paidAmount / oldOrderTotal : 1.0;

          // Tính toán doanh thu và lợi nhuận
          final double costTotal = _items.fold<double>(
              0, (sum, item) => sum + (item.costPrice * item.quantity));

          // Nếu đã thanh toán đủ đơn hàng cũ
          if (paymentRatio >= 1) {
            // Cập nhật doanh thu và lợi nhuận theo đơn hàng mới
            await db.updateOrderRevenue(orderId, {
              'revenue': newOrderTotal,
              'profit': newOrderTotal - costTotal,
            });
          } else {
            // Nếu chưa thanh toán đủ, tính theo tỷ lệ
            final double adjustedRevenue = oldOrderTotal * paymentRatio +
                priceDifference * _paymentAmount / priceDifference;
            final double adjustedProfit =
                adjustedRevenue - (costTotal * adjustedRevenue / newOrderTotal);

            await db.updateOrderRevenue(orderId, {
              'revenue': adjustedRevenue,
              'profit': adjustedProfit,
            });
          }
        } else if (priceDifference < 0) {
          // Trường hợp 2: Đơn hàng mới có giá trị thấp hơn đơn hàng cũ
          // Cần hoàn tiền cho khách hàng

          // Tính toán số tiền cần hoàn
          final double refundAmount = -priceDifference; // Chuyển thành số dương

          // Tính toán doanh thu và lợi nhuận sau khi hoàn tiền
          final double costTotal = _items.fold<double>(
              0, (sum, item) => sum + (item.costPrice * item.quantity));
          final double revenue = newOrderTotal;
          final double profit = revenue - costTotal;

          // Cập nhật doanh thu và lợi nhuận
          await db.updateOrderRevenue(orderId, {
            'revenue': revenue,
            'profit': profit,
            'refund_amount': refundAmount,
            'refund_date': DateTime.now().toIso8601String(),
            'refund_reason': 'Hoàn tiền chênh lệch khi đổi hàng',
          });

          // Hiển thị thông báo về số tiền cần hoàn
          _showMessage(
              'Cần hoàn trả khách hàng ${FormatUtils.formatCurrency(refundAmount)}');
        } else {
          // Trường hợp 3: Đơn hàng mới có giá trị bằng đơn hàng cũ
          // Không cần thanh toán thêm hoặc hoàn tiền

          // Tính toán doanh thu và lợi nhuận
          final double costTotal = _items.fold<double>(
              0, (sum, item) => sum + (item.costPrice * item.quantity));

          // Cập nhật doanh thu và lợi nhuận
          await db.updateOrderRevenue(orderId, {
            'revenue': newOrderTotal,
            'profit': newOrderTotal - costTotal,
          });
        }

        // Đánh dấu đơn hàng là đơn đổi hàng
        await db.updateOrder(orderId, {
          'category': 'Đổi hàng',
          'is_exchanged': 1,
        });
      }

      if (!mounted) return;

      if (isNewOrder) {
        // Reload lại dữ liệu sản phẩm
        final products = await DatabaseHelper.instance.getProducts();

        // Reset form để tạo đơn hàng mới
        setState(() {
          // Cập nhật danh sách sản phẩm
          _products = products.map((p) => Product.fromMap(p)).toList();

          _items.clear();
          _customerNameController.clear();
          _customerPhoneController.clear();
          _selectedCustomer = null;
          _isNewCustomer = true;
          _paymentController.text = '0';
          _paymentAmount = 0;
          _hasUserEditedPayment = false;
          _orderNote = '';
          _orderCategory = 'Bán lẻ';
          _taxController.text = '0';
          _taxPercent = 0;
          _discountController.text = '0';
          _discountAmount = 0;
          _shippingController.text = '0';
          _shippingFee = 0;
          _paymentMethod = 'cash';
          _deliveryMethod = 'pickup';

          // Reset các biến liên quan đến đơn hàng cũ
          _existingOrderId = null;
          _initialOrderState = null;
          _initialItems = null;
        });
        _showMessage('Đã lưu đơn hàng. Tiếp tục tạo đơn mới.');
      } else {
        // Hiển thị thông báo trước khi thoát form
        _showMessage('Đã hoàn tất đơn hàng');
        // Thoát form nếu là "Hoàn tất"
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Lỗi: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => const HelpDialog(),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ToastOverlay.show(
      context,
      message: message,
      isError: isError,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstRun) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_items.isNotEmpty) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Hủy đơn hàng?'),
              content: const Text(
                  'Bạn có muốn hủy đơn hàng này không?\nMọi thay đổi sẽ không được lưu.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Tiếp tục'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Hủy đơn'),
                ),
              ],
            ),
          );

          if (shouldPop == true) {
            return true;
          }
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('Tạo đơn hàng'),
              if (_isExchangeOrder || widget.isExchange)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Đổi hàng',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Hướng dẫn',
              onPressed: _showHelp,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Tùy chọn',
              onPressed: _showOptions,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _customerNameController,
                                  focusNode: _customerNameFocusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Tên khách hàng',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: (value) {
                                    setState(() {
                                      _isNewCustomer = true;
                                      _selectedCustomer = null;
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.people),
                                tooltip: 'Chọn từ danh sách',
                                onPressed: () async {
                                  final selected = await showDialog<Customer>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Chọn khách hàng'),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: _customers.length,
                                          itemBuilder: (context, index) {
                                            final customer = _customers[index];
                                            return ListTile(
                                              title: Text(customer.name),
                                              subtitle: customer.phone != null
                                                  ? Text(customer.phone!)
                                                  : null,
                                              onTap: () => Navigator.pop(
                                                  context, customer),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                  if (selected != null) {
                                    setState(() {
                                      _selectedCustomer = selected;
                                      _isNewCustomer = false;
                                      _customerNameController.text =
                                          selected.name;
                                      _customerPhoneController.text =
                                          selected.phone ?? '';
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customerPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Số điện thoại',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  focusNode: _addProductFocusNode,
                                  onPressed: _addItem,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text(
                                    'Thêm sản phẩm',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _addTemporaryItem,
                                  icon: const Icon(Icons.add_circle_outline,
                                      size: 18),
                                  label: const Text(
                                    'Nhập hàng mới',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: ResponsiveUtils.getAdaptiveIconSize(
                                        context, 64),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.5),
                                  ),
                                  SizedBox(
                                      height:
                                          ResponsiveUtils.getAdaptiveSpacing(
                                              context, 16)),
                                  Text(
                                    'Chưa có sản phẩm nào',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(
                                  ResponsiveUtils.getAdaptiveSpacing(
                                      context, 16)),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return Card(
                                  child: ListTile(
                                    title: Text(item.name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () =>
                                                  _updateItemQuantity(item, -1),
                                            ),
                                            Text('${item.quantity}'),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () =>
                                                  _updateItemQuantity(item, 1),
                                            ),
                                            const Spacer(),
                                            Text(FormatUtils.formatCurrency(
                                                item.total)),
                                          ],
                                        ),
                                        if (item.productId != null)
                                          Text(
                                            'Còn ${_products.firstWhere((p) => p.id == item.productId).quantity - item.quantity} trong kho',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _removeItem(item),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (_items.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(
                            ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        child: Column(
                          children: [
                            _buildTotalSection(),
                            SizedBox(
                                height: ResponsiveUtils.getAdaptiveSpacing(
                                    context, 16)),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _saveOrder(false),
                                    icon: _isLoading
                                        ? SizedBox(
                                            width: ResponsiveUtils
                                                .getAdaptiveIconSize(
                                                    context, 20),
                                            height: ResponsiveUtils
                                                .getAdaptiveIconSize(
                                                    context, 20),
                                            child:
                                                const CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            Icons.check_circle_outline,
                                            size: ResponsiveUtils
                                                .getAdaptiveIconSize(
                                                    context, 18),
                                          ),
                                    label: Text(
                                      'Hoàn tất',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize:
                                            ResponsiveUtils.getAdaptiveFontSize(
                                                context, 14),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width: ResponsiveUtils.getAdaptiveSpacing(
                                        context, 16)),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _saveOrder(true),
                                    icon: Icon(
                                      Icons.shopping_bag_outlined,
                                      size: ResponsiveUtils.getAdaptiveIconSize(
                                          context, 18),
                                    ),
                                    label: Text(
                                      'Đơn khác',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize:
                                            ResponsiveUtils.getAdaptiveFontSize(
                                                context, 14),
                                      ),
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
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.primary,
            indicatorColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.primary.withAlpha(51)
                : Colors.white.withAlpha(51),
            elevation: 2,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                    color: isDark
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white);
              }
              return TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.white70);
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(
                    color: isDark
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white);
              }
              return IconThemeData(
                  color: isDark ? Colors.grey[400] : Colors.white70);
            }),
          ),
          child: NavigationBar(
            selectedIndex: 0, // Inventory tab selected
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              if (index != 0) {
                // If not the current tab
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return HomeScreen(initialPage: index);
                    },
                  ),
                );
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.inventory),
                selectedIcon: Icon(Icons.inventory),
                label: 'Kho Hàng',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Báo Cáo',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                selectedIcon: Icon(Icons.settings),
                label: 'Cài Đặt',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    final subtotal = CalculationUtils.calculateSubtotal(_items);
    final tax = CalculationUtils.calculateTax(subtotal, _taxPercent);
    final discount =
        CalculationUtils.calculateDiscount(subtotal, _discountAmount);
    // Tính tổng tiền bao gồm cả chi phí bổ sung
    final total = subtotal + tax - discount + _shippingFee + _additionalFee;

    if (!_hasUserEditedPayment) {
      _paymentAmount = total;
      _paymentController.text = FormatUtils.formatCurrency(total);
    }

    // Tính toán số tiền còn nợ hoặc thừa
    // CalculationUtils.calculateDebt(
    //   total: total,
    //   paid: _paymentAmount,
    // );

    return Card(
      child: Padding(
        padding:
            EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tạm tính:',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                  ),
                ),
                Text(
                  FormatUtils.formatCurrency(subtotal),
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                  ),
                ),
              ],
            ),
            if (_taxPercent > 0) ...[
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Thuế (${_taxPercent.toStringAsFixed(1)}%):'),
                  Text(FormatUtils.formatCurrency(tax)),
                ],
              ),
            ],
            if (_discountAmount > 0) ...[
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Giảm giá:'),
                  Text('-${FormatUtils.formatCurrency(discount)}'),
                ],
              ),
            ],
            if (_shippingFee > 0) ...[
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Phí ship:'),
                  Text(FormatUtils.formatCurrency(_shippingFee)),
                ],
              ),
            ],
            if (_additionalFee > 0) ...[
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_additionalFeeDescription:'),
                  Text(FormatUtils.formatCurrency(_additionalFee)),
                ],
              ),
            ],
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng cộng:'),
                Text(FormatUtils.formatCurrency(total)),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            TextField(
              controller: _paymentController,
              decoration: InputDecoration(
                labelText: 'Số tiền thanh toán',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 24)),
                labelStyle: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _hasUserEditedPayment = true;
                final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                final payment = double.tryParse(numericValue) ?? 0;

                // Lưu vị trí con trỏ hiện tại
                final cursorPosition = _paymentController.selection.baseOffset;

                // Đếm số ký tự dấu phân cách phía trước con trỏ trong chuỗi cũ
                final oldValue = _paymentController.text;
                final oldDotCount = '.'
                    .allMatches(oldValue.substring(0, cursorPosition))
                    .length;

                // Cập nhật giá trị mới với định dạng
                final formattedValue = FormatUtils.formatCurrency(payment);
                _paymentController.value = TextEditingValue(
                  text: formattedValue,
                  selection: TextSelection.collapsed(
                    // Tính toán vị trí con trỏ mới dựa trên số dấu phân cách
                    offset: cursorPosition +
                        ('.'
                                .allMatches(formattedValue.substring(
                                    0, cursorPosition + 1))
                                .length -
                            oldDotCount),
                  ),
                );

                setState(() {
                  _paymentAmount = payment;
                });
              },
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isExchange && _total < (widget.oldOrderTotal ?? 0)
                      ? 'Phải hoàn:'
                      : _total > _paymentAmount
                          ? 'Còn nợ:'
                          : 'Thừa:',
                  style: TextStyle(
                    color: widget.isExchange &&
                            _total < (widget.oldOrderTotal ?? 0)
                        ? Theme.of(context).colorScheme.primary
                        : _total > _paymentAmount
                            ? Theme.of(context).colorScheme.error
                            : Colors.orange[700],
                  ),
                ),
                Text(
                  FormatUtils.formatCurrency(
                      widget.isExchange && _total < (widget.oldOrderTotal ?? 0)
                          ? (widget.oldOrderTotal ?? 0) -
                              _total // Số tiền cần hoàn trả
                          : _total - _paymentAmount // Số tiền còn nợ hoặc thừa
                      ),
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                    color: widget.isExchange &&
                            _total < (widget.oldOrderTotal ?? 0)
                        ? Theme.of(context).colorScheme.primary
                        : _total > _paymentAmount
                            ? Theme.of(context).colorScheme.error
                            : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _paymentController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    _shippingController.dispose();
    _additionalFeeController.dispose();
    _customerNameFocusNode.dispose();
    _addProductFocusNode.dispose();
    super.dispose();
  }
}
