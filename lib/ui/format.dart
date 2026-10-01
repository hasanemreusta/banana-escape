import 'package:banana_escape/l10n/strings.dart';

/// 12500 → "12,500" ("12.500" in Turkish). Prices now run into five figures, where an unbroken
/// string of digits is hard to read at a glance.
String formatCoins(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(S.current.thousandsSeparator);
    }
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
