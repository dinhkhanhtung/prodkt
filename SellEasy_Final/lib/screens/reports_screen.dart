import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/expense.dart';
import '../models/customer.dart';
import '../services/database_helper.dart';
import '../services/pdf_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../utils/calculation_utils.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'forms/create_order_form.dart';
import '../utils/format_utils.dart';
import '../utils/toast_helper.dart';
import '../widgets/order_detail_dialog.dart';
import '../utils/dialog_helper.dart';
import '../utils/responsive_utils.dart';

String formatCurrency(double amount) {
  return amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          ) +
      'đ';
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _timeRange = 'month';
  String _orderTimeRange = 'month';
  String _expenseTimeRange = 'month';
  String? _expenseCategory;
  String? _orderCategory;
  String _selectedYear = DateTime.now().year.toString();
  String _selectedOrderYear = DateTime.now().year.toString();
  String _selectedExpenseYear = DateTime.now().year.toString();
  bool _showPlainText = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  List<Map<String, dynamic>> _filteredExpenses = [];
  Map<String, dynamic> _summary = {
    'total_revenue': 0.0,
    'total_expenses': 0.0,
    'total_debt': 0.0,
    'total_refunds': 0.0,
    'net_profit': 0.0,
  };
  String _orderFilter = 'all';
  String _expenseType = 'all';
  bool _showAllOrders = false;
  bool _showOrderFilters = false;
  bool _showExpenseFilters = false;
  TextEditingController _yearController = TextEditingController();
  TextEditingController _orderYearController = TextEditingController();
  TextEditingController _expenseYearController = TextEditingController();
  Timer? _loadDataTimer;
  bool _showDetailedFinancials = false; // Add this line
  bool _showSummaryBoxes = true;
  bool _showCharts = true;
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _lowStockProducts = [];
  int _newCustomersToday = 0;
  int _totalInventory = 0;
  bool _showAllExpenses = false;
  double _refundAmount = 0;
  String _refundReason = '';

  List<String> get _years {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => (currentYear - index).toString());
  }

  @override
  void initState() {
    super.initState();
    _yearController.text = _selectedYear;
    _orderYearController.text = _selectedOrderYear;
    _expenseYearController.text = _selectedExpenseYear;
    _loadData();

    // Thêm timer để tự động cập nhật dữ liệu mỗi 5 giây
    _loadDataTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _loadDataTimer?.cancel();
    _yearController.dispose();
    _orderYearController.dispose();
    _expenseYearController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    // Filter orders based on time range and year
    _filteredOrders = _orders.where((order) {
      final orderDate = DateTime.parse(order['date']);
      final selectedYear = int.parse(_selectedOrderYear);

      if (orderDate.year != selectedYear) return false;

      final now = DateTime.now();
      switch (_orderTimeRange) {
        case 'today':
          return orderDate.year == now.year &&
              orderDate.month == now.month &&
              orderDate.day == now.day;
        case 'week':
          final weekAgo = now.subtract(const Duration(days: 7));
          return orderDate.isAfter(weekAgo);
        case 'month':
          return orderDate.year == now.year && orderDate.month == now.month;
        default:
          return true;
      }
    }).toList();

    // Filter expenses based on time range and year
    _filteredExpenses = _expenses.where((expense) {
      final expenseDate = DateTime.parse(expense['date']);
      final selectedYear = int.parse(_selectedExpenseYear);

      if (expenseDate.year != selectedYear) return false;

      final now = DateTime.now();
      switch (_expenseTimeRange) {
        case 'today':
          return expenseDate.year == now.year &&
              expenseDate.month == now.month &&
              expenseDate.day == now.day;
        case 'week':
          final weekAgo = now.subtract(const Duration(days: 7));
          return expenseDate.isAfter(weekAgo);
        case 'month':
          return expenseDate.year == now.year && expenseDate.month == now.month;
        default:
          return true;
      }
    }).toList();

    // Calculate filtered summary with corrected profit calculation
    final totalRevenue = _filteredOrders.fold(0.0, (sum, order) {
      if ((order['status'] == 'Hoàn tất' || order['status'] == 'Còn nợ') &&
          order['status'] != 'Đã hủy') {
        // Tính doanh thu thực = số tiền đã trả - số tiền hoàn
        final paid = (order['paid'] as num?)?.toDouble() ?? 0.0;
        final refundAmount =
            (order['refund_amount'] as num?)?.toDouble() ?? 0.0;
        final actualRevenue = paid - refundAmount;
        return sum + actualRevenue;
      }
      return sum;
    });

    final totalShipping = _filteredOrders.fold(0.0, (sum, order) {
      if ((order['status'] == 'Hoàn tất' || order['status'] == 'Còn nợ') &&
          order['status'] != 'Đã hủy') {
        // Calculate shipping fee based on actual payment ratio
        final actualPaid = (order['paid'] ?? 0) - (order['refund_amount'] ?? 0);
        final paymentRatio =
            order['total'] > 0 ? actualPaid / order['total'] : 0;
        return sum + ((order['shipping_fee'] ?? 0) * paymentRatio);
      }
      return sum;
    });

    final totalDiscount = _filteredOrders.fold(0.0, (sum, order) {
      if ((order['status'] == 'Hoàn tất' || order['status'] == 'Còn nợ') &&
          order['status'] != 'Đã hủy') {
        // Calculate discount based on actual payment ratio
        final actualPaid = (order['paid'] ?? 0) - (order['refund_amount'] ?? 0);
        final paymentRatio =
            order['total'] > 0 ? actualPaid / order['total'] : 0;
        return sum + ((order['discount_amount'] ?? 0) * paymentRatio);
      }
      return sum;
    });

    // Calculate total cost from order items based on actual payment ratio
    final totalCost = _filteredOrders.fold(0.0, (sum, order) {
      if ((order['status'] == 'Hoàn tất' || order['status'] == 'Còn nợ') &&
          order['status'] != 'Đã hủy') {
        final items = order['items'] as List<dynamic>;
        double orderCost = 0.0;
        for (var item in items) {
          orderCost += (item['cost_price'] ?? 0) * (item['quantity'] ?? 0);
        }
        // Calculate cost based on actual payment ratio
        final actualPaid = (order['paid'] ?? 0) - (order['refund_amount'] ?? 0);
        final paymentRatio =
            order['total'] > 0 ? actualPaid / order['total'] : 0;
        return sum + (orderCost * paymentRatio);
      }
      return sum;
    });

    final totalDebt = _filteredOrders.fold(0.0, (sum, order) {
      if ((order['status'] == 'Còn nợ' || order['debt'] > 0) &&
          order['status'] != 'Đã hủy') {
        // Tính công nợ thực = công nợ gốc - số tiền hoàn (nếu có)
        final actualDebt = (order['debt'] ?? 0) - (order['refund_amount'] ?? 0);
        return sum + (actualDebt > 0 ? actualDebt : 0);
      }
      return sum;
    });

    // Calculate total expenses including shipping fees
    final totalExpenses = _filteredExpenses.fold(
        0.0, (sum, expense) => sum + (expense['amount'] ?? 0));

    // Calculate net profit = Revenue - Cost - Expenses - Discount
    // Note: No need to subtract refunds as they are already deducted from revenue
    final double netProfit =
        totalRevenue - totalCost - totalExpenses - totalDiscount;

    _summary = {
      'total_revenue': totalRevenue,
      'total_shipping': totalShipping,
      'total_discount': totalDiscount,
      'total_cost': totalCost,
      'total_expenses': totalExpenses,
      'total_debt': totalDebt,
      'net_profit': netProfit,
    };

    setState(() {}); // Trigger UI update
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final orders = await DatabaseHelper.instance.getOrders();
      final expenses = await DatabaseHelper.instance.getExpenses();
      final products = await DatabaseHelper.instance.getProducts();
      final customers = await DatabaseHelper.instance.getCustomers();

      // Tải thông tin chi tiết đơn hàng
      List<Map<String, dynamic>> ordersWithItems = [];
      for (var order in orders) {
        final items = await DatabaseHelper.instance.getOrderItems(order['id']);
        ordersWithItems.add({
          ...order,
          'items': items,
        });
      }

      // Tính toán sản phẩm bán chạy
      Map<String, int> productSales = {};
      for (var order in ordersWithItems) {
        if (order['status'] != 'Đã hoàn tiền') {
          for (var item in order['items']) {
            final quantity = (item['quantity'] is int
                    ? item['quantity']
                    : int.tryParse(item['quantity']?.toString() ?? '0') ?? 0)
                as int;
            final productId = item['product_id']?.toString() ?? '';
            if (productId.isNotEmpty) {
              productSales[productId] =
                  (productSales[productId] ?? 0) + quantity;
            }
          }
        }
      }

      // Chuyển đổi và lọc sản phẩm bán chạy
      _topProducts = productSales.entries
          .map((e) {
            final product = products.firstWhere(
                (p) => p['id'].toString() == e.key,
                orElse: () => {});
            return product.isNotEmpty ? {...product, 'sales': e.value} : null;
          })
          .where((p) => p != null)
          .toList()
          .cast<Map<String, dynamic>>();

      _topProducts.sort((a, b) =>
          ((b['sales'] ?? 0) as int).compareTo((a['sales'] ?? 0) as int));
      if (_topProducts.length > 5) {
        _topProducts = _topProducts.sublist(0, 5);
      }

      // Tính toán sản phẩm sắp hết
      _lowStockProducts = products.where((p) {
        final quantity = (p['quantity'] is int
            ? p['quantity']
            : int.tryParse(p['quantity']?.toString() ?? '0') ?? 0) as int;
        return quantity <= 10;
      }).toList();

      // Tính số khách mới trong ngày
      final today = DateTime.now();
      _newCustomersToday = customers.where((c) {
        try {
          final customerDate =
              DateTime.parse(c['created_at']?.toString() ?? '');
          return customerDate.year == today.year &&
              customerDate.month == today.month &&
              customerDate.day == today.day;
        } catch (e) {
          return false;
        }
      }).length;

      // Tính tổng tồn kho
      _totalInventory = products.fold<int>(0, (sum, p) {
        final quantity = (p['quantity'] is int
            ? p['quantity']
            : int.tryParse(p['quantity']?.toString() ?? '0') ?? 0) as int;
        return sum + quantity;
      });

      if (mounted) {
        setState(() {
          _orders = ordersWithItems;
          _expenses = expenses;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ToastHelper.showError(
            context, 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _refreshData() async {
    try {
      final orders = await DatabaseHelper.instance.getOrders();
      final expenses = await DatabaseHelper.instance.getExpenses();

      // Tải thông tin chi tiết đơn hàng
      List<Map<String, dynamic>> ordersWithItems = [];
      for (var order in orders) {
        final items = await DatabaseHelper.instance.getOrderItems(order['id']);
        ordersWithItems.add({
          ...order,
          'items': items,
        });
      }

      if (mounted) {
        setState(() {
          _orders = ordersWithItems;
          _expenses = expenses;
          _applyFilters();
        });
      }
    } catch (e) {
      print('Error refreshing data: $e');
      if (mounted) {
        ToastHelper.showError(
            context, 'Đã xảy ra lỗi khi cập nhật dữ liệu. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _showOrderYearPicker() async {
    final currentYear = DateTime.now().year;
    // Generate years list from 5 years ago to 5 years in the future
    final years =
        List.generate(11, (index) => (currentYear - 5 + index).toString());

    await DialogHelper.showAnimatedDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn năm cho đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _orderYearController,
              decoration: const InputDecoration(
                labelText: 'Nhập năm',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('Hoặc chọn năm:'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.maxFinite,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: years
                    .map((year) => InkWell(
                          onTap: () {
                            setState(() {
                              _selectedOrderYear = year;
                              _orderYearController.text = year;
                            });
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: year == _selectedOrderYear
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1)
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              year,
                              style: TextStyle(
                                color: year == _selectedOrderYear
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: year == _selectedOrderYear
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final year = int.tryParse(_orderYearController.text);
              if (year != null && year >= 1900 && year <= 2100) {
                setState(() => _selectedOrderYear = year.toString());
                Navigator.pop(context);
                _applyFilters();
              } else {
                ToastHelper.showError(context, 'Năm không hợp lệ');
              }
            },
            child: const Text('Chọn'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExpenseYearPicker() async {
    final currentYear = DateTime.now().year;
    // Generate years list from 5 years ago to 5 years in the future
    final years =
        List.generate(11, (index) => (currentYear - 5 + index).toString());

    await DialogHelper.showAnimatedDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn năm cho chi tiêu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _expenseYearController,
              decoration: const InputDecoration(
                labelText: 'Nhập năm',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('Hoặc chọn năm:'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.maxFinite,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: years
                    .map((year) => InkWell(
                          onTap: () {
                            setState(() {
                              _selectedExpenseYear = year;
                              _expenseYearController.text = year;
                            });
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: year == _selectedExpenseYear
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              year,
                              style: TextStyle(
                                color: year == _selectedExpenseYear
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.black87,
                                fontWeight: year == _selectedExpenseYear
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final year = int.tryParse(_expenseYearController.text);
              if (year != null && year >= 1900 && year <= 2100) {
                setState(() => _selectedExpenseYear = year.toString());
                Navigator.pop(context);
                _applyFilters();
              } else {
                ToastHelper.showError(context, 'Năm không hợp lệ');
              }
            },
            child: const Text('Chọn'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (isError) {
      ToastHelper.showError(context, message);
    } else {
      ToastHelper.showSuccess(context, message);
    }
  }

  Future<void> _processDebtPayment(
      Map<String, dynamic> order, double amount) async {
    try {
      final newDebt = order['debt'] - amount;
      final newPaid = order['paid'] + amount;

      // Cập nhật trạng thái đơn hàng thành "Hoàn tất" nếu đã trả hết nợ
      final Map<String, dynamic> updateData = {
        'debt': newDebt,
        'paid': newPaid,
      };

      // Nếu đã trả hết nợ, cập nhật trạng thái thành "Hoàn tất"
      if (newDebt <= 0) {
        updateData['status'] = 'Hoàn tất';
      }

      await DatabaseHelper.instance.updateOrder(
        order['id'],
        updateData,
      );

      if (order['customer_id'] != null) {
        await DatabaseHelper.instance.updateCustomerDebt(
          order['customer_id'],
          -amount,
        );
      }

      // Refresh data before closing dialog
      await _refreshData();

      if (!mounted) return;
      Navigator.pop(context);

      final message = newDebt <= 0
          ? 'Đã thanh toán hết nợ và hoàn tất đơn hàng'
          : 'Đã trả ${FormatUtils.formatCurrency(amount)}';
      _showMessage(message);
    } catch (e) {
      _showMessage(
          'Không thể xử lý thanh toán nợ. Vui lòng kiểm tra lại và thử lại sau.',
          isError: true);
    }
  }

  Future<void> _completeOrder(Map<String, dynamic> order) async {
    try {
      final db = DatabaseHelper.instance;
      await db.updateOrder(
        order['id'],
        {
          'status': 'Hoàn tất',
          'paid': order['total'],
          'debt': 0,
        },
      );

      // Refresh data before closing dialog
      await _refreshData();

      if (!mounted) return;
      Navigator.pop(context);

      _showMessage('Đã hoàn tất đơn hàng');
    } catch (e) {
      _showMessage('Lỗi: ${e.toString()}', isError: true);
    }
  }

  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    try {
      final db = DatabaseHelper.instance;

      // Update order status and reset financial values
      await db.updateOrder(
        order['id'],
        {
          'status': 'Đã hủy',
          'cancelled_at': DateTime.now().toIso8601String(),
          'total': 0,
          'paid': 0,
          'debt': 0,
          'revenue': 0,
          'profit': 0,
        },
      );

      // Return products to inventory
      final items = await db.getOrderItems(order['id']);
      for (final item in items) {
        if (item['product_id'] != null) {
          await db.updateProductQuantity(
            item['product_id'],
            item['quantity'],
          );
        }
      }

      // Remove shipping fee expense if exists
      if (order['shipping_fee'] > 0) {
        await db.deleteExpenseByDescription(
            'Phí vận chuyển đơn hàng #${order['id']}');
      }

      // Remove additional fee expense if exists
      if (order['additional_fee'] > 0) {
        final additionalFeeDescription =
            order['additional_fee_description'] ?? 'Chi phí khác';
        await db.deleteExpenseByDescription(
            '$additionalFeeDescription - đơn hàng #${order['id']}');
      }

      // Update customer debt if needed
      if (order['customer_id'] != null && order['debt'] > 0) {
        await db.updateCustomerDebt(
          order['customer_id'],
          -order['debt'],
        );
      }

      await _refreshData();
      if (!mounted) return;
      Navigator.pop(context);
      _showMessage('Đã hủy đơn hàng và cập nhật dữ liệu liên quan');
    } catch (e) {
      _showMessage('Lỗi: ${e.toString()}', isError: true);
    }
  }

  Future<void> _returnOrder(Map<String, dynamic> order) async {
    try {
      // Update order status
      await DatabaseHelper.instance.updateOrder(
        order['id'],
        {
          'status': 'Đã trả hàng',
          'returned_at': DateTime.now().toIso8601String(),
        },
      );

      // Return products to inventory
      final items = await DatabaseHelper.instance.getOrderItems(order['id']);
      for (final item in items) {
        final product =
            await DatabaseHelper.instance.getProduct(item['product_id']);
        if (product != null) {
          await DatabaseHelper.instance.updateProduct(
            item['product_id'],
            {
              'quantity': product['quantity'] + item['quantity'],
            },
          );
        }
      }

      await _refreshData();
      if (!mounted) return;
      Navigator.pop(context);
      _showMessage('Đã hoàn trả đơn hàng và cập nhật kho');
    } catch (e) {
      _showMessage('Lỗi: ${e.toString()}', isError: true);
    }
  }

  Future<void> _showDebtPaymentDialog(Map<String, dynamic> order) async {
    final debtController = TextEditingController(
      text: FormatUtils.formatCurrency(
          order['debt']), // Set default value to current debt
    );
    bool isProcessing = false;

    await DialogHelper.showAnimatedDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thanh toán công nợ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Số nợ hiện tại: ${FormatUtils.formatCurrency(order['debt'])}'),
            const SizedBox(height: 16),
            TextField(
              controller: debtController,
              decoration: const InputDecoration(
                labelText: 'Số tiền thanh toán',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (numericValue.isNotEmpty) {
                  final amount = double.tryParse(numericValue) ?? 0;
                  debtController.text = FormatUtils.formatCurrency(amount);
                  debtController.selection = TextSelection.fromPosition(
                    TextPosition(offset: debtController.text.length),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: isProcessing ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: isProcessing
                ? null
                : () async {
                    final amount = _parseDebtInput(debtController.text);
                    if (amount == null || amount <= 0) {
                      _showMessage('Số tiền không hợp lệ', isError: true);
                      return;
                    }
                    if (amount > order['debt']) {
                      _showMessage('Số tiền vượt quá số nợ', isError: true);
                      return;
                    }

                    setState(() => isProcessing = true);
                    await _processDebtPayment(order, amount);
                  },
            icon: const Icon(Icons.payment),
            label: const Text('Thanh toán'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRefundDialog(Map<String, dynamic> order) async {
    // Kiểm tra trạng thái đơn hàng
    if (order['status'] == 'Đã hoàn tiền' || order['status'] == 'Đã hủy') {
      ToastHelper.showError(context, 'Đơn hàng này đã được hoàn tiền hoặc hủy');
      return;
    }

    // Tính số tiền có thể hoàn tối đa
    final maxRefundAmount =
        (order['paid'] ?? 0) - (order['refund_amount'] ?? 0);
    if (maxRefundAmount <= 0) {
      ToastHelper.showError(context, 'Không có số tiền nào có thể hoàn trả');
      return;
    }

    bool isProcessing = false;

    await DialogHelper.showAnimatedDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Trả hàng - Đơn #${order['id']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Số tiền có thể hoàn: ${FormatUtils.formatCurrency(maxRefundAmount)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: maxRefundAmount.toString(),
                decoration: const InputDecoration(
                  labelText: 'Số tiền hoàn trả *',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final amount = double.tryParse(value) ?? 0;
                  if (amount > maxRefundAmount) {
                    setState(() {
                      _refundAmount = maxRefundAmount;
                    });
                  } else {
                    setState(() {
                      _refundAmount = amount;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Lý do hoàn trả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    _refundReason = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (_refundAmount <= 0) {
                        ToastHelper.showError(
                            context, 'Vui lòng nhập số tiền hoàn trả hợp lệ');
                        return;
                      }

                      setState(() => isProcessing = true);

                      try {
                        await DatabaseHelper.instance.updateOrder(
                          order['id'],
                          {
                            'refund_amount': _refundAmount,
                            'refund_reason': _refundReason,
                            'status': 'Đã hoàn tiền',
                          },
                        );

                        if (!mounted) return;
                        Navigator.pop(context);

                        ToastHelper.showSuccess(
                            context, 'Đã hoàn tiền thành công');
                        await _refreshData();
                      } catch (e) {
                        if (mounted) {
                          ToastHelper.showError(context,
                              'Không thể hoàn tiền. Vui lòng kiểm tra lại và thử lại sau.');
                        }
                      } finally {
                        if (mounted) {
                          setState(() => isProcessing = false);
                        }
                      }
                    },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isProcessing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    const Icon(Icons.payments),
                  const SizedBox(width: 8),
                  Text(isProcessing ? 'Đang xử lý...' : 'Hoàn tiền'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOrderDetails(Map<String, dynamic> order) async {
    bool isProcessing = false;

    // Load order items and customer info
    final orderItems = await DatabaseHelper.instance.getOrderItems(order['id']);
    Customer? customer;
    if (order['customer_id'] != null) {
      final customerData =
          await DatabaseHelper.instance.getCustomer(order['customer_id']);
      if (customerData != null) {
        customer = Customer.fromMap(customerData);
      }
    }

    if (!mounted) return;

    await DialogHelper.showAnimatedDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          titlePadding: EdgeInsets.zero,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                // Icon đơn hàng
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Tiêu đề
                Expanded(
                  child: Text(
                    'Chi tiết đơn #${order['id']}',
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
                  onPressed:
                      isProcessing ? null : () => Navigator.pop(dialogContext),
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trạng thái và thông tin cơ bản
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Ngày đặt hàng
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${order['date']}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Trạng thái đơn hàng
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order['status']),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getStatusColor(order['status'])
                                        .withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                order['status'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Thông tin khách hàng
                      if (customer != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Khách hàng: ${customer.name}',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (customer.phone != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'SĐT: ${customer.phone}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                      // Trạng thái hoàn tiền
                      if (order['refund_amount'] != null &&
                          order['refund_amount'] > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.assignment_return,
                                  color: Colors.red, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Đã hoàn tiền',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Phần sản phẩm
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sản phẩm',
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
                      ...orderItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                      if (item['attributes'] != null)
                                        Text(
                                          item['attributes'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${item['quantity']} x ${formatCurrency(item['price'])}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Phần thông tin thanh toán
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Thanh toán',
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
                      // Tổng tiền
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng tiền:'),
                          Text(
                            order['refund_amount'] != null &&
                                    order['refund_amount'] > 0
                                ? '0đ'
                                : formatCurrency(order['total']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Thuế
                      if (order['tax_percent'] > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Thuế (${order['tax_percent']}%):'),
                            Text(
                              '${formatCurrency(order['total'] * order['tax_percent'] / 100)}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      // Chiết khấu
                      if (order['discount_amount'] > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Chiết khấu:'),
                            Text(
                              '${formatCurrency(order['discount_amount'])}',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      // Phí ship
                      if (order['shipping_fee'] > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Phí ship:'),
                            Text('${formatCurrency(order['shipping_fee'])}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      const Divider(),
                      // Đã trả
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Đã trả:'),
                          Text(
                            '${formatCurrency(order['paid'])}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // Còn nợ
                      if ((order['debt'] ?? 0) > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Còn nợ:'),
                            Text(
                              '${formatCurrency(order['debt'])}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          actions: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tiêu đề phần thao tác
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
                  const SizedBox(height: 12),

                  // Hàng 1: Nút xuất PDF và Xóa
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Nút xuất PDF
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    Navigator.pop(dialogContext);
                                    await _exportOrderToPdf(order);
                                  },
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Xuất PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),

                      // Nút xóa
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    // Show confirmation dialog
                                    final confirm = await DialogHelper
                                        .showAnimatedDialog<bool>(
                                      context: dialogContext,
                                      builder: (BuildContext confirmContext) =>
                                          AlertDialog(
                                        title: const Text('Xác nhận xóa'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                                'Bạn có chắc chắn muốn xóa đơn hàng này?'),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Đơn hàng #${order['id']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Trạng thái: ${order['status']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Tổng tiền: ${formatCurrency(order['total'])}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 16),
                                            if (order['status'] !=
                                                'Đã hoàn tiền')
                                              const Text(
                                                'Thao tác này sẽ:\n'
                                                '- Xóa đơn hàng và các sản phẩm trong đơn\n'
                                                '- Hoàn trả số lượng sản phẩm vào kho\n'
                                                '- Giảm công nợ khách hàng (nếu có)\n'
                                                '- Cập nhật lại doanh thu và lợi nhuận\n\n'
                                                'Lưu ý: Thao tác này không thể hoàn tác!',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              )
                                            else
                                              const Text(
                                                'Đơn hàng đã hủy. Xóa đơn hàng này sẽ không ảnh hưởng đến kho hàng.',
                                                style: TextStyle(
                                                    color: Colors.orange),
                                              ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                confirmContext, false),
                                            child: const Text('Hủy'),
                                          ),
                                          FilledButton.icon(
                                            onPressed: () => Navigator.pop(
                                                confirmContext, true),
                                            icon: const Icon(
                                                Icons.delete_forever),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            label: const Text('Xóa đơn hàng'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      setState(() => isProcessing = true);
                                      try {
                                        await DatabaseHelper.instance
                                            .deleteOrder(order['id']);

                                        // Refresh data before closing dialog
                                        await _refreshData();

                                        if (!mounted) return;
                                        Navigator.of(dialogContext).pop();

                                        _showMessage(
                                            'Đã xóa đơn hàng thành công');
                                      } catch (e) {
                                        setState(() => isProcessing = false);
                                        if (!mounted) return;
                                        _showMessage('Lỗi: ${e.toString()}',
                                            isError: true);
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Xóa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Hiển thị các nút khác nếu cần
                  if ((order['debt'] ?? 0) > 0 ||
                      ((order['status'] == 'Hoàn tất' ||
                              (order['status'] == 'Còn nợ' &&
                                  (order['debt'] ?? 0) == 0)) &&
                          (order['refund_amount'] ?? 0) == 0))
                    const SizedBox(height: 12),

                  // Hàng 2: Các nút khác (trả nợ, đổi hàng, trả hàng)
                  if ((order['debt'] ?? 0) > 0 ||
                      ((order['status'] == 'Hoàn tất' ||
                              (order['status'] == 'Còn nợ' &&
                                  (order['debt'] ?? 0) == 0)) &&
                          (order['refund_amount'] ?? 0) == 0))
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Nút trả nợ
                        if ((order['debt'] ?? 0) > 0)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ElevatedButton.icon(
                                onPressed: isProcessing
                                    ? null
                                    : () {
                                        Navigator.pop(dialogContext);
                                        _showDebtPaymentDialog(order);
                                      },
                                icon: const Icon(Icons.payments),
                                label: const Text('Trả nợ'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ),

                        // Nút đổi hàng và trả hàng
                        if ((order['status'] == 'Hoàn tất' ||
                                (order['status'] == 'Còn nợ' &&
                                    (order['debt'] ?? 0) == 0)) &&
                            (order['refund_amount'] ?? 0) == 0) ...[
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ElevatedButton.icon(
                                onPressed: isProcessing
                                    ? null
                                    : () async {
                                        Navigator.pop(dialogContext);
                                        if (!_canExchangeOrder(order)) {
                                          ToastHelper.showError(context,
                                              'Đơn hàng trên 3 ngày không được đổi');
                                          return;
                                        }
                                        await _showExchangeDialog(order);
                                      },
                                icon: const Icon(Icons.swap_horiz),
                                label: const Text('Đổi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ElevatedButton.icon(
                                onPressed: isProcessing
                                    ? null
                                    : () async {
                                        Navigator.pop(dialogContext);
                                        await _showReturnDialog(order);
                                      },
                                icon: const Icon(Icons.assignment_return),
                                label: const Text('Trả'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReturnDialog(Map<String, dynamic> order) async {
    bool isProcessing = false;

    await DialogHelper.showAnimatedDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          titlePadding: EdgeInsets.zero,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                // Icon trả hàng
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assignment_return,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Tiêu đề
                Expanded(
                  child: Text(
                    'Trả hàng - Đơn #${order['id']}',
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
                  onPressed: isProcessing ? null : () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bạn có chắc chắn muốn trả hàng không?\n\n'
                'Lưu ý:\n'
                '- Toàn bộ hàng sẽ được hoàn trả về kho\n'
                '- Mọi doanh thu và lợi nhuận của đơn hàng này sẽ bị trừ đi\n'
                '- Phí ship không được hoàn trả',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              Text(
                'Tổng tiền đơn hàng: ${formatCurrency(order['total'])}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (order['shipping_fee'] > 0)
                Text(
                  'Phí ship: ${formatCurrency(order['shipping_fee'])}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 8),
              Text(
                'Số tiền phải hoàn: ${formatCurrency(order['total'] - (order['shipping_fee'] ?? 0))}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      setState(() => isProcessing = true);
                      try {
                        // Process return
                        await DatabaseHelper.instance.refundOrder(
                          order['id'],
                          order['total'] -
                              (order['shipping_fee'] ??
                                  0), // Hoàn số tiền trừ phí ship
                          'Trả hàng toàn bộ đơn',
                        );

                        // Return all products to inventory
                        final orderItems = await DatabaseHelper.instance
                            .getOrderItems(order['id']);
                        for (final item in orderItems) {
                          if (item['product_id'] != null) {
                            await DatabaseHelper.instance.updateProductQuantity(
                              item['product_id'],
                              item['quantity'],
                            );
                          }
                        }

                        // Refresh data before closing dialog
                        await _refreshData();

                        if (!mounted) return;
                        Navigator.pop(context);

                        ToastHelper.showSuccess(
                            context, 'Đã xử lý trả hàng thành công');
                      } catch (e) {
                        setState(() => isProcessing = false);
                        if (!mounted) return;
                        ToastHelper.showError(context, 'Lỗi: ${e.toString()}');
                      }
                    },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportOrderToPdf(Map<String, dynamic> order) async {
    try {
      // Chuẩn bị dữ liệu cho PDF
      final List<Map<String, dynamic>> orderItems =
          List<Map<String, dynamic>>.from(order['items']);
      final List<String> headers = [
        'Sản phẩm',
        'Số lượng',
        'Đơn giá',
        'Thành tiền'
      ];

      // Chuyển đổi dữ liệu đơn hàng thành định dạng phù hợp cho PDF
      final List<Map<String, dynamic>> data = orderItems.map((item) {
        return {
          'Sản phẩm': item['name'],
          'Số lượng': item['quantity'],
          'Đơn giá': formatCurrency(item['price']),
          'Thành tiền': formatCurrency(item['price'] * item['quantity']),
        };
      }).toList();

      // Thêm các dòng tổng kết
      data.add({
        'Sản phẩm': 'Tổng tiền hàng',
        'Số lượng': '',
        'Đơn giá': '',
        'Thành tiền': formatCurrency(order['total']),
      });

      if (order['tax_percent'] > 0) {
        data.add({
          'Sản phẩm': 'Thuế (${order['tax_percent']}%)',
          'Số lượng': '',
          'Đơn giá': '',
          'Thành tiền':
              formatCurrency(order['total'] * order['tax_percent'] / 100),
        });
      }

      if (order['discount_amount'] > 0) {
        data.add({
          'Sản phẩm': 'Chiết khấu',
          'Số lượng': '',
          'Đơn giá': '',
          'Thành tiền': '-${formatCurrency(order['discount_amount'])}',
        });
      }

      if (order['shipping_fee'] > 0) {
        data.add({
          'Sản phẩm': 'Phí ship',
          'Số lượng': '',
          'Đơn giá': '',
          'Thành tiền': formatCurrency(order['shipping_fee']),
        });
      }

      data.add({
        'Sản phẩm': 'Tổng cộng',
        'Số lượng': '',
        'Đơn giá': '',
        'Thành tiền': formatCurrency(order['total'] +
            (order['shipping_fee'] ?? 0) -
            (order['discount_amount'] ?? 0)),
      });

      // Tạo tiêu đề cho PDF
      final String title = 'Hóa đơn #${order['id']} - ${order['date']}';

      // Gọi service để tạo và in PDF
      await PDFService.generateAndPrintPDF(
        title: title,
        data: data,
        headers: headers,
      );

      // Hiển thị thông báo thành công
      if (mounted) {
        ToastHelper.showSuccess(context, 'Đã xuất PDF thành công');
      }
    } catch (e) {
      ToastHelper.showError(context, 'Lỗi: ${e.toString()}');
    }
  }

  Widget _buildSummaryCard() {
    final revenue = (_summary['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final expenses = (_summary['total_expenses'] as num?)?.toDouble() ?? 0.0;
    final totalCost = (_summary['total_cost'] as num?)?.toDouble() ?? 0.0;
    final debt = (_summary['total_debt'] as num?)?.toDouble() ?? 0.0;
    final refunds = (_summary['total_refunds'] as num?)?.toDouble() ?? 0.0;
    final netProfit = (_summary['net_profit'] as num?)?.toDouble() ?? 0.0;

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng kết',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _timeRange == 'today'
                          ? 'Hôm nay'
                          : _timeRange == 'week'
                              ? '7 ngày qua'
                              : 'Tháng này',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _showDetailedFinancials
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _showDetailedFinancials = !_showDetailedFinancials;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Lợi nhuận
          Container(
            padding:
                EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getAdaptiveSpacing(context, 12)),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lợi nhuận',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${netProfit.toStringAsFixed(0).replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]}.',
                      )}đ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Doanh thu
          Container(
            padding:
                EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getAdaptiveSpacing(context, 12)),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Doanh thu',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${revenue.toStringAsFixed(0).replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]}.',
                      )}đ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (_showDetailedFinancials) ...[
            const SizedBox(height: 16),
            // Giá vốn
            Container(
              padding: EdgeInsets.all(
                  ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Giá vốn',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${totalCost.toStringAsFixed(0).replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        )}đ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Chi phí
            Container(
              padding: EdgeInsets.all(
                  ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chi phí',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${expenses.toStringAsFixed(0).replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        )}đ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Công nợ
          Container(
            padding:
                EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
              borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getAdaptiveSpacing(context, 12)),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Công nợ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${debt.toStringAsFixed(0).replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]}.',
                      )}đ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    if (_filteredOrders.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có đơn hàng nào',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredOrders = _filteredOrders.where((order) {
      if (_orderFilter == 'all') return true;
      if (_orderFilter == 'debt') return (order['debt'] ?? 0) > 0;
      if (_orderFilter == 'discount')
        return (order['discount_amount'] ?? 0) > 0;
      if (_orderFilter == 'exchange')
        return order['refund_reason'] == 'Hủy đơn để đổi hàng';
      if (_orderFilter == 'cancel')
        return order['status'] == 'Đã hoàn tiền' &&
            order['refund_reason'] != 'Hủy đơn để đổi hàng';
      return true;
    }).toList();

    final displayOrders =
        _showAllOrders ? filteredOrders : filteredOrders.take(5).toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đơn hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${filteredOrders.length} đơn',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.visibility,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          tooltip: 'Bộ lọc',
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Thời gian',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      FilterChip(
                                        label: const Text('Hôm nay'),
                                        selected: _orderTimeRange == 'today',
                                        onSelected: (selected) {
                                          if (selected &&
                                              _orderTimeRange != 'today') {
                                            setState(() {
                                              _orderTimeRange = 'today';
                                              _applyFilters();
                                            });
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('7 ngày'),
                                        selected: _orderTimeRange == 'week',
                                        onSelected: (selected) {
                                          if (selected &&
                                              _orderTimeRange != 'week') {
                                            setState(() {
                                              _orderTimeRange = 'week';
                                              _applyFilters();
                                            });
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Tháng'),
                                        selected: _orderTimeRange == 'month',
                                        onSelected: (selected) {
                                          if (selected &&
                                              _orderTimeRange != 'month') {
                                            setState(() {
                                              _orderTimeRange = 'month';
                                              _applyFilters();
                                            });
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      ActionChip(
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(_selectedOrderYear),
                                            const Icon(Icons.arrow_drop_down,
                                                size: 18),
                                          ],
                                        ),
                                        onPressed: () async {
                                          await _showOrderYearPicker();
                                          if (_isLoading) {
                                            _applyFilters();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Loại đơn',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      FilterChip(
                                        label: const Text('Tất cả'),
                                        selected: _orderFilter == 'all',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(
                                                () => _orderFilter = 'all');
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Còn nợ'),
                                        selected: _orderFilter == 'debt',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(
                                                () => _orderFilter = 'debt');
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Chiết khấu'),
                                        selected: _orderFilter == 'discount',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() =>
                                                _orderFilter = 'discount');
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Đổi hàng'),
                                        selected: _orderFilter == 'exchange',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() =>
                                                _orderFilter = 'exchange');
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Đã hủy'),
                                        selected: _orderFilter == 'cancel',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(
                                                () => _orderFilter = 'cancel');
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          ...displayOrders.map((order) => InkWell(
                onTap: () => _showOrderDetails(order),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (order['debt'] ?? 0) > 0
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              order['status'] == 'Đã hoàn tiền'
                                  ? Icons.assignment_return
                                  : (order['debt'] ?? 0) > 0
                                      ? Icons.warning_amber
                                      : Icons.check_circle,
                              color: order['status'] == 'Đã hoàn tiền'
                                  ? Colors.red
                                  : (order['debt'] ?? 0) > 0
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Đơn #${order['id']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (order['refund_amount'] != null &&
                                        order['refund_amount'] > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.assignment_return,
                                                color: Colors.red, size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              'Đã hoàn tiền',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Text(
                                      order['status'] == 'Đã hoàn tiền'
                                          ? formatCurrency(0)
                                          : formatCurrency(order['total']),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        order['date'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    if (order['category'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          order['category'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
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
                      if ((order['tax_percent'] > 0 ||
                              order['shipping_fee'] > 0 ||
                              (order['debt'] > 0)) &&
                          order['status'] != 'Đã hoàn tiền')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const SizedBox(width: 32),
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    if (order['tax_percent'] > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Thuế ${order['tax_percent']}%',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.purple,
                                          ),
                                        ),
                                      ),
                                    if (order['shipping_fee'] > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Ship ${formatCurrency(order['shipping_fee'])}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    if ((order['debt'] ?? 0) > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Nợ ${formatCurrency(order['debt'])}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                'Đã trả: ${formatCurrency(order['paid'])}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              )),
          if (!_showAllOrders && filteredOrders.length > 5)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    setState(() => _showAllOrders = true);
                  },
                  child: const Text('Xem tất cả'),
                ),
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    if (_showAllOrders) {
                      setState(() => _showAllOrders = false);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _orderFilter == 'debt'
                            ? 'Tổng nợ:'
                            : _orderFilter == 'discount'
                                ? 'Tổng chiết khấu:'
                                : 'Tổng giá trị:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _orderFilter == 'debt' ? Colors.orange : null,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_orderFilter == 'debt')
                            Text(
                              formatCurrency(filteredOrders.fold(
                                0.0,
                                (sum, order) => sum + (order['debt'] ?? 0),
                              )),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          else if (_orderFilter == 'discount')
                            Text(
                              formatCurrency(filteredOrders.fold(
                                0.0,
                                (sum, order) =>
                                    sum + (order['discount_amount'] ?? 0),
                              )),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatCurrency(filteredOrders.fold(
                                      0.0,
                                      (sum, order) =>
                                          sum +
                                          (order['status'] == 'Đã hoàn tiền'
                                              ? 0
                                              : order['total']))),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (filteredOrders.any(
                                    (order) => order['discount_amount'] > 0))
                                  Text(
                                    'Tổng chiết khấu: ${formatCurrency(filteredOrders.fold(
                                      0.0,
                                      (sum, order) =>
                                          sum + (order['discount_amount'] ?? 0),
                                    ))}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                if (filteredOrders
                                    .any((order) => order['shipping_fee'] > 0))
                                  Text(
                                    'Tổng phí ship: ${formatCurrency(filteredOrders.fold(
                                      0.0,
                                      (sum, order) =>
                                          sum + (order['shipping_fee'] ?? 0),
                                    ))}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    if (_filteredExpenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payments_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có chi tiêu nào',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredExpenses = _filteredExpenses.where((expense) {
      if (_expenseType == 'all') return true;
      return expense['category'] == _expenseType;
    }).toList();

    final displayExpenses =
        _showAllExpenses ? filteredExpenses : filteredExpenses.take(5).toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chi tiêu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${filteredExpenses.length} khoản',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.visibility,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          tooltip: 'Bộ lọc',
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Thời gian',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      FilterChip(
                                        label: const Text('Hôm nay'),
                                        selected: _expenseTimeRange == 'today',
                                        onSelected: (selected) {
                                          if (selected &&
                                              _expenseTimeRange != 'today') {
                                            setState(() {
                                              _expenseTimeRange = 'today';
                                              _applyFilters();
                                            });
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('7 ngày'),
                                        selected: _expenseTimeRange == 'week',
                                        onSelected: (selected) {
                                          if (selected &&
                                              _expenseTimeRange != 'week') {
                                            setState(() {
                                              _expenseTimeRange = 'week';
                                              _applyFilters();
                                            });
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Tháng'),
                                        selected: _expenseTimeRange == 'month',
                                        onSelected: (selected) {
                                          if (selected &&
                                              _expenseTimeRange != 'month') {
                                            setState(() {
                                              _expenseTimeRange = 'month';
                                              _applyFilters();
                                            });
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      ActionChip(
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(_selectedExpenseYear),
                                            const Icon(Icons.arrow_drop_down,
                                                size: 18),
                                          ],
                                        ),
                                        onPressed: () async {
                                          await _showExpenseYearPicker();
                                          if (_isLoading) {
                                            _applyFilters();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Loại chi tiêu',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      FilterChip(
                                        label: const Text('Tất cả'),
                                        selected: _expenseType == 'all',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(
                                                () => _expenseType = 'all');
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Vận hành'),
                                        selected: _expenseType == 'Vận hành',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() =>
                                                _expenseType = 'Vận hành');
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Nguyên liệu'),
                                        selected: _expenseType == 'Nguyên liệu',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() =>
                                                _expenseType = 'Nguyên liệu');
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Nhân công'),
                                        selected: _expenseType == 'Nhân công',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() =>
                                                _expenseType = 'Nhân công');
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Tiện ích'),
                                        selected: _expenseType == 'Tiện ích',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() =>
                                                _expenseType = 'Tiện ích');
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Marketing'),
                                        selected: _expenseType == 'Marketing',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() =>
                                                _expenseType = 'Marketing');
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      FilterChip(
                                        label: const Text('Khác'),
                                        selected: _expenseType == 'Khác',
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(
                                                () => _expenseType = 'Khác');
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          ...displayExpenses.map((expense) => InkWell(
                onTap: () => _showExpenseDetails(expense),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          expense['category'] == 'Vận hành'
                              ? Icons.business
                              : Icons.category,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense['description'] ?? 'Không có mô tả',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              expense['date'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCurrency(expense['amount']),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          Text(
                            expense['category'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
          if (!_showAllExpenses && filteredExpenses.length > 5)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    setState(() => _showAllExpenses = true);
                  },
                  child: const Text('Xem tất cả'),
                ),
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () {
                if (_showAllExpenses) {
                  setState(() => _showAllExpenses = false);
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng chi:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formatCurrency(filteredExpenses.fold(
                        0.0, (sum, expense) => sum + expense['amount'])),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExpenseDetails(Map<String, dynamic> expense) async {
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
            color: Theme.of(context).colorScheme.error.withOpacity(0.15),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              // Icon chi tiêu
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  expense['category'] == 'Vận hành'
                      ? Icons.business
                      : expense['category'] == 'Nguyên liệu'
                          ? Icons.inventory
                          : expense['category'] == 'Nhân công'
                              ? Icons.people
                              : expense['category'] == 'Tiện ích'
                                  ? Icons.electrical_services
                                  : expense['category'] == 'Marketing'
                                      ? Icons.campaign
                                      : Icons.category,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Tiêu đề
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense['description'] ?? 'Không có mô tả',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      expense['category'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Nút đóng
              IconButton(
                icon: Icon(Icons.close,
                    color: Theme.of(context).colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .errorContainer
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Số tiền:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        formatCurrency(expense['amount']),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ngày:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        expense['date'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        actions: [
          Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tiêu đề phần thao tác
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
                const SizedBox(height: 12),

                // Hàng nút thao tác
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Nút sửa
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _editExpense(expense);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Sửa'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    // Nút xóa
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _deleteExpense(expense);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Xóa'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  Future<void> _editExpense(Map<String, dynamic> expense) async {
    bool isProcessing = false;
    // Format initial amount with thousand separators
    final initialAmount = (expense['amount'] as num).toDouble();
    final amountController = TextEditingController(
      text: initialAmount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          ),
    );

    final descriptionController = TextEditingController(
      text: expense['description']?.toString() ?? '',
    );

    String selectedCategory = expense['category']?.toString() ?? 'Khác';
    if (![
      'Vận hành',
      'Nguyên liệu',
      'Nhân công',
      'Tiện ích',
      'Marketing',
      'Khác'
    ].contains(selectedCategory)) {
      selectedCategory = 'Khác';
    }

    await DialogHelper.showAnimatedDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          titlePadding: EdgeInsets.zero,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                // Icon chi tiêu
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_document,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Tiêu đề
                Expanded(
                  child: Text(
                    'Sửa chi tiêu',
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
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .errorContainer
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: amountController,
                        enabled: !isProcessing,
                        decoration: const InputDecoration(
                          labelText: 'Số tiền',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        enabled: !isProcessing,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Loại chi tiêu',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Vận hành',
                            child: Text('Vận hành'),
                          ),
                          DropdownMenuItem(
                            value: 'Nguyên liệu',
                            child: Text('Nguyên liệu'),
                          ),
                          DropdownMenuItem(
                            value: 'Nhân công',
                            child: Text('Nhân công'),
                          ),
                          DropdownMenuItem(
                            value: 'Tiện ích',
                            child: Text('Tiện ích'),
                          ),
                          DropdownMenuItem(
                            value: 'Marketing',
                            child: Text('Marketing'),
                          ),
                          DropdownMenuItem(
                            value: 'Khác',
                            child: Text('Khác'),
                          ),
                        ],
                        onChanged: isProcessing
                            ? null
                            : (value) {
                                if (value != null &&
                                    value != selectedCategory) {
                                  setState(() => selectedCategory = value);
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tiêu đề phần thao tác
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
                  const SizedBox(height: 12),

                  // Hàng nút thao tác
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Nút hủy
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Hủy'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),

                      // Nút cập nhật
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    final amount = double.tryParse(
                                        amountController.text
                                            .replaceAll('.', ''));
                                    if (amount == null || amount <= 0) {
                                      ToastHelper.showError(
                                          context, 'Số tiền không hợp lệ');
                                      return;
                                    }

                                    setState(() => isProcessing = true);
                                    try {
                                      await DatabaseHelper.instance
                                          .updateExpense(
                                        expense['id'],
                                        {
                                          'amount': amount,
                                          'category': selectedCategory,
                                          'description':
                                              descriptionController.text.trim(),
                                        },
                                      );

                                      // Refresh data before closing dialog
                                      await _refreshData();

                                      if (!mounted) return;
                                      Navigator.pop(context);
                                      ToastHelper.showSuccess(
                                          context, 'Đã cập nhật chi tiêu');
                                    } catch (e) {
                                      setState(() => isProcessing = false);
                                      ToastHelper.showError(
                                          context, 'Lỗi: ${e.toString()}');
                                    }
                                  },
                            icon: isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(
                                isProcessing ? 'Đang xử lý...' : 'Cập nhật'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    bool isProcessing = false;

    final confirm = await DialogHelper.showAnimatedDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          titlePadding: EdgeInsets.zero,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: Row(
              children: [
                // Icon xóa
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_forever,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Tiêu đề
                const Expanded(
                  child: Text(
                    'Xác nhận xóa',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Nút đóng
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context, false),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bạn có chắc chắn muốn xóa khoản chi tiêu này?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mô tả: ${expense['description'] ?? 'Không có mô tả'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Số tiền: ${formatCurrency(expense['amount'])}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tiêu đề phần thao tác
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
                  const SizedBox(height: 12),

                  // Hàng nút thao tác
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Nút hủy
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () => Navigator.pop(context, false),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Hủy'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),

                      // Nút xóa
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () => Navigator.pop(context, true),
                            icon: isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.delete),
                            label: Text(isProcessing ? 'Đang xử lý...' : 'Xóa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
    );

    if (confirm == true) {
      try {
        // Refresh data before closing dialog
        await DatabaseHelper.instance.deleteExpense(expense['id']);
        await _refreshData();

        if (mounted) {
          ToastHelper.showSuccess(context, 'Đã xóa chi tiêu');
        }
      } catch (e) {
        if (mounted) {
          ToastHelper.showError(context, 'Lỗi: ${e.toString()}');
        }
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Chào buổi sáng!';
    } else if (hour < 18) {
      return 'Chào buổi chiều!';
    } else {
      return 'Chào buổi tối!';
    }
  }

  String _getFormattedDateTime() {
    final now = DateTime.now();
    final weekday = _getWeekday(now.weekday);
    return '$weekday, ${now.day} tháng ${now.month}, ${now.year}';
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return 'Thứ hai';
      case 2:
        return 'Thứ ba';
      case 3:
        return 'Thứ tư';
      case 4:
        return 'Thứ năm';
      case 5:
        return 'Thứ sáu';
      case 6:
        return 'Thứ bảy';
      case 7:
        return 'Chủ nhật';
      default:
        return '';
    }
  }

  double? _parseDebtInput(String text) {
    if (text.isEmpty) return null;
    final onlyNumbers = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (onlyNumbers.isEmpty) return null;
    return double.tryParse(onlyNumbers);
  }

  bool _canExchangeOrder(Map<String, dynamic> order) {
    final orderDate = DateTime.parse(order['date']);
    final now = DateTime.now();
    final difference = now.difference(orderDate);
    return difference.inDays <= 3;
  }

  Future<void> _showExchangeDialog(Map<String, dynamic> order) async {
    final confirm = await DialogHelper.showAnimatedDialog<bool>(
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              // Icon đổi hàng
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.swap_horiz,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Tiêu đề
              Expanded(
                child: Text(
                  'Đổi hàng - Đơn #${order['id']}',
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
                onPressed: () => Navigator.pop(context, false),
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn có chắc chắn muốn đổi hàng không?\n\n'
              'Lưu ý:\n'
              '- Hàng sẽ được hoàn trả về kho\n'
              '- Mọi doanh thu và lợi nhuận của đơn hàng này sẽ bị trừ đi\n'
              '- Phí ship không được hoàn trả\n'
              '- Để đổi hàng, bạn cần xác nhận xóa đơn hàng này và tạo đơn hàng mới',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              'Tổng tiền đơn hàng: ${formatCurrency(order['total'])}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (order['shipping_fee'] > 0)
              Text(
                'Phí ship: ${formatCurrency(order['shipping_fee'])}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Lấy thông tin đơn hàng cũ
        final orderItems =
            await DatabaseHelper.instance.getOrderItems(order['id']);
        final customer = order['customer_id'] != null
            ? await DatabaseHelper.instance.getCustomer(order['customer_id'])
            : null;

        // Tạo đơn hàng mới với dữ liệu từ đơn cũ
        final newOrder = {
          'id': null, // Ensure this is null for new order
          'customer_id': customer?['id'], // Use null-safe access
          'date': DateTime.now().toIso8601String(),
          'status': 'Còn nợ',
          'total': order['total']?.toDouble() ?? 0.0,
          'paid': order['total']?.toDouble() ??
              0.0, // Set initial payment to old order total
          'debt': 0.0,
          'shipping_fee': 0.0, // Reset shipping fee to 0 for exchange order
          'discount_amount': order['discount_amount']?.toDouble() ?? 0.0,
          'tax_percent': order['tax_percent']?.toDouble() ?? 0.0,
          'note': 'Đổi hàng từ đơn #${order['id']}',
          'category': 'Đổi hàng',
          'items': orderItems, // Pass the old order items
        };

        // Mở form tạo đơn mới
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateOrderForm(
              initialOrder: newOrder,
              isExchange: true,
              oldOrderTotal: order['total']?.toDouble() ?? 0.0,
            ),
          ),
        );

        if (result == true) {
          // Trước khi xóa đơn hàng cũ, cộng lại số lượng sản phẩm vào kho
          final oldOrderItems =
              await DatabaseHelper.instance.getOrderItems(order['id']);
          for (final item in oldOrderItems) {
            if (item['product_id'] != null) {
              await DatabaseHelper.instance.updateProductQuantity(
                item['product_id'],
                item['quantity'], // Cộng lại số lượng vào kho
              );
            }
          }

          // Xóa đơn hàng cũ
          await DatabaseHelper.instance.deleteOrder(order['id']);

          // Refresh lại danh sách đơn hàng
          await _refreshData();

          if (!mounted) return;
          ToastHelper.showSuccess(context, 'Đã xử lý đổi hàng thành công');
        }
      } catch (e) {
        if (!mounted) return;
        ToastHelper.showError(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  Widget _buildSummaryBoxes() {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng quan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showSummaryBoxes ? Icons.visibility_off : Icons.visibility,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _showSummaryBoxes = !_showSummaryBoxes;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_showSummaryBoxes) ...[
            Divider(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Hàng bán chạy
                  Container(
                    padding: EdgeInsets.all(
                        ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hàng bán chạy',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _topProducts.length.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Khách mới
                  Container(
                    padding: EdgeInsets.all(
                        ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person_add,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Khách mới',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _newCustomersToday.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Hàng sắp hết
                  Container(
                    padding: EdgeInsets.all(
                        ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hàng sắp hết',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _lowStockProducts.length.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tồn kho
                  Container(
                    padding: EdgeInsets.all(
                        ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                      border: Border.all(
                        color: Colors.purple.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.inventory,
                              color: Colors.purple,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tồn kho',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.purple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _totalInventory.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCharts() {
    // Tính toán dữ liệu cho biểu đồ cột
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    List<double> dailyRevenue = List.filled(7, 0);

    for (var order in _filteredOrders) {
      final orderDate = DateTime.parse(order['date']);
      if (orderDate.isAfter(weekStart)) {
        final dayIndex = orderDate.weekday - 1;
        if (order['status'] != 'Đã hoàn tiền') {
          dailyRevenue[dayIndex] +=
              (order['total'] ?? 0) - (order['refund_amount'] ?? 0);
        }
      }
    }

    // Tính toán dữ liệu cho biểu đồ tròn
    Map<String, double> expensesByCategory = {};
    double totalExpenses = 0;

    for (var expense in _filteredExpenses) {
      final category = expense['category'] as String;
      final amount = (expense['amount'] as num).toDouble();
      expensesByCategory[category] =
          (expensesByCategory[category] ?? 0) + amount;
      totalExpenses += amount;
    }

    final pieChartSections = expensesByCategory.entries.map((entry) {
      final percentage =
          totalExpenses > 0 ? (entry.value / totalExpenses * 100) : 0;
      final color = entry.key == 'Vận hành'
          ? Colors.blue
          : entry.key == 'Nguyên liệu'
              ? Colors.green
              : entry.key == 'Nhân công'
                  ? Colors.orange
                  : entry.key == 'Tiện ích'
                      ? Colors.purple
                      : entry.key == 'Marketing'
                          ? Colors.red
                          : Colors.grey;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%\n${entry.key}',
        radius: 100,
        color: color,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    // Tìm giá trị cao nhất cho biểu đồ cột
    final maxRevenue = dailyRevenue.reduce((a, b) => a > b ? a : b);
    final yInterval =
        maxRevenue <= 0 ? 1000000.0 : (maxRevenue / 5).ceilToDouble();

    return Card(
      child: Column(
        children: [
          Padding(
            padding:
                EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Biểu đồ phân tích',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showCharts ? Icons.visibility_off : Icons.visibility,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _showCharts = !_showCharts;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_showCharts) ...[
            Divider(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            Padding(
              padding: EdgeInsets.all(
                  ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Doanh thu theo ngày',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  SizedBox(
                    height: ResponsiveUtils.getAdaptiveSpacing(context, 200),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxRevenue + yInterval,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.blueGrey,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${(rod.toY / 1000000).toStringAsFixed(1)}tr',
                                const TextStyle(color: Colors.white),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  'T2',
                                  'T3',
                                  'T4',
                                  'T5',
                                  'T6',
                                  'T7',
                                  'CN'
                                ];
                                if (value.toInt() >= 0 &&
                                    value.toInt() < days.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      days[value.toInt()],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: ResponsiveUtils.getAdaptiveSpacing(
                                  context, 40),
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${(value / 1000000).toStringAsFixed(0)}tr',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: yInterval,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        barGroups: List.generate(7, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: dailyRevenue[index],
                                color: Theme.of(context).colorScheme.primary,
                                width: ResponsiveUtils.getAdaptiveSpacing(
                                    context, 16),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(
                                      ResponsiveUtils.getAdaptiveSpacing(
                                          context, 4)),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 32)),
                  const Text(
                    'Chi tiêu theo loại',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  if (pieChartSections.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(
                            ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        child: Text(
                          'Chưa có dữ liệu chi tiêu',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 200),
                      child: PieChart(
                        PieChartData(
                          sections: pieChartSections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDecorativeChart() {
    // Tạo dữ liệu mẫu cho biểu đồ trang trí
    final List<FlSpot> spots = List.generate(12, (index) {
      final baseValue = 1000000; // 1 triệu
      final randomFactor = 0.5 + (index % 3) * 0.5; // Tạo mẫu lặp lại
      return FlSpot(index.toDouble(), baseValue * randomFactor);
    });

    return Card(
      child: Padding(
        padding:
            EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Xu hướng doanh thu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                    vertical: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                  ),
                  child: Text(
                    '12 tháng',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            SizedBox(
              height: ResponsiveUtils.getAdaptiveSpacing(context, 200),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 500000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'T1',
                            'T2',
                            'T3',
                            'T4',
                            'T5',
                            'T6',
                            'T7',
                            'T8',
                            'T9',
                            'T10',
                            'T11',
                            'T12'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                months[value.toInt()],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize:
                            ResponsiveUtils.getAdaptiveSpacing(context, 40),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000000).toStringAsFixed(0)}tr',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  minX: 0,
                  maxX: 11,
                  minY: 0,
                  maxY: 2000000,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Card(
      child: Padding(
        padding:
            EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _getGreeting(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
            Text(
              _getFormattedDateTime(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueTrendChart() {
    // Tính toán dữ liệu cho 7 ngày gần nhất
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    double maxRevenue = 0;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      double dailyRevenue = 0;

      // Tính tổng doanh thu cho mỗi ngày
      for (var order in _filteredOrders) {
        final orderDate = DateTime.parse(order['date']);
        if (orderDate.year == date.year &&
            orderDate.month == date.month &&
            orderDate.day == date.day &&
            order['status'] != 'Đã hoàn tiền') {
          dailyRevenue += (order['total'] ?? 0) - (order['refund_amount'] ?? 0);
        }
      }

      spots.add(FlSpot(i.toDouble(), dailyRevenue));
      if (dailyRevenue > maxRevenue) maxRevenue = dailyRevenue;
    }

    // Tính khoảng cách cho trục Y
    final yInterval =
        maxRevenue <= 0 ? 1000000.0 : (maxRevenue / 5).ceilToDouble();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Doanh thu 7 ngày gần nhất',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                    vertical: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                  ),
                  child: Text(
                    '7 ngày',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 14)),
            SizedBox(
              height: ResponsiveUtils.getAdaptiveSpacing(context, 200),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date =
                              now.subtract(Duration(days: 6 - value.toInt()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize:
                            ResponsiveUtils.getAdaptiveSpacing(context, 40),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000000).toStringAsFixed(0)}tr',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: maxRevenue + yInterval,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
              child: ListView(
                padding: EdgeInsets.all(
                    ResponsiveUtils.getAdaptiveSpacing(context, 14)),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildGreetingCard(),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 14)),
                  _buildRevenueTrendChart(),
                  SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 14)),
                  _buildSummaryCard(),
                  SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 14)),
                  _buildSummaryBoxes(),
                  SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 14)),
                  _buildCharts(),
                  SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 14)),
                  _buildOrderList(),
                  SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 14)),
                  _buildExpenseList(),
                  SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 14)),
                  _buildDecorativeChart(),
                ],
              ),
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hoàn tất':
        return Colors.green;
      case 'Còn nợ':
        return Colors.orange;
      case 'Đã hoàn tiền':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
