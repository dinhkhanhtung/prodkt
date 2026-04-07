import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double getAdaptiveFontSize(BuildContext context, double fontSize) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return fontSize * 0.8; // Smaller screens
    } else if (width > 600) {
      return fontSize * 1.2; // Larger screens like tablets
    }
    
    return fontSize; // Default size for normal phones
  }

  static double getAdaptiveIconSize(BuildContext context, double iconSize) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return iconSize * 0.8; // Smaller screens
    } else if (width > 600) {
      return iconSize * 1.2; // Larger screens like tablets
    }
    
    return iconSize; // Default size for normal phones
  }

  static double getAdaptiveSpacing(BuildContext context, double spacing) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return spacing * 0.8; // Smaller screens
    } else if (width > 600) {
      return spacing * 1.2; // Larger screens like tablets
    }
    
    return spacing; // Default size for normal phones
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final diagonal = (width * width + height * height) / 2;
    
    return diagonal > 250000; // Roughly 500x500 pixels
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
}
