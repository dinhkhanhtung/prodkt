import 'package:flutter/material.dart';

class AnimatedFormDialog extends StatefulWidget {
  final String title;
  final Widget child;
  final VoidCallback? onSave;
  final bool isScrollable;
  final double maxWidth;
  final double? maxHeight;

  const AnimatedFormDialog({
    Key? key,
    required this.title,
    required this.child,
    this.onSave,
    this.isScrollable = true,
    this.maxWidth = 600,
    this.maxHeight,
  }) : super(key: key);

  @override
  State<AnimatedFormDialog> createState() => _AnimatedFormDialogState();
}

class _AnimatedFormDialogState extends State<AnimatedFormDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Gọi dependOnInheritedWidgetOfExactType để đảm bảo tham chiếu an toàn đến widget tổ tiên
    // khi hot reload xảy ra
    context.dependOnInheritedWidgetOfExactType<MediaQuery>();
    Theme.of(context); // Lấy theme hiện tại để đảm bảo tham chiếu an toàn
  }

  @override
  void dispose() {
    // Đảm bảo controller được dispose an toàn
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: widget.maxWidth,
                  maxHeight: widget.maxHeight ??
                      MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    if (widget.isScrollable)
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: widget.child,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: widget.child,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(
            0.1), // TODO: Sửa thành withAlpha(25) hoặc withAlpha trong phiên bản mới hơn
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (widget.onSave != null)
            TextButton.icon(
              onPressed: widget.onSave,
              icon: const Icon(Icons.save),
              label: const Text('Lưu'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }
}
