import 'dart:math';

import 'package:banana_escape/config/game_config.dart';
import 'package:banana_escape/game/data/collectible_type.dart';
import 'package:banana_escape/game/data/obstacle_type.dart';
import 'package:banana_escape/game/systems/spawn_host.dart';

class SpawnController {
  /// [random] exists so tests can pin the rolls. Production passes nothing and
  /// gets an unseeded generator, exactly as before.
  SpawnController(this.host, {Random? random}) : _random = random ?? Random();

  final SpawnHost host;
  final Random _random;

  double _obstacleTimer = 0;
  double _collectibleTimer = 0;
  int _openingIndex = 0;
  int _lastOpenLane = 1;

  static const List<_OpeningSpawn> _openingSpawns = [
    _OpeningSpawn(time: 0.8, collectible: CollectibleType.coin, lane: 1),
    _OpeningSpawn(time: 1.3, collectible: CollectibleType.coin, lane: 0),
    _OpeningSpawn(time: 1.8, collectible: CollectibleType.coin, lane: 2),
    _OpeningSpawn(time: 2.7, obstacle: ObstacleType.crate, lane: 1),
    _OpeningSpawn(time: 3.3, collectible: CollectibleType.coin, lane: 0),
    _OpeningSpawn(time: 4.2, obstacle: ObstacleType.peel, lane: 2),
  ];

  void update(double dt) {
    while (_openingIndex < _openingSpawns.length &&
        host.runTime >= _openingSpawns[_openingIndex].time) {
      final opening = _openingSpawns[_openingIndex];
      if (opening.obstacle != null) {
        host.spawnObstacle(opening.lane, opening.obstacle!);
      }
      if (opening.collectible != null) {
        host.spawnCollectible(opening.lane, opening.collectible!, yOffset: 0);
      }
      _openingIndex++;
    }

    _obstacleTimer += dt;
    _collectibleTimer += dt;

    if (_obstacleTimer >= host.obstacleInterval) {
      _obstacleTimer = 0;
      _spawnObstacleWave();
    }

    if (_collectibleTimer >= host.collectibleInterval) {
      _collectibleTimer = 0;
      _spawnCollectibleWave();
    }
  }

  void _spawnObstacleWave() {
    final safeLanes = List<int>.generate(3, (index) => index)
        .where((lane) => !_laneIsOccupied(lane))
        .toList();
    if (safeLanes.isEmpty) {
      return;
    }

    final openLaneCandidates =
        safeLanes.where((lane) => lane != _lastOpenLane).toList();
    final openLaneSource =
        openLaneCandidates.isNotEmpty ? openLaneCandidates : safeLanes;
    final openLane = openLaneSource[_random.nextInt(openLaneSource.length)];
    _lastOpenLane = openLane;
    final difficultyBias = (host.stage - 1).clamp(0, 6) / 6;
    final inEarlyGame = host.runTime < GameConfig.earlyGameSafeDuration;
    final inMidGame = host.runTime >= GameConfig.midGamePressureStart;
    final inLateGame = host.runTime >= GameConfig.lateGamePressureStart;

    final double blockChance;
    if (inEarlyGame) {
      blockChance = 0.0;
    } else if (inLateGame) {
      blockChance = 0.48 + (difficultyBias * 0.26);
    } else if (inMidGame) {
      blockChance = 0.30 + (difficultyBias * 0.24);
    } else {
      blockChance = 0.18 + (difficultyBias * 0.16);
    }

    final blockTwoLanes = _random.nextDouble() < blockChance;
    var spawned = 0;
    final blockedLanes = <int>[];
    for (var lane = 0; lane < 3; lane++) {
      if (lane == openLane) {
        continue;
      }
      if (_laneIsOccupied(lane)) {
        continue;
      }
      if (!blockTwoLanes &&
          _random.nextDouble() <
              _singleLaneSkipChance(difficultyBias, inEarlyGame, inMidGame)) {
        continue;
      }
      host.spawnObstacle(lane, _pickObstacleType(host.stage));
      spawned++;
      blockedLanes.add(lane);
      if (!blockTwoLanes) {
        break;
      }
    }

    if (host.stage >= 3 &&
        blockedLanes.isNotEmpty &&
        _random.nextDouble() <
            _staggerChance(difficultyBias, inMidGame, inLateGame)) {
      final staggerLane = blockedLanes[_random.nextInt(blockedLanes.length)];
      if (!host.laneHasObstacleNearSpawn(staggerLane, topLimit: 110)) {
        host.spawnObstacleWithOffset(
          staggerLane,
          _pickObstacleType(host.stage),
          yOffset: _staggerOffset(inLateGame),
        );
      }
    }

    // Every skip roll can miss, leaving a wave that applies no pressure at
    // all. The fallback puts one obstacle out so the beat is not wasted — but
    // never in the open lane, or a board that already has two lanes occupied
    // would end up sealed off entirely with no way through.
    if (spawned == 0) {
      final fallbackLane = List<int>.generate(3, (index) => index).firstWhere(
        (lane) => lane != openLane && !_laneIsOccupied(lane),
        orElse: () => -1,
      );
      if (fallbackLane != -1) {
        host.spawnObstacle(
          fallbackLane,
          _pickObstacleType(host.stage),
        );
      }
    }
  }

