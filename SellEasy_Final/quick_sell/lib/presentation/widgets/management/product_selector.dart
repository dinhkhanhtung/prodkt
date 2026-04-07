import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../data/models/product_model.dart';
import '../../providers/product_provider.dart';

class ProductSelector extends StatefulWidget {
  final Function(Product, int) onProductSelected;
  final List<int> excludeProductIds;

  const ProductSelector({
    Key? key,
    required this.onProductSelected,
    this.excludeProductIds = const [],
  }) : super(key: key);

  @override
  State<ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<ProductSelector> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  bool _isSearching = false;
  List<Product> _filteredProducts = [];
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredProducts = [];
        _selectedProduct = null;
      });
    } else {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final products = productProvider.products;
      
      setState(() {
        _isSearching = true;
        _filteredProducts = products.where((product) {
          // Exclude products that are already in the order
          if (widget.excludeProductIds.contains(product.id)) {
            return false;
          }
          
          final nameMatch = product.normalizedName.contains(query);
          final codeMatch = product.code?.toLowerCase().contains(query) ?? false;
          return nameMatch || codeMatch;
        }).toList();
      });
    }
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedProduct = product;
      _quantityController.text = '1';
    });
  }

  void _addProduct() {
    if (_selectedProduct == null) return;
    
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity <= 0) return;
    
    widget.onProductSelected(_selectedProduct!, quantity);
    
    // Reset
    _searchController.clear();
    _quantityController.text = '1';
    setState(() {
      _selectedProduct = null;
      _isSearching = false;
      _filteredProducts = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm sản phẩm...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.getAdaptiveSpacing(context, 12),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
                autofocus: true,
              ),
            ),
          ],
        ),
        
        if (_isSearching && _filteredProducts.isNotEmpty)
          _buildSearchResults(),
          
        if (_selectedProduct != null)
          _buildSelectedProduct(),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: EdgeInsets.only(top: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
      constraints: BoxConstraints(
        maxHeight: ResponsiveUtils.getAdaptiveHeight(context, 200),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        itemCount: _filteredProducts.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return ListTile(
            leading: Container(
              width: ResponsiveUtils.getAdaptiveWidth(context, 40),
              height: ResponsiveUtils.getAdaptiveWidth(context, 40),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: product.imagePath != null && product.imagePath!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(product.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      color: Colors.grey,
                    ),
            ),
            title: Text(product.name),
            subtitle: Text(
              '${StringUtils.formatCurrency(product.sellPrice)} - SL: ${product.quantity} ${product.unit}',
            ),
            trailing: product.quantity <= 0
                ? Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 8),
                      vertical: ResponsiveUtils.getAdaptiveSpacing(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Hết hàng',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: product.quantity > 0 ? () => _selectProduct(product) : null,
            enabled: product.quantity > 0,
          );
        },
      ),
    );
  }

  Widget _buildSelectedProduct() {
    final product = _selectedProduct!;
    
    return Container(
      margin: EdgeInsets.only(top: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 12)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ResponsiveUtils.getAdaptiveWidth(context, 50),
                height: ResponsiveUtils.getAdaptiveWidth(context, 50),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: product.imagePath != null && product.imagePath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          File(product.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.image,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.image,
                        color: Colors.grey,
                      ),
              ),
              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 12)),
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
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                    Text(
                      'Giá: ${StringUtils.formatCurrency(product.sellPrice)}',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
                    Text(
                      'Tồn kho: ${product.quantity} ${product.unit}',
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
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Số lượng',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixText: product.unit,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              ElevatedButton(
                onPressed: _addProduct,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                    horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Thêm'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
