import 'package:flutter/material.dart';

class DialogHelper {
  // Lưu trữ tham chiếu đến dialog đang hiển thị để có thể xử lý khi hot reload
  static BuildContext? _lastDialogContext;
  static Future<T?> showAnimatedDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    Duration? transitionDuration,
  }) {
    // Lưu lại context của dialog để có thể xử lý khi hot reload
    _lastDialogContext = context;

    // Tạo một builder mới bao bọc builder gốc để xử lý hot reload tốt hơn
    WidgetBuilder safeBuilder = (BuildContext dialogContext) {
      return Builder(
        builder: (BuildContext innerContext) {
          // Sử dụng innerContext để đảm bảo có tham chiếu đến các widget tổ tiên
          // khi hot reload xảy ra
          MediaQuery.of(innerContext);
          Theme.of(innerContext);
          return builder(dialogContext);
        },
      );
    };

    return showGeneralDialog<T>(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation.drive(
              Tween<double>(begin: 0.95, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeOut)),
            ),
            child: safeBuilder(context),
          ),
        );
      },
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ??
          Colors.black.withOpacity(
              0.5), // TODO: Sửa thành withAlpha trong phiên bản mới hơn
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 150),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    );
  }

  static Future<T?> showAnimatedBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
  }) {
    // Lưu lại context của bottom sheet để có thể xử lý khi hot reload
    _lastDialogContext = context;

    // Tạo một builder an toàn để xử lý hot reload tốt hơn
    Widget Function(BuildContext) safeBuilder = (BuildContext sheetContext) {
      return Builder(
        builder: (BuildContext innerContext) {
          // Sử dụng innerContext để đảm bảo có tham chiếu đến các widget tổ tiên
          MediaQuery.of(innerContext);
          Theme.of(innerContext);
          return builder(sheetContext);
        },
      );
    };

    return showModalBottomSheet<T>(
      context: context,
      builder: safeBuilder,
      isScrollControlled: isScrollControlled,
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: Navigator.of(context),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  static void showAnimatedSnackBar({
    required BuildContext context,
    required Widget content,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        animation: CurvedAnimation(
          parent: ModalRoute.of(context)?.animation ??
              const AlwaysStoppedAnimation(1),
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  static Widget buildAnimatedTooltip({
    required Widget child,
    required String message,
    Duration? duration,
  }) {
    return Tooltip(
      message: message,
      waitDuration: duration ?? const Duration(milliseconds: 200),
      showDuration: const Duration(milliseconds: 2000),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
      child: child,
    );
  }

  static Future<T?> showAnimatedAlertDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showAnimatedDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions ??
            [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('OK'),
              ),
            ],
      ),
    );
  }

  static Future<T?> showAnimatedConfirmationDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
  }) {
    return showAnimatedDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.cancel_outlined),
            label: Text(cancelText ?? 'Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_circle),
            label: Text(confirmText ?? 'Xác nhận'),
          ),
        ],
      ),
    );
  }

  static Future<T?> showAnimatedLoadingDialog<T>({
    required BuildContext context,
    String? message,
    bool barrierDismissible = false,
  }) {
    return showAnimatedDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => PopScope(
        canPop: barrierDismissible,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildAnimatedContainer({
    required Widget child,
    Duration? duration,
    EdgeInsets? padding,
    BoxDecoration? decoration,
  }) {
    return AnimatedContainer(
      duration: duration ?? const Duration(milliseconds: 300),
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }

  static Widget buildAnimatedOpacity({
    required Widget child,
    required bool visible,
    Duration? duration,
  }) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: duration ?? const Duration(milliseconds: 200),
      child: child,
    );
  }

  static Widget buildAnimatedScale({
    required Widget child,
    required bool visible,
    Duration? duration,
  }) {
    return AnimatedScale(
      scale: visible ? 1.0 : 0.95,
      duration: duration ?? const Duration(milliseconds: 200),
      child: child,
    );
  }
}
