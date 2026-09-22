import 'package:banana_escape/config/game_config.dart';
import 'package:flutter/material.dart';

enum UpgradeType {
  magnet,
  comboWindow,
  comboBanana,
}

class UpgradeDefinition {
  const UpgradeDefinition({
    required this.type,
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.baseValue,
    required this.valuePerLevel,
    required this.unit,
  });

  final UpgradeType type;

  /// Storage key. Never rename one that has shipped — saved levels are keyed
  /// by it.
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final double baseValue;
  final double valuePerLevel;
  final String unit;

  static const int maxLevel = 5;

  /// Price of each step up, indexed by the level being left. A good run
  /// banks 100-300 coins, so the first step is a few runs away and the last
  /// is a goal measured in weeks, not an evening.
  static const List<int> levelCosts = [500, 1500, 4000, 10000, 25000];

  double valueAt(int level) =>
      baseValue + valuePerLevel * level.clamp(0, maxLevel);

  /// Cost of going from [level] to the next one, or null once maxed.
  int? costToUpgradeFrom(int level) {
    if (level < 0 || level >= maxLevel) {
      return null;
    }
    return levelCosts[level];
  }

  String formatValue(double value) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text$unit';
  }
}

class Upgrades {
  const Upgrades._();

  static const UpgradeDefinition magnet = UpgradeDefinition(
    type: UpgradeType.magnet,
    id: 'magnet_duration',
    title: 'Longer Magnet',
    description: 'Magnet pickups pull coins for longer.',
    icon: Icons.auto_fix_high_rounded,
    baseValue: GameConfig.magnetDuration,
    valuePerLevel: 1,
    unit: 's',
  );

  static const UpgradeDefinition comboWindow = UpgradeDefinition(
    type: UpgradeType.comboWindow,
    id: 'combo_window',
    title: 'Steady Combo',
    description: 'More time between pickups before a combo lapses.',
    icon: Icons.local_fire_department_rounded,
    baseValue: GameConfig.comboWindow,
    valuePerLevel: 0.4,
    unit: 's',
  );

  static const UpgradeDefinition comboBanana = UpgradeDefinition(
    type: UpgradeType.comboBanana,
    id: 'combo_banana_value',
    title: 'Juicier Bananas',
    description: 'Coins paid out per combo banana.',
    icon: Icons.monetization_on_rounded,
    baseValue: GameConfig.comboCoinValue,
    valuePerLevel: 2,
    unit: '',
  );

  static const List<UpgradeDefinition> all = [magnet, comboWindow, comboBanana];
}

class Shop {
  const Shop._();

  static const int shieldCost = 750;

  /// Shields held at once. Keeps a coin hoard from turning into a stockpile
  /// that trivialises the game for weeks.
  static const int maxShields = 5;

  /// The first continue in a run costs this; each further one doubles it.
  static const int reviveBaseCost = 500;

  /// Purchases at or above this ask for confirmation first; a mis-tap should
  /// never cost a week of runs.
  static const int confirmThreshold = 5000;

  static int reviveCost(int revivesUsedThisRun) {
    return reviveBaseCost * (1 << revivesUsedThisRun.clamp(0, 10));
  }
}

/// What a single run starts with, resolved from the profile before the game
/// is built so the game never reads storage.
class RunLoadout {
  const RunLoadout({
    required this.magnetDuration,
    required this.comboWindow,
    required this.comboCoinValue,
    required this.shieldStock,
  });

  static const RunLoadout base = RunLoadout(
    magnetDuration: GameConfig.magnetDuration,
    comboWindow: GameConfig.comboWindow,
    comboCoinValue: GameConfig.comboCoinValue,
    shieldStock: 0,
  );

  final double magnetDuration;
  final double comboWindow;
  final double comboCoinValue;
  /// Shields the player can raise during the run, one double-tap each.
  final int shieldStock;
}
