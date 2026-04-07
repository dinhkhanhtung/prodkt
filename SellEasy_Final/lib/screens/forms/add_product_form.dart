import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../models/custom_field.dart';
import '../../services/database_helper.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../widgets/purchase_help_dialog.dart';
import '../../utils/format_utils.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/toast_helper.dart';
import '../home_screen.dart';

class AddProductForm extends StatefulWidget {
  final Product? product;

  const AddProductForm({
    super.key,
    this.product,
  });

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _supplierController = TextEditingController();
  final _supplierPhoneController = TextEditingController();
  final _noteController = TextEditingController();
  final _nameFocusNode = FocusNode();
  String? _imagePath;
  Map<String, String> _attributes = {};
  List<CustomField> _customFields = [];
  bool _isLoading = false;
  bool _isAutoSku = true;
  bool _allowManualSku = true;
  String _selectedUnit = 'cái';
  bool _showUnit = true;
  bool _enableUnit = true;
  bool _isDuplicateProduct = false;
  Map<String, dynamic>? _existingProduct;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-focus on the name field after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_nameFocusNode.canRequestFocus) {
        _nameFocusNode.requestFocus();
      }
    });
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _nameController.addListener(_onNameChanged);
      _codeController.text = widget.product!.code ?? '';
      _quantityController.text = widget.product!.quantity.toString();
      _costPriceController.text = widget.product!.costPrice.toStringAsFixed(0);
      _sellPriceController.text = widget.product!.sellPrice.toStringAsFixed(0);
      _imagePath = widget.product!.imagePath;
      _isAutoSku = false;
      _selectedUnit = widget.product!.unit ?? 'cái';
    } else {
      _loadSkuSettings();
      _generateSku();
      _loadDefaultUnit();
      _nameController.addListener(_onNameChanged);
    }
    _loadUnitSettings();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onNameChanged() async {
    if (_nameController.text.isEmpty) {
      setState(() {
        _isDuplicateProduct = false;
        _existingProduct = null;
      });
      return;
    }

    try {
      final db = DatabaseHelper.instance;
      final product = await db.findProductByName(
        _nameController.text,
        excludeId: widget.product?.id,
      );

      setState(() {
        _isDuplicateProduct = product != null;
        _existingProduct = product;
      });

      if (_isDuplicateProduct && mounted) {
        final useExisting = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sản phẩm đã tồn tại'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sản phẩm này đã có trong kho:'),
                const SizedBox(height: 8),
                Text('Tên: ${_existingProduct!['name']}'),
                Text('Mã: ${_existingProduct!['code'] ?? 'Chưa có mã'}'),
                Text('Số lượng hiện tại: ${_existingProduct!['quantity']}'),
                Text(
                    'Giá vốn hiện tại: ${_formatPrice(_existingProduct!['cost_price'].toString())}đ'),
                Text(
                    'Giá bán: ${_formatPrice(_existingProduct!['sell_price'].toString())}đ'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                  _nameController.text = '';
                },
                child: const Text('Nhập sản phẩm mới'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context, true);
                  _codeController.text = _existingProduct!['code'] ?? '';
                  _sellPriceController.text =
                      _formatPrice(_existingProduct!['sell_price'].toString());
                  _selectedUnit = _existingProduct!['unit'] ?? 'cái';
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Nhập giá vốn mới'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Giá vốn hiện tại: ${_formatPrice(_existingProduct!['cost_price'].toString())}đ'),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _costPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Giá vốn mới *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.price_change),
                              suffixText: 'đ',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final formattedValue = _formatPrice(value);
                              if (formattedValue != value) {
                                _costPriceController.value = TextEditingValue(
                                  text: formattedValue,
                                  selection: TextSelection.collapsed(
                                    offset: formattedValue.length,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton.icon(
                          onPressed: () {
                            _costPriceController.text = _formatPrice(
                                _existingProduct!['cost_price'].toString());
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.history),
                          label: const Text('Dùng giá cũ'),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Xác nhận'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Dùng sản phẩm cũ'),
              ),
            ],
          ),
        );

        if (useExisting == false) {
          _nameController.text = '';
        }
      }
    } catch (e) {
      print('Error checking product name: $e');
    }
  }

  Future<void> _loadSkuSettings() async {
    try {
      final settings = await DatabaseHelper.instance.getSkuSettings();
      if (mounted) {
        setState(() {
          _allowManualSku = settings['allow_manual_sku'] as bool;
          _isAutoSku = !_allowManualSku;
        });
      }
    } catch (e) {
      print('Error loading SKU settings: $e');
    }
  }

  Future<void> _generateSku() async {
    if (!_isAutoSku) return;

    try {
      final sku = await DatabaseHelper.instance.generateSku();
      if (mounted) {
        setState(() {
          _codeController.text = sku;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Lỗi tạo mã SKU: ${e.toString()}');
      }
    }
  }

  Future<void> _loadDefaultUnit() async {
    try {
      final settings = await DatabaseHelper.instance.getUnitSettings();
      if (mounted) {
        setState(() {
          _selectedUnit = settings['default_unit'] as String;
        });
      }
    } catch (e) {
      print('Error loading default unit: $e');
    }
  }

  Future<void> _loadUnitSettings() async {
    try {
      final settings = await DatabaseHelper.instance.getUnitSettings();
      if (mounted) {
        setState(() {
          _showUnit = settings['show_unit'] as bool;
          _enableUnit = settings['enable_unit'] as bool;
          _selectedUnit = settings['default_unit'] as String;
        });
      }
    } catch (e) {
      print('Error loading unit settings: $e');
      // Fallback to defaults if there's an error
      setState(() {
        _showUnit = true;
        _enableUnit = true;
        _selectedUnit = 'cái';
      });
    }
  }

  Future<String?> _copyImageToAppDirectory(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/product_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = path.basename(sourcePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${timestamp}_$fileName';
      final newPath = '${imagesDir.path}/$newFileName';

      // Kiểm tra nếu ảnh đã tồn tại
      final newFile = File(newPath);
      if (await newFile.exists()) {
        await newFile.delete();
      }

      // Copy file ảnh mới
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(newPath);
        print('Image copied successfully to: $newPath');
        return 'file://$newPath';
      } else {
        print('Source image does not exist: $sourcePath');
        return null;
      }
    } catch (e) {
      print('Error copying image: $e');
      return null;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final customFields = await DatabaseHelper.instance.getCustomFields();
      if (widget.product != null) {
        final attributes = await DatabaseHelper.instance.getProductAttributes(
          widget.product!.id!,
        );
        setState(() {
          _attributes = Map.fromEntries(
            attributes.map(
                (a) => MapEntry(a['name']! as String, a['value']! as String)),
          );
        });
      }
      setState(() {
        _customFields =
            customFields.map((f) => CustomField.fromMap(f)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastHelper.showError(context, 'Đã xảy ra lỗi: ${e.toString()}');
      }
    }
  }

  String _formatPrice(String text) {
    if (text.isEmpty) return '';
    // Chỉ giữ lại các chữ số
    final cleanText = text.replaceAll(RegExp(r'[^0-9]'), '');
    // Parse thành số và format với dấu chấm phân cách hàng nghìn
    final number = int.tryParse(cleanText);
    if (number == null) return '';
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // Nếu đang edit và có ảnh cũ, xóa ảnh cũ trước khi lưu ảnh mới
        if (widget.product != null &&
            widget.product!.imagePath != null &&
            widget.product!.imagePath != _imagePath) {
          try {
            final oldImageFile =
                File(widget.product!.imagePath!.replaceFirst('file://', ''));
            if (await oldImageFile.exists()) {
              await oldImageFile.delete();
            }
          } catch (e) {
            print('Error deleting old image: $e');
          }
        }

        // Lưu ảnh mới vào thư mục của ứng dụng
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${appDir.path}/product_images');
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }

        final fileName =
            'product_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final savedImage =
            await File(image.path).copy('${imagesDir.path}/$fileName');

        setState(() {
          _imagePath = 'file://${savedImage.path}';
        });
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Lỗi chọn ảnh: ${e.toString()}');
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final code = _codeController.text.trim();
      final quantity = int.parse(_quantityController.text);

      // Parse giá trị số một cách an toàn
      String costPriceText =
          _costPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      String sellPriceText =
          _sellPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');

      final costPrice =
          costPriceText.isEmpty ? 0.0 : double.parse(costPriceText);
      final sellPrice =
          sellPriceText.isEmpty ? 0.0 : double.parse(sellPriceText);

      final supplierName = _supplierController.text.trim();
      final supplierPhone = _supplierPhoneController.text.trim();
      final note = _noteController.text.trim();

      if (widget.product != null) {
        // Cập nhật sản phẩm
        await DatabaseHelper.instance.updateProduct(
          widget.product!.id!,
          {
            'name': name,
            'normalized_name': name.toLowerCase(),
            'code': code.isEmpty ? null : code,
            'quantity': quantity,
            'cost_price': costPrice,
            'sell_price': sellPrice,
            'image_path': _imagePath,
            'unit': _selectedUnit,
          },
          attributes: _attributes,
          supplierName: supplierName.isEmpty ? null : supplierName,
          supplierPhone: supplierPhone.isEmpty ? null : supplierPhone,
          note: note.isEmpty ? null : note,
        );
      } else {
        // Thêm sản phẩm mới
        if (_isDuplicateProduct && _existingProduct != null) {
          // Cập nhật số lượng cho sản phẩm đã tồn tại
          await DatabaseHelper.instance.addProductStock(
            _existingProduct!['id'] as int,
            quantity,
            costPrice,
            supplierName: supplierName.isEmpty ? null : supplierName,
            supplierPhone: supplierPhone.isEmpty ? null : supplierPhone,
            note: note.isEmpty ? null : note,
          );
        } else {
          // Thêm sản phẩm mới
          await DatabaseHelper.instance.insertProduct(
            {
              'name': name,
              'normalized_name': name.toLowerCase(),
              'code': code.isEmpty ? null : code,
              'quantity': quantity,
              'cost_price': costPrice,
              'sell_price': sellPrice,
              'image_path': _imagePath,
              'entry_date': DateTime.now().toIso8601String(),
              'unit': _selectedUnit,
            },
            attributes: _attributes,
            supplierName: supplierName.isEmpty ? null : supplierName,
            supplierPhone: supplierPhone.isEmpty ? null : supplierPhone,
            note: note.isEmpty ? null : note,
          );
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastHelper.showError(context, 'Lỗi: ${e.toString()}');
      }
      rethrow;
    }
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _codeController.clear();
      _quantityController.clear();
      _costPriceController.clear();
      _sellPriceController.clear();
      _supplierController.clear();
      _supplierPhoneController.clear();
      _noteController.clear();
      _imagePath = null;
      _attributes = {};
      _formKey.currentState?.reset();
    });
  }

  bool _hasChanges() {
    if (widget.product != null) {
      // Check if editing an existing product
      final currentCostPrice = double.tryParse(
              _costPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          0.0;
      final currentSellPrice = double.tryParse(
              _sellPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          0.0;

      // So sánh giá trị số trực tiếp
      final costPriceChanged =
          (currentCostPrice - widget.product!.costPrice).abs() > 0.01;
      final sellPriceChanged =
          (currentSellPrice - widget.product!.sellPrice).abs() > 0.01;

      return _nameController.text != widget.product!.name ||
          _codeController.text != (widget.product!.code ?? '') ||
          _quantityController.text != widget.product!.quantity.toString() ||
          costPriceChanged ||
          sellPriceChanged ||
          _imagePath != widget.product!.imagePath ||
          _supplierController.text.isNotEmpty ||
          _supplierPhoneController.text.isNotEmpty ||
          _noteController.text.isNotEmpty ||
          _selectedUnit != widget.product!.unit;
    } else {
      // Check if adding a new product
      return _nameController.text.isNotEmpty ||
          _codeController.text.isNotEmpty ||
          _quantityController.text.isNotEmpty ||
          _costPriceController.text.isNotEmpty ||
          _sellPriceController.text.isNotEmpty ||
          _imagePath != null ||
          _supplierController.text.isNotEmpty ||
          _supplierPhoneController.text.isNotEmpty ||
          _noteController.text.isNotEmpty ||
          _attributes.isNotEmpty ||
          _selectedUnit != 'cái';
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges()) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text(
            'Bạn có muốn hủy nhập hàng?\nMọi thay đổi sẽ không được lưu.'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.edit),
            label: const Text('Tiếp tục nhập'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.cancel),
            label: const Text('Hủy nhập'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nhập hàng'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const PurchaseHelpDialog(),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.only(
                      left: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                      right: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                      top: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                      bottom: ResponsiveUtils.getAdaptiveSpacing(context, 100)),
                  children: [
                    InkWell(
                      onTap: () async {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SafeArea(
                              child: Wrap(
                                children: <Widget>[
                                  ListTile(
                                    leading: const Icon(Icons.photo_camera),
                                    title: const Text('Chụp ảnh'),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      final picker = ImagePicker();
                                      final pickedFile = await picker.pickImage(
                                        source: ImageSource.camera,
                                      );
                                      if (pickedFile != null) {
                                        setState(() {
                                          _imagePath = pickedFile.path;
                                        });
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('Chọn từ thư viện'),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      await _pickImage();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        height:
                            ResponsiveUtils.getAdaptiveSpacing(context, 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              child: _imagePath != null
                                  ? Image.file(
                                      File(_imagePath!
                                          .replaceFirst('file://', '')),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        print('Error loading image: $error');
                                        return Center(
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 48,
                                            color: Colors.grey.withOpacity(0.3),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[800]
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate,
                                              size: ResponsiveUtils
                                                  .getAdaptiveIconSize(
                                                      context, 64),
                                              color: (Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.white70
                                                      : Colors.black54)
                                                  .withOpacity(0.3),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Thêm ảnh',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontSize: ResponsiveUtils
                                                    .getAdaptiveFontSize(
                                                        context, 16),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Chụp ảnh hoặc chọn từ thư viện',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white70
                                                    : Colors.black54,
                                                fontSize: ResponsiveUtils
                                                    .getAdaptiveFontSize(
                                                        context, 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[700]!.withAlpha(230)
                                      : Colors.black.withAlpha(153),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: ResponsiveUtils.getAdaptiveIconSize(
                                      context, 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Tên sản phẩm *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.inventory_2),
                        labelStyle: TextStyle(
                          color:
                              _nameController.text.isEmpty ? Colors.red : null,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên sản phẩm';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: 'Số lượng *',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.numbers),
                              labelStyle: TextStyle(
                                color: _quantityController.text.isEmpty
                                    ? Colors.red
                                    : null,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nhập số lượng';
                              }
                              final quantity = double.tryParse(value);
                              if (quantity == null || quantity <= 0) {
                                return 'Số lượng không hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_showUnit) ...[
                          SizedBox(
                              width: ResponsiveUtils.getAdaptiveSpacing(
                                  context, 16)),
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Đơn vị',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.straighten),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'cái', child: Text('Cái')),
                                DropdownMenuItem(
                                    value: 'chiếc', child: Text('Chiếc')),
                                DropdownMenuItem(
                                    value: 'kg', child: Text('Kilogram (kg)')),
                                DropdownMenuItem(
                                    value: 'g', child: Text('Gram (g)')),
                                DropdownMenuItem(
                                    value: 'm', child: Text('Mét (m)')),
                                DropdownMenuItem(
                                    value: 'cm', child: Text('Centimét (cm)')),
                              ],
                              onChanged: _enableUnit
                                  ? (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedUnit = value;
                                        });
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _costPriceController,
                            decoration: InputDecoration(
                              labelText: 'Giá nhập *',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.price_change),
                              suffixText: 'đ',
                              labelStyle: TextStyle(
                                color: _costPriceController.text.isEmpty
                                    ? Colors.red
                                    : null,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nhập giá nhập';
                              }
                              final price =
                                  double.tryParse(value.replaceAll('.', ''));
                              if (price == null || price <= 0) {
                                return 'Giá không hợp lệ';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.isEmpty) {
                                _costPriceController.text = '';
                                return;
                              }
                              // Chỉ format khi giá trị thực sự thay đổi
                              final numericValue =
                                  value.replaceAll(RegExp(r'[^0-9]'), '');
                              if (numericValue.isNotEmpty) {
                                final formattedValue =
                                    _formatPrice(numericValue);
                                if (formattedValue != value) {
                                  _costPriceController.value = TextEditingValue(
                                    text: formattedValue,
                                    selection: TextSelection.collapsed(
                                      offset: formattedValue.length,
                                    ),
                                  );
                                }
                              }
                              setState(() {}); // Cập nhật màu label
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    TextFormField(
                      controller: _sellPriceController,
                      decoration: InputDecoration(
                        labelText: 'Giá bán *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.sell),
                        suffixText: 'đ',
                        labelStyle: TextStyle(
                          color: _sellPriceController.text.isEmpty
                              ? Colors.red
                              : null,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nhập giá bán';
                        }
                        final price =
                            double.tryParse(value.replaceAll('.', ''));
                        if (price == null || price <= 0) {
                          return 'Giá không hợp lệ';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value.isEmpty) {
                          _sellPriceController.text = '';
                          return;
                        }
                        // Chỉ format khi giá trị thực sự thay đổi
                        final numericValue =
                            value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (numericValue.isNotEmpty) {
                          final formattedValue = _formatPrice(numericValue);
                          if (formattedValue != value) {
                            _sellPriceController.value = TextEditingValue(
                              text: formattedValue,
                              selection: TextSelection.collapsed(
                                offset: formattedValue.length,
                              ),
                            );
                          }
                        }
                        setState(() {}); // Cập nhật màu label
                      },
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codeController,
                            enabled: _allowManualSku && !_isAutoSku,
                            decoration: const InputDecoration(
                              labelText: 'Mã SKU',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.qr_code),
                            ),
                          ),
                        ),
                        if (_allowManualSku && widget.product == null) ...[
                          SizedBox(
                              width: ResponsiveUtils.getAdaptiveSpacing(
                                  context, 16)),
                          IconButton(
                            icon: Icon(
                              _isAutoSku ? Icons.lock : Icons.lock_open,
                              color: _isAutoSku ? Colors.blue : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isAutoSku = !_isAutoSku;
                                if (_isAutoSku) {
                                  _generateSku();
                                }
                              });
                            },
                            tooltip: _isAutoSku
                                ? 'Tắt tự động tạo SKU'
                                : 'Bật tự động tạo SKU',
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _isAutoSku ? _generateSku : null,
                            tooltip: 'Tạo SKU mới',
                          ),
                        ],
                      ],
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    Text(
                      'Thông tin nhập hàng:',
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    TextFormField(
                      controller: _supplierController,
                      decoration: const InputDecoration(
                        labelText: 'Tên nhà cung cấp',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                        hintText: 'Nhập tên nhà cung cấp nếu có',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    TextFormField(
                      controller: _supplierPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại nhà cung cấp',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        hintText: 'Nhập SĐT nhà cung cấp nếu có',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                        hintText: 'Ghi chú về đơn nhập hàng (nếu có)',
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                    if (_customFields.isNotEmpty) ...[
                      Text(
                        'Thuộc tính:',
                        style: TextStyle(
                          fontSize:
                              ResponsiveUtils.getAdaptiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                          height:
                              ResponsiveUtils.getAdaptiveSpacing(context, 16)),
                      ..._customFields.map((field) {
                        final controller = TextEditingController(
                          text: _attributes[field.name] ?? '',
                        );
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: ResponsiveUtils.getAdaptiveSpacing(
                                  context, 16)),
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: field.name,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.label),
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (value.isEmpty) {
                                  _attributes.remove(field.name);
                                } else {
                                  _attributes[field.name] = value;
                                }
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
        bottomSheet: Container(
          padding:
              EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) {
                            ToastHelper.showError(
                              context,
                              'Vui lòng nhập đầy đủ thông tin bắt buộc',
                            );
                            return;
                          }

                          try {
                            await _saveProduct();
                            if (!mounted) return;
                            Navigator.pop(context, true);
                            ToastHelper.showSuccess(
                              context,
                              'Đã lưu sản phẩm',
                            );
                          } catch (e) {
                            // Lỗi đã được xử lý trong _saveProduct()
                          }
                        },
                  icon: Icon(Icons.save,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 18)),
                  label: Text(
                    'Lưu',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 14),
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) {
                            ToastHelper.showError(
                              context,
                              'Vui lòng nhập đầy đủ thông tin bắt buộc',
                            );
                            return;
                          }

                          try {
                            await _saveProduct();
                            if (!mounted) return;
                            _resetForm();
                            ToastHelper.showSuccess(
                              context,
                              'Đã lưu sản phẩm. Tiếp tục nhập hàng mới.',
                            );
                          } catch (e) {
                            // Lỗi đã được xử lý trong _saveProduct()
                          }
                        },
                  icon: Icon(Icons.add_circle_outline,
                      size: ResponsiveUtils.getAdaptiveIconSize(context, 18)),
                  label: Text(
                    'Nhập hàng khác',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 14),
                    ),
                  ),
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
}
