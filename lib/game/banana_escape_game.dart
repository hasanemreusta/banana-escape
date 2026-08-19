import 'dart:math' as math;

import 'package:banana_escape/config/app_copy.dart';
import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/config/game_config.dart';
import 'package:banana_escape/core/game_session_result.dart';
import 'package:banana_escape/core/hud_snapshot.dart';
import 'package:banana_escape/game/components/background_component.dart';
import 'package:banana_escape/game/components/blender_truck_component.dart';
import 'package:banana_escape/game/components/collectible_component.dart';
import 'package:banana_escape/game/components/feedback_burst_component.dart';
import 'package:banana_escape/game/components/obstacle_component.dart';
import 'package:banana_escape/game/components/player_component.dart';
import 'package:banana_escape/game/data/collectible_type.dart';
import 'package:banana_escape/game/data/obstacle_type.dart';
import 'package:banana_escape/game/systems/collision_rules.dart';
import 'package:banana_escape/game/systems/spawn_controller.dart';
import 'package:banana_escape/game/systems/spawn_host.dart';
import 'package:banana_escape/models/skin.dart';
import 'package:banana_escape/services/audio_service.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class BananaEscapeGame extends FlameGame implements SpawnHost {
  BananaEscapeGame({
    required AudioService audio,
    required BananaSkin skin,
    required ValueChanged<GameSessionResult> onGameOver,
  })  : _audio = audio,
        _skin = skin,
        _onGameOver = onGameOver;

  final AudioService _audio;
  final BananaSkin _skin;
  final ValueChanged<GameSessionResult> _onGameOver;

  PlayerComponent? _player;
  SpawnController? _spawner;

  final List<ObstacleComponent> _obstacles = [];
  final List<CollectibleComponent> _collectibles = [];
  final List<double> _laneCenters = List<double>.filled(3, 0);

  double scrollSpeed = GameConfig.initialScrollSpeed;
  @override
  double runTime = 0;
  double _difficultyElapsed = 0;
  double _stageElapsed = 0;
  @override
  double obstacleInterval = GameConfig.initialObstacleInterval;
  @override
  double collectibleInterval = GameConfig.initialCollectibleInterval;
  double _magnetRemaining = 0;
  double _comboRemaining = 0;
  int _comboPickups = 0;
  double _statusRemaining = 0;
  String? _statusText;
  bool _ended = false;

  int score = 0;
  int distance = 0;
  int coins = 0;
  @override
  int stage = 1;
  int styleBonus = 0;
  double _roadWidthFactor = 0.62;
  double _roadWidth = 0;
  double _roadLeft = 0;

  double get currentDistanceFactor =>
      GameConfig.distanceFactor +
      ((stage - 1) * GameConfig.stageDistanceFactorBonus);

  double get roadWidthFactor => _roadWidthFactor;

  double get roadWidth => _roadWidth;

  double get roadLeft => _roadLeft;

  double get laneVisualBias {
    return 0;
  }

  List<double> get laneCenters => _laneCenters;

  @override
  bool get magnetActive => _magnetRemaining > 0;
  double get magnetRemaining => _magnetRemaining;
  double get comboRemaining => _comboRemaining;

  /// Grows one step per [GameConfig.comboStep] pickups inside the combo window.
  int get comboMultiplier {
    if (_comboRemaining <= 0) {
      return 1;
    }
    final steps = _comboPickups ~/ GameConfig.comboStep;
    return (1 + steps).clamp(1, GameConfig.comboMaxMultiplier);
  }

  String? get statusText => _statusRemaining > 0 ? _statusText : null;
  bool get isReady => _player != null && _spawner != null;
  double get playerChaseX => _player?.position.x ?? laneCenters[1];
  HudSnapshot get hudSnapshot => HudSnapshot(
        score: score,
        distance: distance,
        coins: coins,
        stage: stage,
        magnetRemaining: magnetRemaining,
        runTime: runTime,
        statusText: statusText,
        comboMultiplier: comboMultiplier,
        comboRemaining: comboRemaining,
      );

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _recalculateTrackGeometry();
    add(BackgroundComponent());
    add(BlenderTruckComponent());
    _player = PlayerComponent(skin: _skin);
    add(_player!);
    _spawner = SpawnController(this);
    _configurePlayerForCurrentSize();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    _recalculateTrackGeometry();
    _configurePlayerForCurrentSize();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_ended) {
      return;
    }
    if (!isReady) {
      return;
    }

    runTime += dt;
    _difficultyElapsed += dt;
    _stageElapsed += dt;
    if (_statusRemaining > 0) {
      _statusRemaining -= dt;
    }
    if (_magnetRemaining > 0) {
      _magnetRemaining = math.max(0, _magnetRemaining - dt);
    }
    if (_comboRemaining > 0) {
      _comboRemaining = math.max(0, _comboRemaining - dt);
      if (_comboRemaining == 0) {
        _comboPickups = 0;
      }
    }
    _player?.setMagnetActive(magnetActive);
    _player?.setSpeedFactor(
      (scrollSpeed - GameConfig.initialScrollSpeed) /
          (GameConfig.maxScrollSpeed - GameConfig.initialScrollSpeed),
    );

    scrollSpeed = math.min(
      GameConfig.maxScrollSpeed,
      scrollSpeed + (GameConfig.accelerationPerSecond * dt),
    );

    if (_difficultyElapsed >= GameConfig.difficultyInterval) {
      _difficultyElapsed = 0;
      scrollSpeed = math.min(
          GameConfig.maxScrollSpeed, scrollSpeed + GameConfig.speedIncrease);
      obstacleInterval = math.max(
        GameConfig.obstacleIntervalMin,
        obstacleInterval - GameConfig.obstacleIntervalStep,
      );
      collectibleInterval = math.max(
        GameConfig.collectibleIntervalMin,
        collectibleInterval - 0.03,
      );
      _statusText = AppCopy.dangerBanner;
      _statusRemaining = 1.8;
      _audio.playDanger();
    }

    if (_stageElapsed >= GameConfig.stageInterval) {
      _stageElapsed = 0;
      stage += 1;
      scrollSpeed = math.min(GameConfig.maxScrollSpeed, scrollSpeed + 18);
      obstacleInterval = math.max(
        GameConfig.obstacleIntervalMin,
        obstacleInterval - 0.04,
      );
      collectibleInterval = math.max(
        GameConfig.collectibleIntervalMin,
        collectibleInterval - 0.01,
      );
      _statusText = 'Stage $stage Rush!';
      _statusRemaining = 1.8;
      add(
        FeedbackBurstComponent(
          position: Vector2(laneCenters[1], size.y * 0.38),
          color: AppColors.orange,
          baseRadius: 46,
          particles: 12,
          ring: true,
        ),
      );
    }

    distance += (scrollSpeed * dt * currentDistanceFactor).round();
    score = distance + (coins * 7) + styleBonus;
    _spawner!.update(dt);
    _syncSpeeds();
    _checkCollisions();
    _cleanup();
  }

  void moveLeft() => _player?.moveBy(-1);

  void moveRight() => _player?.moveBy(1);

  @override
  void spawnObstacle(int lane, ObstacleType type) {
    spawnObstacleWithOffset(lane, type, yOffset: 0);
  }

  @override
  void spawnObstacleWithOffset(
    int lane,
    ObstacleType type, {
    double yOffset = 0,
  }) {
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    final obstacle = ObstacleComponent(
      type: type,
      lane: lane,
      speed: scrollSpeed,
    )
      ..size = type == ObstacleType.pit ? Vector2(68, 40) : Vector2(58, 58)
      ..position = Vector2(laneCenters[lane], -40 + yOffset);
    _obstacles.add(obstacle);
    add(obstacle);
  }

  @override
  void spawnCollectible(int lane, CollectibleType type, {double yOffset = 0}) {
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    final collectible = CollectibleComponent(
      type: type,
      lane: lane,
      speed: scrollSpeed,
    )
      ..size = Vector2.all(type == CollectibleType.combo ? 42 : 38)
      ..position = Vector2(laneCenters[lane], -32 + yOffset);
    _collectibles.add(collectible);
    add(collectible);
  }

  @override
  bool laneHasObstacleNearSpawn(int lane,
      {double topLimit = GameConfig.spawnSafetyTop}) {
    return _obstacles.any(
      (obstacle) => obstacle.lane == lane && obstacle.position.y < topLimit,
    );
  }

  @override
  bool laneHasCollectibleNearSpawn(
    int lane, {
    double topLimit = GameConfig.spawnSafetyTop,
  }) {
    return _collectibles.any(
      (collectible) =>
          collectible.lane == lane && collectible.position.y < topLimit,
    );
  }

  void _syncSpeeds() {
    for (final obstacle in _obstacles) {
      obstacle.speed = scrollSpeed;
    }
    for (final collectible in _collectibles) {
      collectible.speed = scrollSpeed;
    }
  }

  void _checkCollisions() {
    final player = _player;
    if (player == null) {
      return;
    }
    final playerBox = player.hitbox;

    for (final obstacle in List<ObstacleComponent>.from(_obstacles)) {
      final obstacleBox = obstacle.hitbox;
      if (_shouldCrash(player, playerBox, obstacleBox)) {
        _finishRun();
        return;
      }
      final verticalGap = (player.position.y - obstacle.position.y).abs();
      if (verticalGap < GameConfig.nearMissDistance &&
          !playerBox.overlaps(obstacleBox) &&
          obstacle.lane == player.lane &&
          !obstacle.nearMissAwarded) {
        obstacle.nearMissAwarded = true;
        player.triggerNearMiss();
        styleBonus += GameConfig.nearMissScoreBonus;
        _statusText = 'Close one! +${GameConfig.nearMissScoreBonus}';
        _statusRemaining = 0.55;
        add(
          FeedbackBurstComponent(
            position: obstacle.position.clone(),
            color: AppColors.orange,
            baseRadius: 34,
            particles: 10,
            ring: true,
          ),
        );
        _audio.playNearMiss();
      }
    }

    for (final collectible in List<CollectibleComponent>.from(_collectibles)) {
      final shouldMagnetPull = magnetActive &&
          _distance(player.position, collectible.position) <
              GameConfig.magnetRadius;
      final laneChangePickup = player.isChangingLane &&
          (player.position.x - collectible.position.x).abs() <
              GameConfig.laneChangeCollectRadius &&
          (player.position.y - collectible.position.y).abs() < 34;
      if (playerBox.overlaps(collectible.hitbox) ||
          shouldMagnetPull ||
          laneChangePickup) {
        _collect(collectible);
      }
    }
  }

  bool _shouldCrash(
    PlayerComponent player,
    Rect playerBox,
    Rect obstacleBox,
  ) {
    final safeTargetLane = player.targetLane.clamp(0, laneCenters.length - 1);
    return shouldCrash(
      playerBox: playerBox,
      obstacleBox: obstacleBox,
      isChangingLane: player.isChangingLane,
      isEscaping: player.isEscapingFrom(obstacleBox.center.dx),
      targetLaneCenter: laneCenters[safeTargetLane],
    );
  }

  void _collect(CollectibleComponent collectible) {
    // Every pickup extends the combo window, so a tidy line of coins keeps the
    // multiplier alive while a scrappy run lets it lapse.
    final previousMultiplier = comboMultiplier;
    _comboPickups += 1;
    _comboRemaining = GameConfig.comboWindow;
    final multiplier = comboMultiplier;
    if (multiplier > previousMultiplier) {
      _statusText = 'Combo x$multiplier!';
      _statusRemaining = 1.2;
      add(
        FeedbackBurstComponent(
          position: collectible.position.clone(),
          color: AppColors.orange,
          baseRadius: 38,
          particles: 12,
          ring: true,
        ),
      );
    }

    switch (collectible.type) {
      case CollectibleType.coin:
        {
          coins += multiplier;
          add(
            FeedbackBurstComponent(
              position: collectible.position.clone(),
              color: AppColors.coin,
              baseRadius: 22,
              particles: 7,
            ),
          );
          break;
        }
      case CollectibleType.combo:
        {
          coins += GameConfig.comboCoinValue.toInt() * multiplier;
          _statusText = 'Combo Banana!';
          _statusRemaining = 1.4;
          add(
            FeedbackBurstComponent(
              position: collectible.position.clone(),
              color: AppColors.orange,
              baseRadius: 30,
              particles: 10,
              ring: true,
            ),
          );
          break;
        }
      case CollectibleType.magnet:
        {
          _magnetRemaining = GameConfig.magnetDuration;
          _statusText = 'Magnet mode!';
          _statusRemaining = 1.4;
          add(
            FeedbackBurstComponent(
              position: collectible.position.clone(),
              color: AppColors.mint,
              baseRadius: 30,
              particles: 9,
              ring: true,
            ),
          );
          break;
        }
    }
    _player?.triggerCollectBounce();
    _audio.playCoin();
    _removeCollectible(collectible);
  }

  void _configurePlayerForCurrentSize() {
    final player = _player;
    if (player == null || size.x <= 0 || size.y <= 0) {
      return;
    }
    player.configureLanes(
      laneCenters,
      size.y - GameConfig.playerBottomOffset,
    );
  }

  void _recalculateTrackGeometry() {
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    if (size.x <= 360) {
      _roadWidthFactor = 0.76;
    } else if (size.x <= 430) {
      _roadWidthFactor = 0.7;
    } else {
      _roadWidthFactor = 0.62;
    }
    _roadWidth = size.x * _roadWidthFactor;
    _roadLeft = (size.x - _roadWidth) / 2;
    for (var index = 0; index < _laneCenters.length; index++) {
      _laneCenters[index] =
          _roadLeft + _roadWidth / 6 + index * _roadWidth / 3 + laneVisualBias;
    }
  }

  void _cleanup() {
    for (final obstacle in List<ObstacleComponent>.from(_obstacles)) {
      if (obstacle.position.y > size.y + 70) {
        _removeObstacle(obstacle);
      }
    }
    for (final collectible in List<CollectibleComponent>.from(_collectibles)) {
      if (collectible.position.y > size.y + 60) {
        _removeCollectible(collectible);
      }
    }
  }

  void _removeObstacle(ObstacleComponent obstacle) {
    _obstacles.remove(obstacle);
    obstacle.removeFromParent();
  }

  void _removeCollectible(CollectibleComponent collectible) {
    _collectibles.remove(collectible);
    collectible.removeFromParent();
  }

  double _distance(Vector2 a, Vector2 b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  Future<void> _finishRun() async {
    if (_ended) {
      return;
    }
    _ended = true;
    final player = _player;
    if (player != null) {
      add(
        FeedbackBurstComponent(
          position: player.position.clone(),
          color: AppColors.coral,
          baseRadius: 42,
          particles: 12,
          ring: true,
        ),
      );
    }
    pauseEngine();
    await _audio.playCrash();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    _onGameOver(
      GameSessionResult(
        score: score,
        distance: distance,
        coinsCollected: coins,
        runsPlayed: 1,
      ),
    );
  }
}
