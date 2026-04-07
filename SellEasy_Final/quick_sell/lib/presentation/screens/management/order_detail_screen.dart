import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_item_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/custom_button.dart';
import 'edit_order_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<Order?> _orderFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    _orderFuture = orderProvider.getOrderById(widget.orderId);
  }

  void _showDeleteConfirmation(Order order) {
    DialogHelper.showConfirmDialog(
      context: context,
      title: 'Xóa đơn hàng',
      content: 'Bạn có chắc chắn muốn xóa đơn hàng #${order.id} không?',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteOrder(order);
      }
    });
  }

  Future<void> _deleteOrder(Order order) async {
    setState(() {
      _isLoading = true;
    });

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final success = await orderProvider.deleteOrder(order.id!);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        DialogHelper.showSuccessToast(
          context: context,
          message: 'Đã xóa đơn hàng thành công',
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        DialogHelper.showErrorToast(
          context: context,
          message: 'Không thể xóa đơn hàng: ${orderProvider.error}',
        );
      }
    }
  }

  void _navigateToEditOrder(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditOrderScreen(order: order),
      ),
    ).then((_) {
      _loadOrder();
      setState(() {});
    });
  }

  void _printOrder(Order order) {
    // TODO: Implement print order functionality
    DialogHelper.showToast(
      context: context,
      message: 'Tính năng đang phát triển',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Order?>(
              future: _orderFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
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
                          snapshot.error.toString(),
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loadOrder();
                            });
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final order = snapshot.data;
                if (order == null) {
                  return Center(
                    child: Text(
                      'Không tìm thấy đơn hàng',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order header
                      Container(
                        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Đơn hàng #${order.id}',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                _buildStatusBadge(order.status),
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
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                            Row(
                              children: [
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
                            if (order.customer?.phone != null && order.customer!.phone!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                                    Text(
                                      order.customer!.phone!,
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Action buttons
                      Padding(
                        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomButton(
                              icon: Icons.edit,
                              label: 'Sửa',
                              onPressed: () => _navigateToEditOrder(order),
                              color: Colors.blue,
                            ),
                            SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            CustomButton(
                              icon: Icons.print,
                              label: 'In',
                              onPressed: () => _printOrder(order),
                              color: Colors.green,
                            ),
                            SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            CustomButton(
                              icon: Icons.delete,
                              label: 'Xóa',
                              onPressed: () => _showDeleteConfirmation(order),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),

                      // Order items
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                        ),
                        child: Text(
                          'Sản phẩm',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                      if (order.items == null || order.items!.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                          child: Center(
                            child: Text(
                              'Không có sản phẩm nào',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                          ),
                          itemCount: order.items!.length,
                          separatorBuilder: (context, index) => Divider(),
                          itemBuilder: (context, index) {
                            final item = order.items![index];
                            return _buildOrderItem(item);
                          },
                        ),

                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),

                      // Order summary
                      Container(
                        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        color: Colors.grey[100],
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              'Tổng tiền hàng',
                              StringUtils.formatCurrency(order.getSubtotal()),
                            ),
                            if (order.discountAmount > 0)
                              _buildSummaryRow(
                                'Giảm giá',
                                '- ${StringUtils.formatCurrency(order.discountAmount)}',
                                isNegative: true,
                              ),
                            if (order.taxPercent > 0)
                              _buildSummaryRow(
                                'Thuế (${order.taxPercent}%)',
                                StringUtils.formatCurrency(order.getSubtotal() * order.taxPercent / 100),
                              ),
                            if (order.shippingFee > 0)
                              _buildSummaryRow(
                                'Phí vận chuyển',
                                StringUtils.formatCurrency(order.shippingFee),
                              ),
                            if (order.additionalFee > 0)
                              _buildSummaryRow(
                                order.additionalFeeDescription ?? 'Phí khác',
                                StringUtils.formatCurrency(order.additionalFee),
                              ),
                            Divider(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
                            _buildSummaryRow(
                              'Tổng cộng',
                              StringUtils.formatCurrency(order.total),
                              isBold: true,
                            ),
                            _buildSummaryRow(
                              'Đã thanh toán',
                              StringUtils.formatCurrency(order.paid),
                            ),
                            if (order.debt > 0)
                              _buildSummaryRow(
                                'Còn nợ',
                                StringUtils.formatCurrency(order.debt),
                                isNegative: true,
                              ),
                          ],
                        ),
                      ),

                      // Notes
                      if (order.note != null && order.note!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ghi chú',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                              Container(
                                padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  order.note!,
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    
    switch (status) {
      case 'Hoàn thành':
        color = Colors.green;
        break;
      case 'Đang xử lý':
        color = Colors.blue;
        break;
      case 'Chưa thanh toán':
        color = Colors.orange;
        break;
      case 'Đã hủy':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 8),
        vertical: ResponsiveUtils.getAdaptiveSpacing(context, 4),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    final product = item.product;
    final totalPrice = item.price * item.quantity;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.getAdaptiveSpacing(context, 8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveUtils.getAdaptiveWidth(context, 40),
            height: ResponsiveUtils.getAdaptiveWidth(context, 40),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                item.quantity.toString(),
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product?.name ?? 'Sản phẩm không xác định',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (item.isExchanged)
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
                SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${StringUtils.formatCurrency(item.price)} × ${item.quantity}',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      StringUtils.formatCurrency(totalPrice),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                        fontWeight: FontWeight.bold,
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

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isNegative = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.getAdaptiveSpacing(context, 4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isNegative ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}
