import 'dart:convert';

import 'package:banana_escape/core/game_session_result.dart';
import 'package:banana_escape/models/daily_reward.dart';
import 'package:banana_escape/models/mission.dart';
import 'package:banana_escape/models/skin.dart';

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
  });

  final int highScore;
  final int totalCoins;
  final bool soundOn;
  final int totalRuns;
  final Map<String, int> missionProgress;
  final List<String> ownedSkinIds;
  final String equippedSkinId;
  final DailyRewardState dailyRewardState;

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
    };
  }

  factory GameProfile.fromPrefs(Map<String, Object?> map) {
    final initial = GameProfile.initial();

    Map<String, int> decodeMissionProgress(Object? raw) {
      if (raw is! String || raw.isEmpty) {
        return Map<String, int>.from(initial.missionProgress);
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final mission in Missions.all)
          mission.id: (decoded[mission.id] as num?)?.toInt() ?? 0,
      };
    }

    DailyRewardState decodeDailyReward(Object? raw) {
      if (raw is! String || raw.isEmpty) {
        return initial.dailyRewardState;
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return DailyRewardState.fromMap(decoded);
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
