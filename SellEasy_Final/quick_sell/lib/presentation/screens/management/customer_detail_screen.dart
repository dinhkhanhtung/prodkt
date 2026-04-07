import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/order_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/custom_button.dart';
import 'edit_customer_screen.dart';
import 'order_detail_screen.dart';
import 'create_order_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;

  const CustomerDetailScreen({
    Key? key,
    required this.customerId,
  }) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Future<Customer?> _customerFuture;
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

    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    _customerFuture = customerProvider.getCustomerById(widget.customerId);
    await orderProvider.loadOrders();
    
    _ordersFuture = _getCustomerOrders(widget.customerId);

    setState(() {
      _isLoading = false;
    });
  }

  Future<List<Order>> _getCustomerOrders(int customerId) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    return orderProvider.getOrdersByCustomer(customerId);
  }

  void _showDeleteConfirmation(Customer customer) {
    DialogHelper.showConfirmDialog(
      context: context,
      title: 'Xóa khách hàng',
      content: 'Bạn có chắc chắn muốn xóa khách hàng "${customer.name}" không?',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteCustomer(customer);
      }
    });
  }

  Future<void> _deleteCustomer(Customer customer) async {
    setState(() {
      _isLoading = true;
    });

    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final success = await customerProvider.deleteCustomer(customer.id!);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        DialogHelper.showSuccessToast(
          context: context,
          message: 'Đã xóa khách hàng thành công',
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        DialogHelper.showErrorToast(
          context: context,
          message: 'Không thể xóa khách hàng: ${customerProvider.error}',
        );
      }
    }
  }

  void _navigateToEditCustomer(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomerScreen(customer: customer),
      ),
    ).then((_) {
      _loadData();
      setState(() {});
    });
  }

  void _navigateToCreateOrder(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOrderScreen(customer: customer),
      ),
    ).then((_) {
      _loadData();
      setState(() {});
    });
  }

  void _navigateToOrderDetail(int orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(orderId: orderId),
      ),
    ).then((_) {
      _loadData();
      setState(() {});
    });
  }

  void _showPayDebtDialog(Customer customer) {
    if (customer.debt <= 0) {
      DialogHelper.showToast(
        context: context,
        message: 'Khách hàng không có nợ',
      );
      return;
    }

    final TextEditingController amountController = TextEditingController();
    
    DialogHelper.showCustomDialog(
      context: context,
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thanh toán nợ',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            Text(
              'Tổng nợ: ${StringUtils.formatCurrency(customer.debt)}',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Số tiền thanh toán',
                hintText: 'Nhập số tiền',
                border: OutlineInputBorder(),
                prefixText: '₫ ',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  // Format the price with thousand separators
                  final numericValue = value.replaceAll('.', '');
                  if (numericValue.isNotEmpty) {
                    final formattedValue = StringUtils.formatNumber(double.parse(numericValue));
                    amountController.value = TextEditingValue(
                      text: formattedValue,
                      selection: TextSelection.collapsed(offset: formattedValue.length),
                    );
                  }
                }
              },
            ),
            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                ElevatedButton(
                  onPressed: () {
                    if (amountController.text.isEmpty) {
                      DialogHelper.showErrorToast(
                        context: context,
                        message: 'Vui lòng nhập số tiền',
                      );
                      return;
                    }

                    final amount = double.parse(amountController.text.replaceAll('.', ''));
                    if (amount <= 0) {
                      DialogHelper.showErrorToast(
                        context: context,
                        message: 'Số tiền phải lớn hơn 0',
                      );
                      return;
                    }

                    if (amount > customer.debt) {
                      DialogHelper.showErrorToast(
                        context: context,
                        message: 'Số tiền không được lớn hơn tổng nợ',
                      );
                      return;
                    }

                    Navigator.pop(context, amount);
                  },
                  child: const Text('Thanh toán'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).then((amount) {
      if (amount != null) {
        _payDebt(customer, amount);
      }
    });
  }

  Future<void> _payDebt(Customer customer, double amount) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final newDebt = customer.debt - amount;
      final success = await customerProvider.updateCustomerDebt(customer.id!, newDebt);

      if (success) {
        if (mounted) {
          DialogHelper.showSuccessToast(
            context: context,
            message: 'Đã thanh toán nợ thành công',
          );
          _loadData();
        }
      } else {
        if (mounted) {
          DialogHelper.showErrorToast(
            context: context,
            message: 'Không thể thanh toán nợ: ${customerProvider.error}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showErrorToast(
          context: context,
          message: 'Đã xảy ra lỗi: $e',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết khách hàng'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Customer?>(
              future: _customerFuture,
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
                              _loadData();
                            });
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final customer = snapshot.data;
                if (customer == null) {
                  return Center(
                    child: Text(
                      'Không tìm thấy khách hàng',
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
                      // Customer header
                      Container(
                        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: ResponsiveUtils.getAdaptiveWidth(context, 60),
                                  height: ResponsiveUtils.getAdaptiveWidth(context, 60),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 24),
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name,
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                                      if (customer.phone != null && customer.phone!.isNotEmpty)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone,
                                              size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                                            Text(
                                              customer.phone!,
                                              style: TextStyle(
                                                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (customer.email != null && customer.email!.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.email,
                                                size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
                                                color: Colors.grey[600],
                                              ),
                                              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                                              Text(
                                                customer.email!,
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
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            if (customer.address != null && customer.address!.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                                  Expanded(
                                    child: Text(
                                      customer.address!,
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Ngày tạo',
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                                        Text(
                                          StringUtils.formatDate(customer.createdAt),
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 12)),
                                    decoration: BoxDecoration(
                                      color: customer.debt > 0 ? Colors.red.withOpacity(0.1) : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: customer.debt > 0 ? Border.all(color: Colors.red.withOpacity(0.3)) : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Công nợ',
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                                        Text(
                                          StringUtils.formatCurrency(customer.debt),
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                            fontWeight: FontWeight.bold,
                                            color: customer.debt > 0 ? Colors.red : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
                              icon: Icons.shopping_cart,
                              label: 'Tạo đơn',
                              onPressed: () => _navigateToCreateOrder(customer),
                              color: Colors.green,
                            ),
                            SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            CustomButton(
                              icon: Icons.edit,
                              label: 'Sửa',
                              onPressed: () => _navigateToEditCustomer(customer),
                              color: Colors.blue,
                            ),
                            SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            CustomButton(
                              icon: Icons.payment,
                              label: 'Trả nợ',
                              onPressed: () => _showPayDebtDialog(customer),
                              color: Colors.orange,
                            ),
                            SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            CustomButton(
                              icon: Icons.delete,
                              label: 'Xóa',
                              onPressed: () => _showDeleteConfirmation(customer),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),

                      // Order history
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                        ),
                        child: Text(
                          'Lịch sử đơn hàng',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),

                      FutureBuilder<List<Order>>(
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
                            return Padding(
                              padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      size: ResponsiveUtils.getAdaptiveIconSize(context, 48),
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                                    Text(
                                      'Chưa có đơn hàng nào',
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                                    ElevatedButton.icon(
                                      onPressed: () => _navigateToCreateOrder(customer),
                                      icon: const Icon(Icons.add_shopping_cart),
                                      label: const Text('Tạo đơn hàng'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            itemCount: orders.length,
                            separatorBuilder: (context, index) => SizedBox(
                              height: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                            ),
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return _buildOrderItem(order);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildOrderItem(Order order) {
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
