import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class ProductSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onFilterTap;
  final VoidCallback onAddTap;

  const ProductSearchBar({
    Key? key,
    required this.onSearch,
    required this.onFilterTap,
    required this.onAddTap,
  }) : super(key: key);

  @override
  State<ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<ProductSearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(context, 16)),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: ResponsiveUtils.getAdaptiveHeight(context, 48),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[100]
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sản phẩm...',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getAdaptiveSpacing(context, 16),
                    vertical: ResponsiveUtils.getAdaptiveSpacing(context, 12),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearch('');
                          },
                        )
                      : null,
                ),
                onChanged: widget.onSearch,
                textInputAction: TextInputAction.search,
                onSubmitted: widget.onSearch,
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
          Container(
            height: ResponsiveUtils.getAdaptiveHeight(context, 48),
            width: ResponsiveUtils.getAdaptiveHeight(context, 48),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[100]
                  : Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: widget.onFilterTap,
              tooltip: 'Lọc sản phẩm',
            ),
          ),
          SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context, 8)),
          Container(
            height: ResponsiveUtils.getAdaptiveHeight(context, 48),
            width: ResponsiveUtils.getAdaptiveHeight(context, 48),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: widget.onAddTap,
              tooltip: 'Thêm sản phẩm',
            ),
          ),
        ],
      ),
    );
  }
}
