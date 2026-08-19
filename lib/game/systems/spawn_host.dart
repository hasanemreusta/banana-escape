import 'package:banana_escape/game/data/collectible_type.dart';
import 'package:banana_escape/game/data/obstacle_type.dart';

/// The slice of the game a [SpawnController] actually needs.
///
/// The controller decides *what* to spawn and *where*; it has no business
/// knowing about Flame, rendering, or the rest of the run state. Naming that
/// boundary lets the wave composition rules — above all the guarantee that a
/// wave never seals off all three lanes — be exercised against a stub instead
/// of a booted game.
abstract interface class SpawnHost {
  double get runTime;
  int get stage;
  double get obstacleInterval;
  double get collectibleInterval;
  bool get magnetActive;

  bool laneHasObstacleNearSpawn(int lane, {required double topLimit});

  bool laneHasCollectibleNearSpawn(int lane, {required double topLimit});

  void spawnObstacle(int lane, ObstacleType type);

  void spawnObstacleWithOffset(
    int lane,
    ObstacleType type, {
    required double yOffset,
  });

  void spawnCollectible(
    int lane,
    CollectibleType type, {
    required double yOffset,
  });
}
