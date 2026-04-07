import 'package:flutter/material.dart';
import '../widgets/toast_overlay.dart';

class ToastHelper {
  static void showSuccess(BuildContext context, String message) {
    ToastOverlay.show(
      context,
      message: message,
      isError: false,
    );
  }

  static void showError(BuildContext context, String message) {
    ToastOverlay.show(
      context,
      message: message,
      isError: true,
    );
  }

  static void showInfo(BuildContext context, String message) {
    ToastOverlay.show(
      context,
      message: message,
      isError: false,
      duration: const Duration(seconds: 3),
    );
  }
}
