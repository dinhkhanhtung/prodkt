import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_item_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import '../management/order_detail_screen.dart';

class ProductHistoryScreen extends StatefulWidget {
  final int productId;

  const ProductHistoryScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  State<ProductHistoryScreen> createState() => _ProductHistoryScreenState();
}

class _ProductHistoryScreenState extends State<ProductHistoryScreen> {
  late Future<Product?> _productFuture;
  late Future<List<Order>> _ordersFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    _productFuture = productProvider.getProductById(widget.productId);
    await orderProvider.loadOrders();
    
    _ordersFuture = _getOrdersContainingProduct(widget.productId);

    setState(() {
      _isLoading = false;
    });
  }

  Future<List<Order>> _getOrdersContainingProduct(int productId) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final allOrders = orderProvider.orders;
    
    // Filter orders that contain the product
    final List<Order> filteredOrders = [];
    
    for (final order in allOrders) {
      if (order.items != null) {
        final containsProduct = order.items!.any((item) => item.productId == productId);
        if (containsProduct) {
          filteredOrders.add(order);
        }
      }
    }
    
    // Sort by date (newest first)
    filteredOrders.sort((a, b) => b.date.compareTo(a.date));
    
    return filteredOrders;
  }

  void _navigateToOrderDetail(int orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(orderId: orderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử sản phẩm'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Product?>(
              future: _productFuture,
              builder: (context, productSnapshot) {
                if (productSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (productSnapshot.hasError) {
                  return Center(
                    child: Text('Đã xảy ra lỗi: ${productSnapshot.error}'),
                  );
                }

                final product = productSnapshot.data;
                if (product == null) {
                  return const Center(
                    child: Text('Không tìm thấy sản phẩm'),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product info
                    Container(
                      padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Row(
                        children: [
                          Container(
                            width: ResponsiveUtils.getAdaptiveWidth(context, 60),
                            height: ResponsiveUtils.getAdaptiveWidth(context, 60),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.inventory_2,
                              size: ResponsiveUtils.getAdaptiveIconSize(context, 32),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (product.code != null && product.code!.isNotEmpty)
                                  Text(
                                    'Mã: ${product.code}',
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                                Text(
                                  'Giá: ${StringUtils.formatCurrency(product.sellPrice)}',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 12),
                              vertical: ResponsiveUtils.getAdaptiveSpacing(context, 6),
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'SL: ${product.quantity}',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Order history
                    Padding(
                      padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                      child: Text(
                        'Lịch sử đơn hàng',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Expanded(
                      child: FutureBuilder<List<Order>>(
                        future: _ordersFuture,
                        builder: (context, ordersSnapshot) {
                          if (ordersSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (ordersSnapshot.hasError) {
                            return Center(
                              child: Text('Đã xảy ra lỗi: ${ordersSnapshot.error}'),
                            );
                          }

                          final orders = ordersSnapshot.data ?? [];
                          
                          if (orders.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: ResponsiveUtils.getAdaptiveIconSize(context, 64),
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                                  Text(
                                    'Chưa có lịch sử đơn hàng',
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            itemCount: orders.length,
                            separatorBuilder: (context, index) => SizedBox(
                              height: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                            ),
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return _buildOrderItem(context, order, product.id!);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildOrderItem(BuildContext context, Order order, int productId) {
    // Find the order item for this product
    final OrderItem? orderItem = order.items?.firstWhere(
      (item) => item.productId == productId,
      orElse: () => OrderItem(
        orderId: order.id!,
        productId: productId,
        quantity: 0,
        price: 0,
        cost: 0,
      ),
    );

    final quantity = orderItem?.quantity ?? 0;
    final price = orderItem?.price ?? 0;
    final total = quantity * price;
    final isExchanged = orderItem?.isExchanged ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToOrderDetail(order.id!),
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
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                        color: _getStatusColor(order.status),
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
                  SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                  Icon(
                    Icons.person,
                    size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                  Text(
                    order.customer?.name ?? 'Khách lẻ',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Số lượng',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                          Row(
                            children: [
                              Text(
                                quantity.toString(),
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isExchanged)
                                Container(
                                  margin: EdgeInsets.only(
                                    left: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                                    vertical: ResponsiveUtils.getAdaptiveSpacing(context, 2),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Đổi trả',
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 10),
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đơn giá',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                          Text(
                            StringUtils.formatCurrency(price),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thành tiền',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                          Text(
                            StringUtils.formatCurrency(total),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
