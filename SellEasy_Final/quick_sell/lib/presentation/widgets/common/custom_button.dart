import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class CustomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final double? width;
  final double? height;
  final double? iconSize;
  final double? fontSize;
  final bool outlined;

  const CustomButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = Colors.blue,
    this.width,
    this.height,
    this.iconSize,
    this.fontSize,
    this.outlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonWidth = width ?? ResponsiveUtils.getAdaptiveWidth(context, 70);
    final buttonHeight = height ?? ResponsiveUtils.getAdaptiveHeight(context, 70);
    final buttonIconSize = iconSize ?? ResponsiveUtils.getAdaptiveIconSize(context, 24);
    final buttonFontSize = fontSize ?? ResponsiveUtils.getAdaptiveFontSize(context, 12);

    if (outlined) {
      return SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: buttonIconSize,
                color: color,
              ),
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
              Text(
                label,
                style: TextStyle(
                  fontSize: buttonFontSize,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      return SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: buttonIconSize,
                color: Colors.white,
              ),
              SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, 4)),
              Text(
                label,
                style: TextStyle(
                  fontSize: buttonFontSize,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}
