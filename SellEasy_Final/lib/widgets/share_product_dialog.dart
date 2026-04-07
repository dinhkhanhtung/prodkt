import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import '../services/grok_service.dart';
import '../services/database_helper.dart';
import '../utils/toast_helper.dart';

class ShareProductDialog extends StatefulWidget {
  final Map<String, dynamic> product;

  const ShareProductDialog({
    super.key,
    required this.product,
  });

  @override
  State<ShareProductDialog> createState() => _ShareProductDialogState();
}

class _ShareProductDialogState extends State<ShareProductDialog> {
  String _selectedStyle = 'Gần gũi';
  String _generatedPost = '';
  bool _isLoading = false;

  Future<void> _generatePost() async {
    setState(() => _isLoading = true);

    try {
      final attributes = await DatabaseHelper.instance.getProductAttributes(
        widget.product['id'] as int,
      );

      // final post = await GrokService.generateProductPost(
      //   productName: widget.product['name'] as String,
      //   price: widget.product['sell_price'] as double,
      //   quantity: widget.product['quantity'] as int,
      //   style: _selectedStyle,
      //   attributes: attributes,
      // );

      // Temporary placeholder text
      final post = '''
${widget.product['name']}
Giá: ${widget.product['sell_price']}đ
Số lượng: ${widget.product['quantity']}
${attributes.map((attr) => '${attr['name']}: ${attr['value']}').join('\n')}
''';

      setState(() {
        _generatedPost = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastHelper.showError(
            context, 'Không thể tạo bài viết. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _generatedPost));
    if (mounted) {
      ToastHelper.showSuccess(context, 'Đã sao chép vào bộ nhớ tạm');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chia sẻ sản phẩm'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedStyle,
            decoration: const InputDecoration(
              labelText: 'Phong cách',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Gần gũi',
                child: Text('Gần gũi'),
              ),
              DropdownMenuItem(
                value: 'Chuyên nghiệp',
                child: Text('Chuyên nghiệp'),
              ),
              DropdownMenuItem(
                value: 'Khuyến mãi',
                child: Text('Khuyến mãi'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedStyle = value);
              }
            },
          ),
          const SizedBox(height: 16),
          if (_generatedPost.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(_generatedPost),
            ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          label: const Text('Đóng'),
        ),
        if (_generatedPost.isNotEmpty)
          TextButton.icon(
            onPressed: _copyToClipboard,
            icon: const Icon(Icons.copy),
            label: const Text('Sao chép'),
          ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _generatePost,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.refresh),
          label: Text(_generatedPost.isEmpty ? 'Tạo bài viết' : 'Tạo lại'),
        ),
      ],
    );
  }
}
