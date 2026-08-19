import 'dart:math';

import 'package:banana_escape/config/game_config.dart';
import 'package:banana_escape/game/data/collectible_type.dart';
import 'package:banana_escape/game/data/obstacle_type.dart';
import 'package:banana_escape/game/systems/spawn_controller.dart';
import 'package:banana_escape/game/systems/spawn_host.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the controller asked for, and answers lane-occupancy questions
/// from what it has already been told to spawn — enough to make the wave rules
/// behave as they do in a real run.
class FakeSpawnHost implements SpawnHost {
  FakeSpawnHost({
    this.runTime = 0,
    this.stage = 1,
    this.magnetActive = false,
  });

  @override
  double runTime;

  @override
  int stage;

  @override
  bool magnetActive;

  @override
  double obstacleInterval = GameConfig.initialObstacleInterval;

  @override
  double collectibleInterval = GameConfig.initialCollectibleInterval;

  final List<int> obstacleLanes = [];
  final List<int> collectibleLanes = [];
  final List<CollectibleType> collectibleTypes = [];

  /// Lanes the fake reports as blocked regardless of what has been spawned,
  /// so tests can set up a board without driving the controller into it.
  final Set<int> forcedObstacleLanes = {};
  final Set<int> forcedCollectibleLanes = {};

  void clear() {
    obstacleLanes.clear();
    collectibleLanes.clear();
    collectibleTypes.clear();
  }

  @override
  bool laneHasObstacleNearSpawn(int lane, {required double topLimit}) {
    return forcedObstacleLanes.contains(lane) || obstacleLanes.contains(lane);
  }

  @override
  bool laneHasCollectibleNearSpawn(int lane, {required double topLimit}) {
    return forcedCollectibleLanes.contains(lane) ||
        collectibleLanes.contains(lane);
  }

  @override
  void spawnObstacle(int lane, ObstacleType type) {
    obstacleLanes.add(lane);
  }

  @override
  void spawnObstacleWithOffset(
    int lane,
    ObstacleType type, {
    required double yOffset,
  }) {
    obstacleLanes.add(lane);
  }

  @override
  void spawnCollectible(
    int lane,
    CollectibleType type, {
    required double yOffset,
  }) {
    collectibleLanes.add(lane);
    collectibleTypes.add(type);
  }
}

/// Drives one obstacle wave and returns the lanes it blocked.
Set<int> runObstacleWave(FakeSpawnHost host, int seed) {
  final controller = SpawnController(host, random: Random(seed));
  // The scripted opening fires off runTime, which the fake holds fixed, so
  // flush it with a zero-length tick and clear before timing the real wave.
  // Neither the opening nor a zero tick touches the random source, so the
  // seed still lines up with the wave under test.
  controller.update(0.0);
  host.clear();
  controller.update(host.obstacleInterval + 0.01);
  return host.obstacleLanes.toSet();
}

