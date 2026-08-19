import 'dart:ui';

import 'package:banana_escape/config/game_config.dart';
import 'package:banana_escape/game/systems/collision_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lane centres the game settles on at a typical width, so the numbers below
/// sit in the same range the real thing works with.
const double leftLane = 90;
const double middleLane = 210;
const double rightLane = 330;

Rect boxAt(double centerX, {double width = 40, double height = 60}) {
  return Rect.fromCenter(
    center: Offset(centerX, 700),
    width: width,
    height: height,
  );
}

/// Same vertical band as [boxAt] but shifted, for testing shallow overlaps.
Rect boxOffsetBy(Rect from, {double dx = 0, double dy = 0}) {
  return from.shift(Offset(dx, dy));
}

bool crash(
  Rect player,
  Rect obstacle, {
  bool isChangingLane = false,
  bool isEscaping = false,
  double targetLaneCenter = middleLane,
}) {
  return shouldCrash(
    playerBox: player,
    obstacleBox: obstacle,
    isChangingLane: isChangingLane,
    isEscaping: isEscaping,
    targetLaneCenter: targetLaneCenter,
  );
}

void main() {
  group('no overlap', () {
    test('boxes in different lanes never crash', () {
      expect(crash(boxAt(middleLane), boxAt(rightLane)), isFalse);
    });

    test('boxes touching exactly at the edge do not crash', () {
      final player = boxAt(middleLane, width: 40);
      final obstacle = boxOffsetBy(player, dx: 40);

      expect(player.overlaps(obstacle), isFalse);
      expect(crash(player, obstacle), isFalse);
    });
  });

  group('minimum overlap', () {
    test('a sliver on both axes is forgiven', () {
      final player = boxAt(middleLane, width: 40, height: 60);
      // Overlap of 10x12 — under both minimums.
      final obstacle = boxOffsetBy(player, dx: 30, dy: 48);

      final overlap = player.intersect(obstacle);
      expect(overlap.width, lessThan(GameConfig.collisionMinOverlapX));
      expect(overlap.height, lessThan(GameConfig.collisionMinOverlapY));
      expect(crash(player, obstacle), isFalse);
    });

    test('a thin but tall overlap still crashes', () {
      final player = boxAt(middleLane, width: 40, height: 60);
      // 10px wide, but full height: the player is squarely in the lane.
      final obstacle = boxOffsetBy(player, dx: 30);

      final overlap = player.intersect(obstacle);
      expect(overlap.width, lessThan(GameConfig.collisionMinOverlapX));
      expect(overlap.height, greaterThan(GameConfig.collisionMinOverlapY));
      expect(crash(player, obstacle), isTrue);
    });

    test('a dead-centre overlap always crashes', () {
      expect(crash(boxAt(middleLane), boxAt(middleLane)), isTrue);
    });
  });

  group('lane change forgiveness', () {
    test('grazing an edge mid-swipe is forgiven', () {
      final player = boxAt(middleLane, width: 40, height: 60);
      final obstacle = boxOffsetBy(player, dx: 22);

      // Standing still in the lane, this is a hit.
      expect(crash(player, obstacle), isTrue);
      // Mid-swipe, the same geometry is forgiven.
      expect(crash(player, obstacle, isChangingLane: true), isFalse);
    });

    test('an obstacle you are moving away from is forgiven', () {
      final player = boxAt(middleLane, width: 40, height: 60);
      // 28px of horizontal overlap: too deep for the graze rules to touch,
      // shallow enough for the escape rule to reach.
      final obstacle = boxOffsetBy(player, dx: 12);
      final overlap = player.intersect(obstacle);
      expect(
          overlap.width, greaterThanOrEqualTo(GameConfig.collisionMinOverlapX));
      expect(overlap.width, lessThan(GameConfig.laneEscapeGraceOverlapX));

      // Swiping, but into it — or not swiping away from it — is a crash.
      expect(crash(player, obstacle, isChangingLane: true), isTrue);

      // Same geometry, now travelling away from it: forgiven.
      expect(
        crash(
          player,
          obstacle,
          isChangingLane: true,
          isEscaping: true,
          targetLaneCenter: leftLane,
        ),
        isFalse,
      );
    });

    test('escaping does not save you if the obstacle sits in the target lane',
        () {
      final player = boxAt(middleLane, width: 40, height: 60);
      final obstacle = boxOffsetBy(player, dx: 12);

      // The obstacle centre falls inside the +/-28 band around the lane the
      // swipe is heading for, so the escape grace is withdrawn: you are not
      // escaping anything, you are swiping into it.
      expect(
        crash(
          player,
          obstacle,
          isChangingLane: true,
          isEscaping: true,
          targetLaneCenter: obstacle.center.dx,
        ),
        isTrue,
      );
    });

    test('a deep overlap kills you even mid-swipe', () {
      final player = boxAt(middleLane, width: 40, height: 60);
      // Nearly concentric: nothing about a swipe should save this.
      final obstacle = boxOffsetBy(player, dx: 4);

      expect(
        crash(
          player,
          obstacle,
          isChangingLane: true,
          isEscaping: true,
          targetLaneCenter: leftLane,
        ),
        isTrue,
      );
    });
  });

  group('forgiveness is bounded', () {
    test('standing still, no lane-change rule applies', () {
      final player = boxAt(middleLane, width: 40, height: 60);

      // Sweep the obstacle across the player and confirm that every overlap
      // deep enough to clear the minimums is a crash when not swiping.
      for (var dx = 0.0; dx <= 30; dx += 2) {
        final obstacle = boxOffsetBy(player, dx: dx);
        final overlap = player.intersect(obstacle);
        final clearsMinimums =
            overlap.width >= GameConfig.collisionMinOverlapX ||
                overlap.height >= GameConfig.collisionMinOverlapY;

        expect(
          crash(player, obstacle),
          clearsMinimums,
          reason: 'dx=$dx should crash exactly when it clears the minimums',
        );
      }
    });

    test('mid-swipe forgiveness never extends past the graze thresholds', () {
      final player = boxAt(middleLane, width: 40, height: 60);

      // Once the horizontal overlap passes the lane-escape grace, no
      // combination of swipe state can save the run.
      final obstacle = boxOffsetBy(
        player,
        dx: 40 - GameConfig.laneEscapeGraceOverlapX - 2,
      );
      final overlap = player.intersect(obstacle);
      expect(overlap.width, greaterThan(GameConfig.laneEscapeGraceOverlapX));

      for (final escaping in [true, false]) {
        expect(
          crash(
            player,
            obstacle,
            isChangingLane: true,
            isEscaping: escaping,
            targetLaneCenter: leftLane,
          ),
          isTrue,
          reason: 'escaping=$escaping should not matter this deep in',
        );
      }
    });
  });
}
