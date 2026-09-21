import 'dart:convert';

import 'package:banana_escape/core/game_session_result.dart';
import 'package:banana_escape/models/daily_reward.dart';
import 'package:banana_escape/models/mission.dart';
import 'package:banana_escape/models/skin.dart';
import 'package:banana_escape/models/upgrade.dart';

class GameProfile {
  const GameProfile({
    required this.highScore,
    required this.totalCoins,
    required this.soundOn,
    required this.totalRuns,
    required this.missionProgress,
    required this.ownedSkinIds,
    required this.equippedSkinId,
    required this.dailyRewardState,
    required this.upgradeLevels,
    required this.shieldCount,
  });

  final int highScore;
  final int totalCoins;
  final bool soundOn;
  final int totalRuns;
  final Map<String, int> missionProgress;
  final List<String> ownedSkinIds;
  final String equippedSkinId;
  final DailyRewardState dailyRewardState;

  /// Level per [UpgradeDefinition.id]; a missing key means level 0.
  final Map<String, int> upgradeLevels;
  final int shieldCount;

  factory GameProfile.initial() {
    return GameProfile(
      highScore: 0,
      totalCoins: 0,
      soundOn: true,
      totalRuns: 0,
      missionProgress: {
        for (final mission in Missions.all) mission.id: 0,
      },
      ownedSkinIds: const [BananaSkins.defaultId],
      equippedSkinId: BananaSkins.defaultId,
      dailyRewardState: const DailyRewardState(streakDay: 1),
      upgradeLevels: {
        for (final upgrade in Upgrades.all) upgrade.id: 0,
      },
      shieldCount: 0,
    );
  }

  GameProfile copyWith({
    int? highScore,
    int? totalCoins,
    bool? soundOn,
    int? totalRuns,
    Map<String, int>? missionProgress,
    List<String>? ownedSkinIds,
    String? equippedSkinId,
    DailyRewardState? dailyRewardState,
    Map<String, int>? upgradeLevels,
    int? shieldCount,
  }) {
    return GameProfile(
      highScore: highScore ?? this.highScore,
      totalCoins: totalCoins ?? this.totalCoins,
      soundOn: soundOn ?? this.soundOn,
      totalRuns: totalRuns ?? this.totalRuns,
      missionProgress: missionProgress ?? this.missionProgress,
      ownedSkinIds: ownedSkinIds ?? this.ownedSkinIds,
      equippedSkinId: equippedSkinId ?? this.equippedSkinId,
      dailyRewardState: dailyRewardState ?? this.dailyRewardState,
      upgradeLevels: upgradeLevels ?? this.upgradeLevels,
      shieldCount: shieldCount ?? this.shieldCount,
    );
  }

  GameProfile applySession(GameSessionResult session) {
    final nextRuns = totalRuns + session.runsPlayed;
    final nextMissionProgress = Map<String, int>.from(missionProgress);

    for (final mission in Missions.all) {
      final previous = nextMissionProgress[mission.id] ?? 0;
      switch (mission.metric) {
        case MissionMetric.coinsSingleRun:
          nextMissionProgress[mission.id] = previous > session.coinsCollected
              ? previous
              : session.coinsCollected;
        case MissionMetric.distanceSingleRun:
          nextMissionProgress[mission.id] =
              previous > session.distance ? previous : session.distance;
        case MissionMetric.totalRuns:
          nextMissionProgress[mission.id] = nextRuns;
      }
    }

    return copyWith(
      highScore: session.score > highScore ? session.score : highScore,
      totalCoins: totalCoins + session.coinsCollected,
      totalRuns: nextRuns,
      missionProgress: nextMissionProgress,
    );
  }

  bool canClaimDailyReward(DateTime now) =>
      dailyRewardState.canClaim(now);

  /// Grants today's streak reward and advances the streak. Returns the profile
  /// unchanged when the reward was already collected today.
  GameProfile claimDailyReward(DateTime now) {
    if (!dailyRewardState.canClaim(now)) {
      return this;
    }
    return copyWith(
      totalCoins: totalCoins + dailyRewardState.pendingReward(now),
      dailyRewardState: dailyRewardState.claim(now),
    );
  }

  bool ownsSkin(String skinId) {
    return ownedSkinIds.contains(skinId);
  }

  bool canUnlockSkin(BananaSkin skin) {
    return skin.isDefault || ownsSkin(skin.id) || totalCoins >= skin.cost;
  }

  GameProfile unlockSkin(BananaSkin skin) {
    if (skin.isDefault || ownsSkin(skin.id)) {
      return this;
    }
    if (totalCoins < skin.cost) {
      return this;
    }
    return copyWith(
      totalCoins: totalCoins - skin.cost,
      ownedSkinIds: [...ownedSkinIds, skin.id],
      equippedSkinId: skin.id,
    );
  }

  GameProfile equipSkin(String skinId) {
    if (!ownsSkin(skinId) && skinId != BananaSkins.defaultId) {
      return this;
    }
    return copyWith(equippedSkinId: skinId);
  }

  int upgradeLevel(UpgradeDefinition upgrade) {
    return (upgradeLevels[upgrade.id] ?? 0)
        .clamp(0, UpgradeDefinition.maxLevel);
  }

