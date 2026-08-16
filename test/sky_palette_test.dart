import 'package:banana_escape/game/data/sky_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkyPalette cycle', () {
    test('lands on each keyframe at its quarter of the cycle', () {
      expect(SkyPalette.at(0.0).skyTop, SkyPalette.noon.skyTop);
      expect(SkyPalette.at(0.25).skyTop, SkyPalette.sunset.skyTop);
      expect(SkyPalette.at(0.5).skyTop, SkyPalette.night.skyTop);
      expect(SkyPalette.at(0.75).skyTop, SkyPalette.dawn.skyTop);
    });

    test('wraps seamlessly past a full cycle', () {
      expect(SkyPalette.at(1.0).skyTop, SkyPalette.noon.skyTop);
      expect(SkyPalette.at(1.25).skyTop, SkyPalette.sunset.skyTop);
      expect(SkyPalette.at(2.5).skyTop, SkyPalette.night.skyTop);
    });

    test('never returns a hard cut between keyframes', () {
      // Sampling just before and after a keyframe should stay close, otherwise
      // the sky would visibly pop rather than drift.
      final before = SkyPalette.at(0.24);
      final after = SkyPalette.at(0.26);
      final delta = (before.skyTop.r - after.skyTop.r).abs() +
          (before.skyTop.g - after.skyTop.g).abs() +
          (before.skyTop.b - after.skyTop.b).abs();
      expect(delta, lessThan(0.15));
    });

    test('darkness rises into night and falls back out', () {
      expect(SkyPalette.at(0.0).starAlpha, 0);
      expect(
        SkyPalette.at(0.5).starAlpha,
        greaterThan(SkyPalette.at(0.25).starAlpha),
      );
      expect(
        SkyPalette.at(0.9).starAlpha,
        lessThan(SkyPalette.at(0.5).starAlpha),
      );
    });

    test('lerp interpolates rather than snapping to an end', () {
      final mid = SkyPalette.lerp(SkyPalette.noon, SkyPalette.night, 0.5);

      expect(mid.skyTop, isNot(SkyPalette.noon.skyTop));
      expect(mid.skyTop, isNot(SkyPalette.night.skyTop));
      expect(mid.starAlpha, closeTo(0.5, 0.001));
    });
  });
}
