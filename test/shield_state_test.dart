import 'package:banana_escape/game/systems/shield_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShieldState', () {
    test('starts lowered with the stock it was given', () {
      final shields = ShieldState(stock: 3);
      expect(shields.stock, 3);
      expect(shields.isActive, isFalse);
      expect(shields.remaining, 0);
    });

    test('a negative stock is treated as none', () {
      expect(ShieldState(stock: -2).stock, 0);
    });

    test('activating spends one and raises it for the full duration', () {
      final shields = ShieldState(stock: 2);
      expect(shields.activate(), isTrue);
      expect(shields.stock, 1);
      expect(shields.isActive, isTrue);
      expect(shields.remaining, ShieldState.duration);
    });

    test('nothing happens with an empty stock', () {
      final shields = ShieldState(stock: 0);
      expect(shields.canActivate, isFalse);
      expect(shields.activate(), isFalse);
      expect(shields.isActive, isFalse);
    });

    test('a second double-tap while one is up does not waste a shield', () {
      final shields = ShieldState(stock: 3)..activate();
      expect(shields.activate(), isFalse);
      expect(shields.stock, 2);
    });

    test('it runs out after the duration and reports the moment once', () {
      final shields = ShieldState(stock: 1)..activate();
      expect(shields.tick(ShieldState.duration - 0.5), isFalse);
      expect(shields.isActive, isTrue);
      expect(shields.tick(0.6), isTrue);
      expect(shields.isActive, isFalse);
      expect(shields.remaining, 0);
      expect(shields.tick(1), isFalse);
    });

    test('a raised shield absorbs one crash and drops', () {
      final shields = ShieldState(stock: 1)..activate();
      expect(shields.absorb(), isTrue);
      expect(shields.isActive, isFalse);
      expect(shields.absorb(), isFalse);
    });

    test('a lowered shield absorbs nothing, even with stock left', () {
      final shields = ShieldState(stock: 4);
      expect(shields.absorb(), isFalse);
      expect(shields.stock, 4);
    });

    test('after one is used up the next can be raised', () {
      final shields = ShieldState(stock: 2)
        ..activate()
        ..absorb();
      expect(shields.activate(), isTrue);
      expect(shields.stock, 0);
    });
  });
}
