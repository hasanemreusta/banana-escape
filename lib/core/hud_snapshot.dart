class HudSnapshot {
  const HudSnapshot({
    required this.score,
    required this.distance,
    required this.coins,
    required this.stage,
    required this.magnetRemaining,
    required this.runTime,
    required this.statusText,
    required this.comboMultiplier,
    required this.comboRemaining,
  });

  final int score;
  final int distance;
  final int coins;
  final int stage;
  final double magnetRemaining;
  final double runTime;
  final String? statusText;

  /// 1 when no combo is running, otherwise the active coin multiplier.
  final int comboMultiplier;

  /// Seconds left before the combo lapses.
  final double comboRemaining;

  static const empty = HudSnapshot(
    score: 0,
    distance: 0,
    coins: 0,
    stage: 1,
    magnetRemaining: 0,
    runTime: 0,
    statusText: null,
    comboMultiplier: 1,
    comboRemaining: 0,
  );

  @override
  bool operator ==(Object other) {
    return other is HudSnapshot &&
        other.score == score &&
        other.distance == distance &&
        other.coins == coins &&
        other.stage == stage &&
        other.magnetRemaining.toStringAsFixed(1) ==
            magnetRemaining.toStringAsFixed(1) &&
        other.runTime.toStringAsFixed(1) == runTime.toStringAsFixed(1) &&
        other.statusText == statusText &&
        other.comboMultiplier == comboMultiplier &&
        other.comboRemaining.toStringAsFixed(1) ==
            comboRemaining.toStringAsFixed(1);
  }

  @override
  int get hashCode => Object.hash(
        score,
        distance,
        coins,
        stage,
        magnetRemaining.toStringAsFixed(1),
        runTime.toStringAsFixed(1),
        statusText,
        comboMultiplier,
        comboRemaining.toStringAsFixed(1),
      );
}
