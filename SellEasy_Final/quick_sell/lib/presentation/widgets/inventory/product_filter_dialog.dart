import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class ProductFilterDialog extends StatefulWidget {
  final String initialCategory;
  final String initialSortBy;
  final Function(String category, String sortBy) onApply;

  const ProductFilterDialog({
    super.key,
    required this.initialCategory,
    required this.initialSortBy,
    required this.onApply,
  });

  @override
  State<ProductFilterDialog> createState() => _ProductFilterDialogState();
}

class _ProductFilterDialogState extends State<ProductFilterDialog> {
  late String _selectedCategory;
  late String _selectedSortBy;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedSortBy = widget.initialSortBy;
  }

  @override
  Widget build(BuildContext context) {
    final categoryOptions = ['Tất cả', 'Áo', 'Quần', 'Giày', 'Phụ kiện'];
    final sortOptions = [
      {'value': 'name_asc', 'label': 'Tên (A-Z)'},
      {'value': 'name_desc', 'label': 'Tên (Z-A)'},
      {'value': 'price_asc', 'label': 'Giá (Thấp - Cao)'},
      {'value': 'price_desc', 'label': 'Giá (Cao - Thấp)'},
      {'value': 'quantity_asc', 'label': 'Số lượng (Ít - Nhiều)'},
      {'value': 'quantity_desc', 'label': 'Số lượng (Nhiều - Ít)'},
    ];

    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lọc sản phẩm',
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          Text(
            'Danh mục',
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
          Wrap(
            spacing: ResponsiveUtils.getAdaptiveSpacing(context, 8),
            children: categoryOptions.map((category) {
              return ChoiceChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  }
                },
              );
            }).toList(),
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          Text(
            'Sắp xếp theo',
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
          ...sortOptions.map((option) {
            return RadioListTile<String>(
              title: Text(option['label'] as String),
              value: option['value'] as String,
              groupValue: _selectedSortBy,
              onChanged: (value) {
                setState(() {
                  _selectedSortBy = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }).toList(),
          SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Hủy'),
              ),
              SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
              FilledButton(
                onPressed: () {
                  widget.onApply(_selectedCategory, _selectedSortBy);
                  Navigator.pop(context);
                },
                child: const Text('Áp dụng'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
