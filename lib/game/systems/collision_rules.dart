import 'dart:ui';

import 'package:banana_escape/config/game_config.dart';

/// Decides whether an overlap between the player and an obstacle kills the run.
///
/// A raw `Rect.overlaps` test makes a lane runner feel cheap: the player reads
/// a near miss as a hit and blames the game. These rules sit on top of the
/// overlap and forgive the cases a human would call unfair — grazing an edge
/// mid-swipe, and clipping an obstacle you are already moving away from.
///
/// Kept free of Flame types so the rules can be exercised directly, which is
/// the whole point: this is the logic most likely to be tuned and most likely
/// to break quietly when it is.
///
/// [isEscaping] is whether the player is travelling away from the obstacle,
/// and [targetLaneCenter] is the centre of the lane the player is heading for
/// — an obstacle sitting in that lane is not escapable, however the swipe is
/// currently pointed.
bool shouldCrash({
  required Rect playerBox,
  required Rect obstacleBox,
  required bool isChangingLane,
  required bool isEscaping,
  required double targetLaneCenter,
}) {
  if (!playerBox.overlaps(obstacleBox)) {
    return false;
  }

  final overlap = playerBox.intersect(obstacleBox);
  if (overlap.width <= 0 || overlap.height <= 0) {
    return false;
  }

  final horizontalDistance =
      (playerBox.center.dx - obstacleBox.center.dx).abs();
  final requiredDistance = (playerBox.width + obstacleBox.width) * 0.5;
  final isGrazingEdge = horizontalDistance > requiredDistance * 0.54;
  final targetLaneMatchesObstacle =
      obstacleBox.center.dx >= targetLaneCenter - 28 &&
          obstacleBox.center.dx <= targetLaneCenter + 28;

  if (isChangingLane) {
    if (isEscaping &&
        !targetLaneMatchesObstacle &&
        overlap.width < GameConfig.laneEscapeGraceOverlapX) {
      return false;
    }
    if (overlap.width < GameConfig.laneChangeGraceOverlapX &&
        overlap.height < 30) {
      return false;
    }
    if (isGrazingEdge &&
        overlap.width < (GameConfig.collisionMinOverlapX + 6)) {
      return false;
    }
  }

  if (overlap.width < GameConfig.collisionMinOverlapX &&
      overlap.height < GameConfig.collisionMinOverlapY) {
    return false;
  }

  return true;
}
