import 'dart:ui';

class GameConfig {
  const GameConfig._();

  static const Size referenceSize = Size(420, 840);
  static const int laneCount = 3;
  static const double playerBottomOffset = 126;
  static const double initialScrollSpeed = 285;
  static const double maxScrollSpeed = 530;
  static const double speedIncrease = 20;
  static const double accelerationPerSecond = 4.2;
  static const double difficultyInterval = 10;
  static const double stageInterval = 15;
  static const double distanceFactor = 0.58;
  static const double stageDistanceFactorBonus = 0.018;
  static const double initialObstacleInterval = 1.35;
  static const double obstacleIntervalMin = 0.72;
  static const double obstacleIntervalStep = 0.07;
  static const double initialCollectibleInterval = 0.95;
  static const double collectibleIntervalMin = 0.62;
  /// Seconds a combo survives without picking anything up.
  static const double comboWindow = 2.6;

  /// Coins needed per multiplier step, and the ceiling that step can reach.
  static const int comboStep = 6;
  static const int comboMaxMultiplier = 5;

  static const double magnetDuration = 4.5;
  static const double magnetRadius = 110;
  static const double comboCoinValue = 5;
  static const double spawnSafetyTop = 250;
  static const double collectibleVerticalGap = 58;
  static const double laneMoveSpeed = 26;
  static const double laneMoveDuration = 0.11;
  static const double laneChangeCollectRadius = 34;
  static const double obstacleHitboxWidthFactor = 0.66;
  static const double obstacleHitboxHeightFactor = 0.68;
  static const double playerHitboxWidthFactor = 0.5;
  static const double playerHitboxHeightFactor = 0.62;
  static const double nearMissDistance = 34;
  static const double playerVisualOffsetX = 0;
  static const double truckVisualOffsetX = 0;
  static const double collisionMinOverlapX = 18;
  static const double collisionMinOverlapY = 20;
  static const double laneChangeGraceOverlapX = 28;
  static const double laneEscapeGraceOverlapX = 34;
  static const int nearMissScoreBonus = 15;
  static const double earlyGameSafeDuration = 9;
  static const double midGamePressureStart = 20;
  static const double lateGamePressureStart = 35;
  static const double swipeThreshold = 18;
  static const double swipeVelocityThreshold = 240;
}
