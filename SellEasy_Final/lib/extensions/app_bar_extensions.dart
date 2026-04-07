import 'package:flutter/material.dart';

/// Extension để áp dụng các thuộc tính nhất quán cho AppBar trong toàn bộ ứng dụng
extension AppBarExtensions on AppBar {
  /// Tạo một AppBar mới với các thuộc tính được thiết lập để đảm bảo không có hiệu ứng ám màu
  /// trong chế độ tối và có giao diện nhất quán
  static AppBar noColorTinting({
    required BuildContext context,
    required Widget title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
    double? elevation,
    PreferredSizeWidget? bottom,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      elevation: elevation,
      bottom: bottom,
      // Đảm bảo không có hiệu ứng ám màu trong chế độ tối
      backgroundColor: isDark ? Colors.grey[900] : Theme.of(context).colorScheme.primary,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
    );
  }
}