  bool canBuyUpgrade(UpgradeDefinition upgrade) {
    final cost = upgrade.costToUpgradeFrom(upgradeLevel(upgrade));
    return cost != null && totalCoins >= cost;
  }

  GameProfile buyUpgrade(UpgradeDefinition upgrade) {
    final level = upgradeLevel(upgrade);
    final cost = upgrade.costToUpgradeFrom(level);
    if (cost == null || totalCoins < cost) {
      return this;
    }
    return copyWith(
      totalCoins: totalCoins - cost,
      upgradeLevels: {...upgradeLevels, upgrade.id: level + 1},
    );
  }

  bool get canBuyShield =>
      shieldCount < Shop.maxShields && totalCoins >= Shop.shieldCost;

  GameProfile buyShield() {
    if (!canBuyShield) {
      return this;
    }
    return copyWith(
      totalCoins: totalCoins - Shop.shieldCost,
      shieldCount: shieldCount + 1,
    );
  }

  GameProfile consumeShield() {
    if (shieldCount <= 0) {
      return this;
    }
    return copyWith(shieldCount: shieldCount - 1);
  }

  /// Takes [amount] from the bank, or returns the profile unchanged when the
  /// bank cannot cover it.
  GameProfile spendCoins(int amount) {
    if (amount < 0 || totalCoins < amount) {
      return this;
    }
    return copyWith(totalCoins: totalCoins - amount);
  }

  RunLoadout get runLoadout {
    return RunLoadout(
      magnetDuration: Upgrades.magnet.valueAt(upgradeLevel(Upgrades.magnet)),
      comboWindow:
          Upgrades.comboWindow.valueAt(upgradeLevel(Upgrades.comboWindow)),
      comboCoinValue:
          Upgrades.comboBanana.valueAt(upgradeLevel(Upgrades.comboBanana)),
      hasShield: shieldCount > 0,
    );
  }

  Map<String, Object?> toPrefs() {
    return {
      'highScore': highScore,
      'totalCoins': totalCoins,
      'soundOn': soundOn,
      'totalRuns': totalRuns,
      'missionProgress': jsonEncode(missionProgress),
      'ownedSkinIds': ownedSkinIds,
      'equippedSkinId': equippedSkinId,
      'dailyReward': jsonEncode(dailyRewardState.toMap()),
      'upgradeLevels': jsonEncode(upgradeLevels),
      'shieldCount': shieldCount,
    };
  }

  factory GameProfile.fromPrefs(Map<String, Object?> map) {
    final initial = GameProfile.initial();

    // Both blobs are JSON inside a preferences string, so a half-written or
    // hand-edited value is possible. This runs during startup, before any
    // screen exists to report an error, so a throw here would leave the app
    // unable to launch at all — losing the stored progress is the better of
    // the two outcomes.
    Map<String, int> decodeMissionProgress(Object? raw) {
      if (raw is! String || raw.isEmpty) {
        return Map<String, int>.from(initial.missionProgress);
      }
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return {
          for (final mission in Missions.all)
            mission.id: (decoded[mission.id] as num?)?.toInt() ?? 0,
        };
      } on Object {
        return Map<String, int>.from(initial.missionProgress);
      }
    }

    DailyRewardState decodeDailyReward(Object? raw) {
      if (raw is! String || raw.isEmpty) {
        return initial.dailyRewardState;
      }
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return DailyRewardState.fromMap(decoded);
      } on Object {
        return initial.dailyRewardState;
      }
    }

    Map<String, int> decodeUpgradeLevels(Object? raw) {
      if (raw is! String || raw.isEmpty) {
        return Map<String, int>.from(initial.upgradeLevels);
      }
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return {
          for (final upgrade in Upgrades.all)
            upgrade.id: ((decoded[upgrade.id] as num?)?.toInt() ?? 0)
                .clamp(0, UpgradeDefinition.maxLevel),
        };
      } on Object {
        return Map<String, int>.from(initial.upgradeLevels);
      }
    }

    return GameProfile(
      highScore: (map['highScore'] as int?) ?? 0,
      totalCoins: (map['totalCoins'] as int?) ?? 0,
      soundOn: (map['soundOn'] as bool?) ?? true,
      totalRuns: (map['totalRuns'] as int?) ?? 0,
      missionProgress: decodeMissionProgress(map['missionProgress']),
      ownedSkinIds:
          ((map['ownedSkinIds'] as List<Object?>?) ?? initial.ownedSkinIds)
              .whereType<String>()
              .toList(),
      equippedSkinId:
          (map['equippedSkinId'] as String?) ?? BananaSkins.defaultId,
      dailyRewardState: decodeDailyReward(map['dailyReward']),
      upgradeLevels: decodeUpgradeLevels(map['upgradeLevels']),
      shieldCount:
          ((map['shieldCount'] as int?) ?? 0).clamp(0, Shop.maxShields),
    );
  }

  List<MissionProgressView> get missionViews {
    return Missions.all
        .map(
          (mission) => MissionProgressView(
            definition: mission,
            progress: missionProgress[mission.id] ?? 0,
          ),
        )
        .toList();
  }
}
