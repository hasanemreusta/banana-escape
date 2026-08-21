import 'package:banana_escape/core/game_session_result.dart';
import 'package:banana_escape/models/game_profile.dart';
import 'package:banana_escape/models/mission.dart';
import 'package:flutter_test/flutter_test.dart';

GameSessionResult run({
  int score = 0,
  int distance = 0,
  int coins = 0,
  int runsPlayed = 1,
}) {
  return GameSessionResult(
    score: score,
    distance: distance,
    coinsCollected: coins,
    runsPlayed: runsPlayed,
  );
}

int progressOf(GameProfile profile, MissionMetric metric) {
  final mission = Missions.all.firstWhere((m) => m.metric == metric);
  return profile.missionProgress[mission.id]!;
}

MissionProgressView viewOf(GameProfile profile, MissionMetric metric) {
  return profile.missionViews
      .firstWhere((view) => view.definition.metric == metric);
}

void main() {
  group('single-run missions', () {
    test('record the best run rather than a running total', () {
      var profile = GameProfile.initial();

      profile = profile.applySession(run(coins: 12, distance: 300));
      profile = profile.applySession(run(coins: 7, distance: 120));

      expect(
        progressOf(profile, MissionMetric.coinsSingleRun),
        12,
        reason: 'a 12-coin run followed by a 7-coin run is still a best of 12',
      );
      expect(progressOf(profile, MissionMetric.distanceSingleRun), 300);
    });

    test('a worse run never lowers what was already achieved', () {
      var profile = GameProfile.initial()
          .applySession(run(coins: 25, distance: 640));

      profile = profile.applySession(run(coins: 0, distance: 0));

      expect(progressOf(profile, MissionMetric.coinsSingleRun), 25);
      expect(progressOf(profile, MissionMetric.distanceSingleRun), 640);
    });

    test('a better run replaces the old best', () {
      var profile = GameProfile.initial().applySession(run(coins: 5));

      profile = profile.applySession(run(coins: 18));

      expect(progressOf(profile, MissionMetric.coinsSingleRun), 18);
    });

    test('the coin wallet accumulates even though the mission does not', () {
      var profile = GameProfile.initial();

      profile = profile.applySession(run(coins: 10));
      profile = profile.applySession(run(coins: 10));

      expect(profile.totalCoins, 20);
      expect(progressOf(profile, MissionMetric.coinsSingleRun), 10);
    });
  });

  group('cumulative missions', () {
    test('run count adds up across sessions', () {
      var profile = GameProfile.initial();

      for (var i = 1; i <= 4; i++) {
        profile = profile.applySession(run());
        expect(progressOf(profile, MissionMetric.totalRuns), i);
        expect(profile.totalRuns, i);
      }
    });

    test('progress counts the run being applied, not only past ones', () {
      final profile = GameProfile.initial().applySession(run());

      expect(
        progressOf(profile, MissionMetric.totalRuns),
        profile.totalRuns,
        reason: 'the mission must not lag a run behind the profile counter',
      );
    });

    test('a session that plays no run leaves the count alone', () {
      final profile = GameProfile.initial()
          .applySession(run(coins: 30, runsPlayed: 0));

      expect(profile.totalRuns, 0);
      expect(progressOf(profile, MissionMetric.totalRuns), 0);
      expect(progressOf(profile, MissionMetric.coinsSingleRun), 30);
    });
  });

  group('completion', () {
    test('a mission completes exactly at its target, not one short', () {
      final mission = Missions.all
          .firstWhere((m) => m.metric == MissionMetric.coinsSingleRun);

      final justShort =
          GameProfile.initial().applySession(run(coins: mission.target - 1));
      final exact =
          GameProfile.initial().applySession(run(coins: mission.target));

      expect(viewOf(justShort, MissionMetric.coinsSingleRun).isComplete,
          isFalse);
      expect(viewOf(exact, MissionMetric.coinsSingleRun).isComplete, isTrue);
    });

    test('overshooting the target keeps the mission complete', () {
      final mission = Missions.all
          .firstWhere((m) => m.metric == MissionMetric.distanceSingleRun);
      final profile = GameProfile.initial()
          .applySession(run(distance: mission.target * 3));

      expect(viewOf(profile, MissionMetric.distanceSingleRun).isComplete,
          isTrue);
    });

    test('nothing is complete on a fresh profile', () {
      final profile = GameProfile.initial();

      expect(profile.missionViews.every((view) => !view.isComplete), isTrue);
      expect(profile.missionViews, hasLength(Missions.all.length));
    });
  });

  group('high score', () {
    test('rises only when the session beats it', () {
      var profile = GameProfile.initial().applySession(run(score: 800));

      profile = profile.applySession(run(score: 450));
      expect(profile.highScore, 800);

      profile = profile.applySession(run(score: 1200));
      expect(profile.highScore, 1200);
    });

    test('a tying score leaves the high score where it is', () {
      var profile = GameProfile.initial().applySession(run(score: 500));

      profile = profile.applySession(run(score: 500));

      expect(profile.highScore, 500);
    });
  });

  test('applying a session does not mutate the profile it came from', () {
    final original = GameProfile.initial();
    final before = Map<String, int>.from(original.missionProgress);

    original.applySession(run(coins: 40, distance: 900, score: 2000));

    expect(original.missionProgress, before);
    expect(original.totalCoins, 0);
    expect(original.totalRuns, 0);
    expect(original.highScore, 0);
  });
}
