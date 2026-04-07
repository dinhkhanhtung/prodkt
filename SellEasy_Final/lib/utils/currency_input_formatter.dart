import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Only keep digits
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Parse the digits to a number
    int number = int.parse(digitsOnly);

    // Format the number with dots as thousand separators
    String formatted = number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );

    // If the cursor is at the end, move it to the new end
    bool cursorAtEnd = newValue.selection.baseOffset == newValue.text.length;

    return TextEditingValue(
      text: formatted,
      selection: cursorAtEnd
          ? TextSelection.collapsed(offset: formatted.length)
          : newValue.selection,
    );
  }
}
