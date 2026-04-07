import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/custom_button.dart';
import 'edit_product_screen.dart';
import 'product_history_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product?> _productFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    _productFuture = productProvider.getProductById(widget.productId);
  }

  void _showDeleteConfirmation(Product product) {
    DialogHelper.showConfirmDialog(
      context: context,
      title: 'Xóa sản phẩm',
      content: 'Bạn có chắc chắn muốn xóa sản phẩm "${product.name}" không?',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteProduct(product);
      }
    });
  }

  Future<void> _deleteProduct(Product product) async {
    setState(() {
      _isLoading = true;
    });

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final success = await productProvider.deleteProduct(product.id!);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        DialogHelper.showSuccessToast(
          context: context,
          message: 'Đã xóa sản phẩm thành công',
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        DialogHelper.showErrorToast(
          context: context,
          message: 'Không thể xóa sản phẩm: ${productProvider.error}',
        );
      }
    }
  }

  void _navigateToEditProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    ).then((_) {
      _loadProduct();
      setState(() {});
    });
  }

  void _navigateToProductHistory(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductHistoryScreen(productId: product.id!),
      ),
    );
  }

  void _createOrder(Product product) {
    // TODO: Implement create order functionality
    DialogHelper.showToast(
      context: context,
      message: 'Tính năng đang phát triển',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Product?>(
              future: _productFuture,
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
                              _loadProduct();
                            });
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final product = snapshot.data;
                if (product == null) {
                  return Center(
                    child: Text(
                      'Không tìm thấy sản phẩm',
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
                      // Product image
                      Container(
                        width: double.infinity,
                        height: ResponsiveUtils.getAdaptiveHeight(context, 250),
                        color: Colors.grey[200],
                        child: product.imagePath != null && product.imagePath!.isNotEmpty
                            ? Image.file(
                                File(product.imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),

                      // Product info
                      Padding(
                        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 20),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _buildStatusBadge(product),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                            if (product.code != null && product.code!.isNotEmpty)
                              Text(
                                'Mã: ${product.code}',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                                  color: Colors.grey[600],
                                ),
                              ),
                            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            
                            // Price and cost
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    context,
                                    'Giá bán',
                                    StringUtils.formatCurrency(product.sellPrice),
                                    Icons.sell,
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                                Expanded(
                                  child: _buildInfoCard(
                                    context,
                                    'Giá vốn',
                                    StringUtils.formatCurrency(product.costPrice),
                                    Icons.money,
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                            
                            // Quantity and profit
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    context,
                                    'Số lượng',
                                    '${product.quantity} ${product.unit}',
                                    Icons.inventory_2,
                                    Colors.blue,
                                  ),
                                ),
                                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                                Expanded(
                                  child: _buildInfoCard(
                                    context,
                                    'Lợi nhuận',
                                    '${product.getProfitMargin().toStringAsFixed(1)}%',
                                    Icons.trending_up,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
                            
                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomButton(
                                  icon: Icons.shopping_cart,
                                  label: 'Tạo đơn',
                                  onPressed: () => _createOrder(product),
                                  color: Colors.green,
                                ),
                                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                                CustomButton(
                                  icon: Icons.edit,
                                  label: 'Sửa',
                                  onPressed: () => _navigateToEditProduct(product),
                                  color: Colors.blue,
                                ),
                                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                                CustomButton(
                                  icon: Icons.history,
                                  label: 'Lịch sử',
                                  onPressed: () => _navigateToProductHistory(product),
                                  color: Colors.orange,
                                ),
                                SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                                CustomButton(
                                  icon: Icons.delete,
                                  label: 'Xóa',
                                  onPressed: () => _showDeleteConfirmation(product),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 24)),
                            
                            // Additional info
                            Text(
                              'Thông tin thêm',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                            _buildInfoRow(
                              context,
                              'Ngày nhập',
                              StringUtils.formatDate(product.entryDate),
                              Icons.calendar_today,
                            ),
                            SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
                            _buildInfoRow(
                              context,
                              'Giá trị tồn kho',
                              StringUtils.formatCurrency(product.costPrice * product.quantity),
                              Icons.attach_money,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.image,
        size: ResponsiveUtils.getAdaptiveIconSize(context, 64),
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildStatusBadge(Product product) {
    final status = product.getStatus();
    Color color;
    String text;

    switch (status) {
      case 'in_stock':
        color = Colors.green;
        text = 'Còn hàng';
        break;
      case 'low_stock':
        color = Colors.orange;
        text = 'Sắp hết';
        break;
      case 'out_of_stock':
        color = Colors.red;
        text = 'Hết hàng';
        break;
      default:
        color = Colors.grey;
        text = 'Không xác định';
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
        text,
        style: TextStyle(
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 12)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
                color: color,
              ),
              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: ResponsiveUtils.getAdaptiveIconSize(context, 16),
          color: Colors.grey[600],
        ),
        SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
            color: Colors.grey[600],
          ),
        ),
        SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
