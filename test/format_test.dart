import 'package:banana_escape/ui/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatCoins groups thousands', () {
    expect(formatCoins(0), '0');
    expect(formatCoins(750), '750');
    expect(formatCoins(1500), '1,500');
    expect(formatCoins(25000), '25,000');
    expect(formatCoins(1234567), '1,234,567');
    expect(formatCoins(-4200), '-4,200');
  });
}
