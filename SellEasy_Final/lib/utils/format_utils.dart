import 'package:intl/intl.dart';

class FormatUtils {
  static final _currencyFormat = NumberFormat("#,##0", "vi_VN");
  static final _numberFormat = NumberFormat("#,##0", "vi_VN");

  static String formatCurrency(num value) {
    return '${_currencyFormat.format(value)}đ';
  }

  static String formatNumber(String value) {
    if (value.isEmpty) return '';
    // Loại bỏ tất cả ký tự không phải số
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.isEmpty) return '';

    // Chuyển đổi sang số
    final number = int.tryParse(cleanValue);
    if (number == null) return '';

    // Format số với dấu phân cách hàng nghìn
    return _numberFormat.format(number);
  }
}

String formatCurrency(double amount) {
  return amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          ) +
      'đ';
}

String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatDateTime(DateTime dateTime) {
  return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
}

String formatPhoneNumber(String phone) {
  if (phone.isEmpty) return '';
  return phone.replaceAllMapped(
    RegExp(r'(\d{3})(\d{3})(\d{4})'),
    (Match m) => '${m[1]}.${m[2]}.${m[3]}',
  );
}

String formatPercentage(double value) {
  return '${value.toStringAsFixed(1)}%';
}

String formatQuantity(double quantity) {
  return quantity.toStringAsFixed(0);
}

String formatWeight(double weight) {
  return '${weight.toStringAsFixed(1)}kg';
}

String formatVolume(double volume) {
  return '${volume.toStringAsFixed(1)}ml';
}

String formatDistance(double distance) {
  return '${distance.toStringAsFixed(1)}km';
}

String formatTime(DateTime time) {
  return DateFormat('HH:mm').format(time);
}

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = twoDigits(duration.inHours);
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$hours:$minutes:$seconds';
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String formatNumber(double number) {
  return number.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
}

String formatDecimal(double number, {int decimals = 2}) {
  final parts = number.toStringAsFixed(decimals).split('.');
  final wholePart = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  );
  return '$wholePart.${parts[1]}';
}

String formatScientific(double number) {
  return NumberFormat.scientificPattern().format(number);
}

String formatCompact(double number) {
  return NumberFormat.compact().format(number);
}

String formatCompactCurrency(double number) {
  return NumberFormat.compactCurrency(
    symbol: 'đ',
    decimalDigits: 0,
  ).format(number);
}

String formatCompactLong(double number) {
  return NumberFormat.compactLong().format(number);
}

String formatPercent(double number) {
  return NumberFormat.percentPattern().format(number);
}

String formatSignificant(double number, {int significantDigits = 3}) {
  return NumberFormat('0.${'#' * significantDigits}').format(number);
}

String formatPattern(double number, String pattern) {
  return NumberFormat(pattern).format(number);
}

String formatLocale(double number, String locale) {
  return NumberFormat('#,###', locale).format(number);
}

String formatCurrencyLocale(double number, String locale) {
  return NumberFormat.currency(
    symbol: 'đ',
    locale: locale,
    decimalDigits: 0,
  ).format(number);
}

String formatDateLocale(DateTime date, String locale) {
  return DateFormat('dd/MM/yyyy', locale).format(date);
}

String formatDateTimeLocale(DateTime dateTime, String locale) {
  return DateFormat('dd/MM/yyyy HH:mm', locale).format(dateTime);
}

String formatTimeLocale(DateTime time, String locale) {
  return DateFormat('HH:mm', locale).format(time);
}

String formatDurationLocale(Duration duration, String locale) {
  final formatter = NumberFormat('#,##0', locale);
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = twoDigits(duration.inHours);
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$hours:$minutes:$seconds';
}

String formatFileSizeLocale(int bytes, String locale) {
  final formatter = NumberFormat('#,##0', locale);
  if (bytes < 1024) return '${formatter.format(bytes)} B';
  if (bytes < 1024 * 1024) {
    return '${formatter.format(bytes / 1024)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${formatter.format(bytes / (1024 * 1024))} MB';
  }
  return '${formatter.format(bytes / (1024 * 1024 * 1024))} GB';
}

String formatNumberLocale(double number, String locale) {
  return NumberFormat('#,###', locale).format(number);
}

String formatDecimalLocale(double number, String locale, {int decimals = 2}) {
  return NumberFormat('#,##0.${'0' * decimals}', locale).format(number);
}

String formatScientificLocale(double number, String locale) {
  return NumberFormat.scientificPattern(locale).format(number);
}

String formatCompactLocale(double number, String locale) {
  return NumberFormat.compact(locale: locale).format(number);
}

String formatCompactCurrencyLocale(double number, String locale) {
  return NumberFormat.compactCurrency(
    symbol: 'đ',
    locale: locale,
    decimalDigits: 0,
  ).format(number);
}

String formatCompactLongLocale(double number, String locale) {
  return NumberFormat.compactLong(locale: locale).format(number);
}

String formatPercentLocale(double number, String locale) {
  return NumberFormat.percentPattern(locale).format(number);
}

String formatSignificantLocale(double number, String locale,
    {int significantDigits = 3}) {
  return NumberFormat('0.${'#' * significantDigits}', locale).format(number);
}

String formatPatternLocale(double number, String pattern, String locale) {
  return NumberFormat(pattern, locale).format(number);
}
