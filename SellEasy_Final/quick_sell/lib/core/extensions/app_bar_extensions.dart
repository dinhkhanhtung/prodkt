import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension AppBarExtensions on AppBar {
  static AppBar noColorTinting({
    required BuildContext context,
    required Widget title,
    bool centerTitle = true,
    double elevation = 0,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    Widget? leading,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? Colors.grey[900] : Theme.of(context).colorScheme.primary;

    return AppBar(
      title: title,
      centerTitle: centerTitle,
      elevation: elevation,
      actions: actions,
      bottom: bottom,
      leading: leading,
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      // Ensure no color tinting
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
}
