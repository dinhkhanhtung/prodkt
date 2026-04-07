import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../data/models/order_model.dart';
import 'order_detail_screen.dart';
import 'create_order_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'Tất cả';
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadOrders() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.loadOrders();
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc theo trạng thái'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Tất cả'),
            _buildFilterOption('Hoàn thành'),
            _buildFilterOption('Đang xử lý'),
            _buildFilterOption('Chưa thanh toán'),
            _buildFilterOption('Đã hủy'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterOption(String status) {
    return RadioListTile<String>(
      title: Text(status),
      value: status,
      groupValue: _filterStatus,
      onChanged: (value) {
        setState(() {
          _filterStatus = value!;
        });
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        orderProvider.filterByStatus(value!);
        Navigator.pop(context);
      },
    );
  }
  
  void _navigateToOrderDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(orderId: order.id!),
      ),
    ).then((_) => _loadOrders());
  }
  
  void _navigateToCreateOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateOrderScreen(),
      ),
    ).then((_) => _loadOrders());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Lọc đơn hàng',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm đơn hàng...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.getAdaptiveSpacing(context, 12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                          orderProvider.searchOrders('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                orderProvider.searchOrders(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                if (orderProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (orderProvider.error.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đã xảy ra lỗi',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                        Text(
                          orderProvider.error,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        ElevatedButton(
                          onPressed: () {
                            orderProvider.clearError();
                            _loadOrders();
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                
                final orders = orderProvider.filteredOrders;
                
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: ResponsiveUtils.getAdaptiveIconSize(context, 64),
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        Text(
                          'Không tìm thấy đơn hàng nào',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        ElevatedButton.icon(
                          onPressed: _navigateToCreateOrder,
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo đơn hàng'),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.separated(
                    padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => SizedBox(
                      height: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                    ),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderItem(order);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateOrder,
        child: const Icon(Icons.add),
        tooltip: 'Tạo đơn hàng',
      ),
    );
  }
  
  Widget _buildOrderItem(Order order) {
    final customerName = order.customer?.name ?? 'Khách lẻ';
    final statusColor = _getStatusColor(order.status);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToOrderDetail(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đơn #${order.id}',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                      vertical: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                  Text(
                    customerName,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                  Text(
                    StringUtils.formatDate(order.date),
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng tiền',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        StringUtils.formatCurrency(order.total),
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (order.debt > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Còn nợ',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          StringUtils.formatCurrency(order.debt),
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return Colors.green;
      case 'Đang xử lý':
        return Colors.blue;
      case 'Chưa thanh toán':
        return Colors.orange;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
