import 'package:flutter/material.dart';

class ToastOverlay extends StatefulWidget {
  final String message;
  final bool isError;
  final bool showIcon;
  final Duration duration;

  const ToastOverlay({
    super.key,
    required this.message,
    this.isError = false,
    this.showIcon = true,
    this.duration = const Duration(seconds: 2),
  });

  // Lưu trữ tham chiếu đến overlay đang hiển thị để có thể xử lý khi hot reload
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool showIcon = true,
    Duration duration = const Duration(seconds: 2),
  }) {
    // Đảm bảo overlay cũ được xóa trước khi hiển thị overlay mới
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = OverlayEntry(
      builder: (context) => ToastOverlay(
        message: message,
        isError: isError,
        showIcon: showIcon,
        duration: duration,
      ),
    );

    _currentOverlay = overlay;
    Overlay.of(context).insert(overlay);

    Future.delayed(duration, () {
      // Kiểm tra xem overlay có còn là overlay hiện tại không
      if (_currentOverlay == overlay) {
        overlay.remove();
        _currentOverlay = null;
      }
    });
  }

  @override
  State<ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(_animation);

    _controller.forward();

    Future.delayed(widget.duration - const Duration(milliseconds: 400), () {
      _controller.reverse();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Gọi dependOnInheritedWidgetOfExactType để đảm bảo tham chiếu an toàn đến widget tổ tiên
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
    final successColor = Theme.of(context).colorScheme.primary;
    final errorColor = Theme.of(context).colorScheme.error;

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.1,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isError ? errorColor : successColor)
                        .withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showIcon) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: (widget.isError ? errorColor : successColor)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isError
                            ? Icons.error_outline
                            : Icons.check_circle,
                        color: widget.isError ? errorColor : successColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
