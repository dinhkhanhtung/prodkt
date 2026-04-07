import 'package:flutter/material.dart';

/// Utility class for responsive design
class ResponsiveUtils {
  /// Get the number of grid columns based on screen width
  static int getGridColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 4; // Large tablets, desktops
    if (width > 600) return 3; // Tablets
    return 2; // Phones
  }

  /// Get the child aspect ratio for product grid based on screen size
  static double getProductCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    if (isLandscape) {
      return 0.9; // Wider cards in landscape
    }
    
    if (width > 600) {
      return 0.8; // Slightly taller cards on tablets
    }
    
    return 0.75; // Default for phones
  }

  /// Get appropriate padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) {
      return const EdgeInsets.all(24.0);
    } else if (width > 600) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }

  /// Get appropriate dialog width based on screen size
  static double getDialogMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) {
      return 700.0;
    } else if (width > 600) {
      return 550.0;
    } else {
      return width * 0.9;
    }
  }

  /// Check if the device is a tablet or larger
  static bool isTabletOrLarger(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  /// Get appropriate font size based on screen size
  static double getAdaptiveFontSize(BuildContext context, double baseFontSize) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) {
      return baseFontSize * 1.2;
    } else if (width > 600) {
      return baseFontSize * 1.1;
    } else {
      return baseFontSize;
    }
  }

  /// Get appropriate icon size based on screen size
  static double getAdaptiveIconSize(BuildContext context, double baseIconSize) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) {
      return baseIconSize * 1.2;
    } else if (width > 600) {
      return baseIconSize * 1.1;
    } else {
      return baseIconSize;
    }
  }

  /// Get appropriate spacing based on screen size
  static double getAdaptiveSpacing(BuildContext context, double baseSpacing) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) {
      return baseSpacing * 1.5;
    } else if (width > 600) {
      return baseSpacing * 1.25;
    } else {
      return baseSpacing;
    }
  }

  /// Get a responsive layout for a list of widgets
  /// Will display in a Row for landscape/tablet, Column for portrait phones
  static Widget responsiveRowColumn({
    required BuildContext context,
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    double spacing = 16.0,
  }) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
    if (isLandscape || isTablet) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _addSpacingBetween(children, SizedBox(width: spacing)),
      );
    } else {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _addSpacingBetween(children, SizedBox(height: spacing)),
      );
    }
  }

  /// Helper method to add spacing between widgets
  static List<Widget> _addSpacingBetween(List<Widget> widgets, Widget spacer) {
    if (widgets.isEmpty) return [];
    if (widgets.length == 1) return widgets;
    
    final result = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(spacer);
      }
    }
    return result;
  }
}