void main() {
  group('lane safety', () {
    test('a wave never blocks all three lanes', () {
      // The invariant that makes the game playable at all. Swept over many
      // seeds and every difficulty phase, because the block chance climbs
      // with both stage and run time.
      for (final runTime in <double>[0, 5, 12, 25, 40, 90]) {
        for (var stage = 1; stage <= 8; stage++) {
          for (var seed = 0; seed < 60; seed++) {
            final host = FakeSpawnHost(runTime: runTime, stage: stage);
            final blocked = runObstacleWave(host, seed);

            expect(
              blocked.length,
              lessThan(3),
              reason: 'runTime=$runTime stage=$stage seed=$seed '
                  'left no lane open',
            );
          }
        }
      }
    });

    test('the early game never blocks more than one lane', () {
      for (var seed = 0; seed < 80; seed++) {
        final host = FakeSpawnHost(
          runTime: GameConfig.earlyGameSafeDuration - 1,
          stage: 1,
        );
        final blocked = runObstacleWave(host, seed);

        expect(
          blocked.length,
          lessThanOrEqualTo(1),
          reason: 'seed=$seed blocked $blocked before the safe period ended',
        );
      }
    });

    test('a wave always blocks at least one lane once past the opening', () {
      // A wave that spawns nothing is a dead beat — the run stops applying
      // pressure. The fallback branch exists to stop that happening.
      for (var seed = 0; seed < 60; seed++) {
        final host = FakeSpawnHost(runTime: 30, stage: 4);
        final blocked = runObstacleWave(host, seed);

        expect(blocked, isNotEmpty, reason: 'seed=$seed produced no obstacle');
      }
    });
  });

  group('respecting an occupied board', () {
    test('never stacks an obstacle onto a lane that already has one', () {
      for (var occupied = 0; occupied < 3; occupied++) {
        for (var seed = 0; seed < 40; seed++) {
          final host = FakeSpawnHost(runTime: 40, stage: 6)
            ..forcedObstacleLanes.add(occupied);
          final blocked = runObstacleWave(host, seed);

          expect(
            blocked,
            isNot(contains(occupied)),
            reason: 'seed=$seed spawned into occupied lane $occupied',
          );
        }
      }
    });

    test('never drops an obstacle onto a lane holding collectibles', () {
      for (var occupied = 0; occupied < 3; occupied++) {
        for (var seed = 0; seed < 40; seed++) {
          final host = FakeSpawnHost(runTime: 40, stage: 6)
            ..forcedCollectibleLanes.add(occupied);
          final blocked = runObstacleWave(host, seed);

          expect(
            blocked,
            isNot(contains(occupied)),
            reason: 'seed=$seed buried the coins in lane $occupied',
          );
        }
      }
    });

    test('two lanes occupied still leaves the third open', () {
      for (var seed = 0; seed < 40; seed++) {
        final host = FakeSpawnHost(runTime: 40, stage: 8)
          ..forcedObstacleLanes.addAll([0, 1]);
        final blocked = runObstacleWave(host, seed);

        expect(
          blocked,
          isEmpty,
          reason: 'seed=$seed blocked lane 2, the only way through',
        );
      }
    });
  });

  group('the opening script', () {
    test('runs its scripted spawns in order as the clock passes them', () {
      final host = FakeSpawnHost(runTime: 5, stage: 1);
      SpawnController(host, random: Random(1)).update(0.0);

      // Every scripted entry has fired by t=5: four coins, two obstacles.
      expect(host.collectibleLanes, [1, 0, 2, 0]);
      expect(host.obstacleLanes, containsAll(<int>[1, 2]));
    });

    test('the first obstacle only arrives after coins have been shown', () {
      final host = FakeSpawnHost(runTime: 2.0, stage: 1);
      SpawnController(host, random: Random(1)).update(0.0);

      expect(host.collectibleLanes, isNotEmpty);
      expect(
        host.obstacleLanes,
        isEmpty,
        reason: 'the opening teaches pickups before it introduces hazards',
      );
    });
  });

  group('collectible waves', () {
    test('magnets are held back until the run has settled', () {
      for (var seed = 0; seed < 120; seed++) {
        final host = FakeSpawnHost(runTime: 4, stage: 1);
        final controller = SpawnController(host, random: Random(seed));
        controller.update(host.collectibleInterval + 0.01);

        expect(
          host.collectibleTypes,
          isNot(contains(CollectibleType.magnet)),
          reason: 'seed=$seed handed out a magnet 4 seconds in',
        );
      }
    });

    test('no second magnet while one is already running', () {
      for (var seed = 0; seed < 120; seed++) {
        final host = FakeSpawnHost(runTime: 30, stage: 3, magnetActive: true);
        final controller = SpawnController(host, random: Random(seed));
        controller.update(host.collectibleInterval + 0.01);

        expect(
          host.collectibleTypes,
          isNot(contains(CollectibleType.magnet)),
          reason: 'seed=$seed stacked a magnet on an active one',
        );
      }
    });
  });
}