  /// A lane is off limits for a fresh obstacle while anything is still sitting
  /// in the spawn strip — dropping a second one on top reads as a cheap kill.
  bool _laneIsOccupied(int lane) {
    return host.laneHasObstacleNearSpawn(
          lane,
          topLimit: GameConfig.spawnSafetyTop,
        ) ||
        host.laneHasCollectibleNearSpawn(
          lane,
          topLimit: GameConfig.spawnSafetyTop,
        );
  }

  double _singleLaneSkipChance(
    double difficultyBias,
    bool inEarlyGame,
    bool inMidGame,
  ) {
    if (inEarlyGame) {
      return 0.56;
    }
    if (inMidGame) {
      return 0.18 - difficultyBias * 0.06;
    }
    return 0.3 - difficultyBias * 0.1;
  }

  double _staggerChance(
    double difficultyBias,
    bool inMidGame,
    bool inLateGame,
  ) {
    if (inLateGame) {
      return 0.38 + (difficultyBias * 0.18);
    }
    if (inMidGame) {
      return 0.24 + (difficultyBias * 0.16);
    }
    return 0.16 + (difficultyBias * 0.1);
  }

  double _staggerOffset(bool inLateGame) {
    return inLateGame ? -96 : -116;
  }

  ObstacleType _pickObstacleType(int stage) {
    final weighted = <ObstacleType>[
      ObstacleType.peel,
      ObstacleType.crate,
      ObstacleType.crate,
      ObstacleType.rock,
      ObstacleType.smoothieBox,
    ];
    if (stage >= 2) {
      weighted.addAll([ObstacleType.cart, ObstacleType.peel]);
    }
    if (stage >= 3) {
      weighted.addAll([ObstacleType.pit, ObstacleType.cart, ObstacleType.rock]);
    }
    if (stage >= 5) {
      weighted.addAll([ObstacleType.pit, ObstacleType.smoothieBox]);
    }
    return weighted[_random.nextInt(weighted.length)];
  }

  void _spawnCollectibleWave() {
    final availableLanes = List<int>.generate(3, (index) => index)
        .where(
          (lane) => !host.laneHasObstacleNearSpawn(
            lane,
            topLimit: GameConfig.spawnSafetyTop,
          ),
        )
        .toList();
    if (availableLanes.isEmpty) {
      return;
    }
    final lane = availableLanes[_random.nextInt(availableLanes.length)];
    final roll = _random.nextDouble();

    if (host.laneHasCollectibleNearSpawn(lane, topLimit: 150)) {
      return;
    }

    if (roll < 0.12 && host.runTime > 8 && !host.magnetActive) {
      host.spawnCollectible(lane, CollectibleType.magnet, yOffset: 0);
      return;
    }

    if (roll > 0.88 && host.runTime > 6) {
      host.spawnCollectible(lane, CollectibleType.combo, yOffset: 0);
      return;
    }

    if (host.stage >= 2 &&
        _random.nextDouble() < 0.24 &&
        availableLanes.length >= 2) {
      _spawnCoinZigZag(availableLanes);
      return;
    }

    if (_random.nextDouble() < 0.28) {
      _spawnCoinLine(lane);
      return;
    }

    final count = 1 + _random.nextInt(host.stage >= 3 ? 4 : 3);
    for (var i = 0; i < count; i++) {
      host.spawnCollectible(
        lane,
        CollectibleType.coin,
        yOffset: -(i * GameConfig.collectibleVerticalGap).toDouble(),
      );
    }
  }

  void _spawnCoinLine(int lane) {
    final count = 3 + _random.nextInt(host.stage >= 3 ? 3 : 2);
    for (var i = 0; i < count; i++) {
      host.spawnCollectible(
        lane,
        CollectibleType.coin,
        yOffset: -(i * GameConfig.collectibleVerticalGap).toDouble(),
      );
    }
  }

  void _spawnCoinZigZag(List<int> availableLanes) {
    availableLanes.sort();
    var currentLane = availableLanes[_random.nextInt(availableLanes.length)];
    final steps = 4 + _random.nextInt(2);
    for (var i = 0; i < steps; i++) {
      host.spawnCollectible(
        currentLane,
        CollectibleType.coin,
        yOffset: -(i * GameConfig.collectibleVerticalGap).toDouble(),
      );
      final nextChoices =
          availableLanes.where((lane) => lane != currentLane).toList();
      if (nextChoices.isEmpty) {
        break;
      }
      currentLane = nextChoices[_random.nextInt(nextChoices.length)];
    }
  }
}

class _OpeningSpawn {
  const _OpeningSpawn({
    required this.time,
    required this.lane,
    this.obstacle,
    this.collectible,
  });

  final double time;
  final int lane;
  final ObstacleType? obstacle;
  final CollectibleType? collectible;
}
