import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/models/product_model.dart';
import '../../providers/product_provider.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _unitController = TextEditingController(text: 'cái');
  
  String? _imagePath;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _quantityController.dispose();
    _sellPriceController.dispose();
    _costPriceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      DialogHelper.showErrorToast(
        context: context,
        message: 'Không thể chọn ảnh: $e',
      );
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final code = _codeController.text.trim();
      final quantity = int.parse(_quantityController.text.trim());
      final sellPrice = double.parse(_sellPriceController.text.trim().replaceAll('.', ''));
      final costPrice = double.parse(_costPriceController.text.trim().replaceAll('.', ''));
      final unit = _unitController.text.trim();

      final product = Product(
        name: name,
        normalizedName: StringUtils.normalize(name),
        code: code.isNotEmpty ? code : null,
        quantity: quantity,
        sellPrice: sellPrice,
        costPrice: costPrice,
        imagePath: _imagePath,
        entryDate: StringUtils.getCurrentDate(),
        unit: unit,
      );

      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final success = await productProvider.addProduct(product);

      if (success) {
        if (mounted) {
          DialogHelper.showSuccessToast(
            context: context,
            message: 'Đã thêm sản phẩm thành công',
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          DialogHelper.showErrorToast(
            context: context,
            message: 'Không thể thêm sản phẩm: ${productProvider.error}',
          );
        }
      }
    } catch (e) {
      DialogHelper.showErrorToast(
        context: context,
        message: 'Đã xảy ra lỗi: $e',
      );
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
        title: const Text('Thêm sản phẩm'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: ResponsiveUtils.getAdaptiveWidth(context, 150),
                          height: ResponsiveUtils.getAdaptiveWidth(context, 150),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _imagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_imagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                                  ),
                                )
                              : _buildImagePlaceholder(),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    
                    // Product name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên sản phẩm *',
                        hintText: 'Nhập tên sản phẩm',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên sản phẩm';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    
                    // Product code
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Mã sản phẩm',
                        hintText: 'Nhập mã sản phẩm (không bắt buộc)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    
                    // Quantity and unit
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Số lượng *',
                              hintText: 'Nhập số lượng',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập số lượng';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Số lượng không hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        Expanded(
                          child: TextFormField(
                            controller: _unitController,
                            decoration: const InputDecoration(
                              labelText: 'Đơn vị',
                              hintText: 'Đơn vị',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    
                    // Sell price and cost price
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sellPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Giá bán *',
                              hintText: 'Nhập giá bán',
                              border: OutlineInputBorder(),
                              prefixText: '₫ ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập giá bán';
                              }
                              if (double.tryParse(value.replaceAll('.', '')) == null) {
                                return 'Giá bán không hợp lệ';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                // Format the price with thousand separators
                                final numericValue = value.replaceAll('.', '');
                                if (numericValue.isNotEmpty) {
                                  final formattedValue = StringUtils.formatNumber(double.parse(numericValue));
                                  _sellPriceController.value = TextEditingValue(
                                    text: formattedValue,
                                    selection: TextSelection.collapsed(offset: formattedValue.length),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                        Expanded(
                          child: TextFormField(
                            controller: _costPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Giá vốn *',
                              hintText: 'Nhập giá vốn',
                              border: OutlineInputBorder(),
                              prefixText: '₫ ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập giá vốn';
                              }
                              if (double.tryParse(value.replaceAll('.', '')) == null) {
                                return 'Giá vốn không hợp lệ';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                // Format the price with thousand separators
                                final numericValue = value.replaceAll('.', '');
                                if (numericValue.isNotEmpty) {
                                  final formattedValue = StringUtils.formatNumber(double.parse(numericValue));
                                  _costPriceController.value = TextEditingValue(
                                    text: formattedValue,
                                    selection: TextSelection.collapsed(offset: formattedValue.length),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 32)),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Lưu sản phẩm',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
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

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: ResponsiveUtils.getAdaptiveIconSize(context, 32),
          color: Colors.grey[400],
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
        Text(
          'Thêm ảnh',
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
