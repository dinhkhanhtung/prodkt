import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../services/database_helper.dart';
import '../utils/format_utils.dart';
import '../utils/toast_helper.dart';
import 'order_detail_dialog.dart';

class OrderListWidget extends StatefulWidget {
  final String timeRange;
  final String selectedYear;
  final String orderFilter;
  final bool showAllOrders;

  const OrderListWidget({
    super.key,
    required this.timeRange,
    required this.selectedYear,
    required this.orderFilter,
    required this.showAllOrders,
  });

  @override
  State<OrderListWidget> createState() => _OrderListWidgetState();
}

class _OrderListWidgetState extends State<OrderListWidget> {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void didUpdateWidget(OrderListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRange != widget.timeRange ||
        oldWidget.selectedYear != widget.selectedYear ||
        oldWidget.orderFilter != widget.orderFilter ||
        oldWidget.showAllOrders != widget.showAllOrders) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final orders = await DatabaseHelper.instance.getOrders();

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
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ToastHelper.showError(
            context, 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.');
      }
    }
  }

  void _applyFilters() {
    final now = DateTime.now();
    final filteredOrders = _orders.where((order) {
      final orderDate = DateTime.parse(order['date']);
      final isInTimeRange = widget.timeRange == 'today'
          ? orderDate.year == now.year &&
              orderDate.month == now.month &&
              orderDate.day == now.day
          : widget.timeRange == 'week'
              ? orderDate.isAfter(now.subtract(const Duration(days: 7)))
              : orderDate.year == now.year && orderDate.month == now.month;

      final isInYear = orderDate.year.toString() == widget.selectedYear;

      final matchesFilter = widget.orderFilter == 'all'
          ? true
          : widget.orderFilter == 'debt'
              ? order['remaining_amount'] > 0
              : widget.orderFilter == 'discount'
                  ? order['discount'] > 0
                  : true;

      return isInTimeRange && isInYear && matchesFilter;
    }).toList();

    setState(() {
      _filteredOrders = filteredOrders;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredOrders.length,
          itemBuilder: (context, index) {
            final order = _filteredOrders[index];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => OrderDetailDialog(order: order),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đơn #${order['id']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              order['date'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng tiền:',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              formatCurrency(order['total_amount']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        if (order['discount'] > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Chiết khấu:',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '-${formatCurrency(order['discount'])}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (order['remaining_amount'] > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Còn nợ:',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                formatCurrency(order['remaining_amount']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (_filteredOrders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Không có đơn hàng nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
