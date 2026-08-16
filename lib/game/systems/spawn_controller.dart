import 'dart:math';

import 'package:banana_escape/config/game_config.dart';
import 'package:banana_escape/game/banana_escape_game.dart';
import 'package:banana_escape/game/data/collectible_type.dart';
import 'package:banana_escape/game/data/obstacle_type.dart';

class SpawnController {
  SpawnController(this.game) : _random = Random();

  final BananaEscapeGame game;
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
        game.runTime >= _openingSpawns[_openingIndex].time) {
      final opening = _openingSpawns[_openingIndex];
      if (opening.obstacle != null) {
        game.spawnObstacle(opening.lane, opening.obstacle!);
      }
      if (opening.collectible != null) {
        game.spawnCollectible(opening.lane, opening.collectible!);
      }
      _openingIndex++;
    }

    _obstacleTimer += dt;
    _collectibleTimer += dt;

    if (_obstacleTimer >= game.obstacleInterval) {
      _obstacleTimer = 0;
      _spawnObstacleWave();
    }

    if (_collectibleTimer >= game.collectibleInterval) {
      _collectibleTimer = 0;
      _spawnCollectibleWave();
    }
  }

  void _spawnObstacleWave() {
    final safeLanes = List<int>.generate(3, (index) => index)
        .where(
          (lane) =>
              !game.laneHasObstacleNearSpawn(lane) &&
              !game.laneHasCollectibleNearSpawn(lane),
        )
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
    final difficultyBias = (game.stage - 1).clamp(0, 6) / 6;
    final inEarlyGame = game.runTime < GameConfig.earlyGameSafeDuration;
    final inMidGame = game.runTime >= GameConfig.midGamePressureStart;
    final inLateGame = game.runTime >= GameConfig.lateGamePressureStart;

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
      if (game.laneHasObstacleNearSpawn(lane) ||
          game.laneHasCollectibleNearSpawn(lane)) {
        continue;
      }
      if (!blockTwoLanes &&
          _random.nextDouble() <
              _singleLaneSkipChance(difficultyBias, inEarlyGame, inMidGame)) {
        continue;
      }
      game.spawnObstacle(lane, _pickObstacleType(game.stage));
      spawned++;
      blockedLanes.add(lane);
      if (!blockTwoLanes) {
        break;
      }
    }

    if (game.stage >= 3 &&
        blockedLanes.isNotEmpty &&
        _random.nextDouble() <
            _staggerChance(difficultyBias, inMidGame, inLateGame)) {
      final staggerLane = blockedLanes[_random.nextInt(blockedLanes.length)];
      if (!game.laneHasObstacleNearSpawn(staggerLane, topLimit: 110)) {
        game.spawnObstacleWithOffset(
          staggerLane,
          _pickObstacleType(game.stage),
          yOffset: _staggerOffset(inLateGame),
        );
      }
    }

    if (spawned == 0) {
      final fallbackLane = List<int>.generate(3, (index) => index).firstWhere(
        (lane) =>
            !game.laneHasObstacleNearSpawn(lane) &&
            !game.laneHasCollectibleNearSpawn(lane),
        orElse: () => -1,
      );
      if (fallbackLane != -1) {
        game.spawnObstacle(
          fallbackLane,
          _pickObstacleType(game.stage),
        );
      }
    }
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
        .where((lane) => !game.laneHasObstacleNearSpawn(lane))
        .toList();
    if (availableLanes.isEmpty) {
      return;
    }
    final lane = availableLanes[_random.nextInt(availableLanes.length)];
    final roll = _random.nextDouble();

    if (game.laneHasCollectibleNearSpawn(lane, topLimit: 150)) {
      return;
    }

    if (roll < 0.12 && game.runTime > 8 && !game.magnetActive) {
      game.spawnCollectible(lane, CollectibleType.magnet);
      return;
    }

    if (roll > 0.88 && game.runTime > 6) {
      game.spawnCollectible(lane, CollectibleType.combo);
      return;
    }

    if (game.stage >= 2 &&
        _random.nextDouble() < 0.24 &&
        availableLanes.length >= 2) {
      _spawnCoinZigZag(availableLanes);
      return;
    }

    if (_random.nextDouble() < 0.28) {
      _spawnCoinLine(lane);
      return;
    }

    final count = 1 + _random.nextInt(game.stage >= 3 ? 4 : 3);
    for (var i = 0; i < count; i++) {
      game.spawnCollectible(
        lane,
        CollectibleType.coin,
        yOffset: -(i * GameConfig.collectibleVerticalGap).toDouble(),
      );
    }
  }

  void _spawnCoinLine(int lane) {
    final count = 3 + _random.nextInt(game.stage >= 3 ? 3 : 2);
    for (var i = 0; i < count; i++) {
      game.spawnCollectible(
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
      game.spawnCollectible(
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
