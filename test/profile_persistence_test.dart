import 'dart:convert';

import 'package:banana_escape/core/game_session_result.dart';
import 'package:banana_escape/models/daily_reward.dart';
import 'package:banana_escape/models/game_profile.dart';
import 'package:banana_escape/models/mission.dart';
import 'package:banana_escape/models/skin.dart';
import 'package:banana_escape/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A profile with every field moved off its default, so a round trip that
/// silently drops one of them shows up as a failure rather than a coincidence.
GameProfile populatedProfile() {
  return GameProfile.initial()
      .applySession(
        GameSessionResult(
          score: 4200,
          distance: 730,
          coinsCollected: 26,
          runsPlayed: 5,
        ),
      )
      .copyWith(
        totalCoins: 1500,
        soundOn: false,
        dailyRewardState: DailyRewardState(
          streakDay: 4,
          lastClaimedAtEpochMs:
              DateTime(2026, 8, 18, 20, 30).millisecondsSinceEpoch,
        ),
      )
      .unlockSkin(BananaSkins.berryPop);
}

Future<StorageService> storageWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return StorageService(await SharedPreferences.getInstance());
}

void expectSameProfile(GameProfile actual, GameProfile expected) {
  expect(actual.highScore, expected.highScore);
  expect(actual.totalCoins, expected.totalCoins);
  expect(actual.soundOn, expected.soundOn);
  expect(actual.totalRuns, expected.totalRuns);
  expect(actual.missionProgress, expected.missionProgress);
  expect(actual.ownedSkinIds, expected.ownedSkinIds);
  expect(actual.equippedSkinId, expected.equippedSkinId);
  expect(
    actual.dailyRewardState.streakDay,
    expected.dailyRewardState.streakDay,
  );
  expect(
    actual.dailyRewardState.lastClaimedAtEpochMs,
    expected.dailyRewardState.lastClaimedAtEpochMs,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('prefs round trip', () {
    test('every field survives toPrefs and back', () {
      final original = populatedProfile();

      final restored = GameProfile.fromPrefs(original.toPrefs());

      expectSameProfile(restored, original);
    });

    test('an untouched profile round trips to the same defaults', () {
      final initial = GameProfile.initial();

      expectSameProfile(GameProfile.fromPrefs(initial.toPrefs()), initial);
    });

    test('an empty store reads back as a fresh profile', () {
      final loaded = GameProfile.fromPrefs(const {});

      expectSameProfile(loaded, GameProfile.initial());
      expect(loaded.equippedSkinId, BananaSkins.defaultId);
      expect(loaded.soundOn, isTrue, reason: 'sound defaults to on');
    });

    test('a partially written store keeps what it has and defaults the rest',
        () {
      final loaded = GameProfile.fromPrefs(const {
        'highScore': 900,
        'totalCoins': 120,
      });

      expect(loaded.highScore, 900);
      expect(loaded.totalCoins, 120);
      expect(loaded.totalRuns, 0);
      expect(loaded.soundOn, isTrue);
      expect(loaded.ownedSkinIds, [BananaSkins.defaultId]);
      expect(loaded.missionProgress, GameProfile.initial().missionProgress);
    });
  });

  group('mission progress storage', () {
    test('a mission absent from stored data starts at zero', () {
      final known = Missions.all.first;
      final loaded = GameProfile.fromPrefs({
        'missionProgress': jsonEncode({known.id: 14}),
      });

      expect(loaded.missionProgress[known.id], 14);
      expect(loaded.missionProgress, hasLength(Missions.all.length));
      for (final mission in Missions.all.skip(1)) {
        expect(loaded.missionProgress[mission.id], 0);
      }
    });

    test('progress for a mission that no longer exists is dropped', () {
      final loaded = GameProfile.fromPrefs({
        'missionProgress': jsonEncode({
          'retired_mission': 99,
          Missions.all.first.id: 3,
        }),
      });

      expect(loaded.missionProgress.containsKey('retired_mission'), isFalse);
      expect(loaded.missionProgress[Missions.all.first.id], 3);
    });

    test('a corrupt mission blob falls back instead of bricking the launch',
        () {
      final loaded = GameProfile.fromPrefs(const {
        'highScore': 700,
        'missionProgress': 'not json at all',
      });

      expect(loaded.missionProgress, GameProfile.initial().missionProgress);
      expect(loaded.highScore, 700, reason: 'the rest must still load');
    });

    test('a mission blob of the wrong shape falls back too', () {
      final loaded = GameProfile.fromPrefs({
        'missionProgress': jsonEncode([1, 2, 3]),
      });

      expect(loaded.missionProgress, GameProfile.initial().missionProgress);
    });
  });

  group('daily reward storage', () {
    test('a claimed streak survives the round trip', () {
      final claimed =
          GameProfile.initial().claimDailyReward(DateTime(2026, 8, 20, 9));

      final restored = GameProfile.fromPrefs(claimed.toPrefs());

      expect(restored.canClaimDailyReward(DateTime(2026, 8, 20, 23)), isFalse);
      expect(restored.canClaimDailyReward(DateTime(2026, 8, 21, 7)), isTrue);
      expect(restored.dailyRewardState.pendingDay(DateTime(2026, 8, 21, 7)), 2);
    });

    test('a corrupt reward blob falls back to an unclaimed streak', () {
      final loaded = GameProfile.fromPrefs(const {
        'dailyReward': '{oops',
      });

      expect(loaded.dailyRewardState.lastClaimedAtEpochMs, isNull);
      expect(loaded.canClaimDailyReward(DateTime(2026, 8, 21)), isTrue);
    });

    test('a nonsense streak day cannot push the reward table out of range', () {
      final tomorrow = DateTime(2026, 8, 21);

      for (final storedDay in [-3, 0, 99]) {
        final loaded = GameProfile.fromPrefs({
          'dailyReward': jsonEncode({
            'streakDay': storedDay,
            'lastClaimedAtEpochMs':
                DateTime(2026, 8, 20).millisecondsSinceEpoch,
          }),
        });
        final state = loaded.dailyRewardState;

        expect(
          state.streakDay,
          inInclusiveRange(1, DailyRewardState.streakLength),
        );
        expect(
          state.pendingDay(tomorrow),
          inInclusiveRange(1, DailyRewardState.streakLength),
        );
        expect(
          DailyRewardState.rewardTable,
          contains(state.pendingReward(tomorrow)),
          reason: 'stored day $storedDay must still pay a real table entry',
        );
      }
    });
  });

  group('skins', () {
    test('buying a skin spends the coins, owns it and equips it', () {
      final profile = GameProfile.initial().copyWith(totalCoins: 600);

      final after = profile.unlockSkin(BananaSkins.berryPop);

      expect(after.totalCoins, 600 - BananaSkins.berryPop.cost);
      expect(after.ownsSkin(BananaSkins.berryPop.id), isTrue);
      expect(after.equippedSkinId, BananaSkins.berryPop.id);
    });

    test('a skin you cannot afford is not sold on credit', () {
      final profile = GameProfile.initial().copyWith(totalCoins: 10);

      final after = profile.unlockSkin(BananaSkins.galaxyPeel);

      expect(after.totalCoins, 10);
      expect(after.ownsSkin(BananaSkins.galaxyPeel.id), isFalse);
      expect(profile.canUnlockSkin(BananaSkins.galaxyPeel), isFalse);
    });

    test('buying a skin twice does not charge twice', () {
      final owned = GameProfile.initial()
          .copyWith(totalCoins: 600)
          .unlockSkin(BananaSkins.berryPop);

      final again = owned.unlockSkin(BananaSkins.berryPop);

      expect(again.totalCoins, owned.totalCoins);
      expect(again.ownedSkinIds, owned.ownedSkinIds);
    });

    test('an unowned skin cannot be equipped', () {
      final profile = GameProfile.initial();

      final after = profile.equipSkin(BananaSkins.galaxyPeel.id);

      expect(after.equippedSkinId, BananaSkins.defaultId);
    });

    test('ownership and the equipped skin survive the round trip', () {
      final bought = GameProfile.initial()
          .copyWith(totalCoins: 2000)
          .unlockSkin(BananaSkins.mintChip)
          .unlockSkin(BananaSkins.galaxyPeel)
          .equipSkin(BananaSkins.mintChip.id);

      final restored = GameProfile.fromPrefs(bought.toPrefs());

      expect(restored.ownedSkinIds, bought.ownedSkinIds);
      expect(restored.equippedSkinId, BananaSkins.mintChip.id);
      expect(BananaSkins.byId(restored.equippedSkinId).name, 'Mint Chip');
    });
  });

  group('StorageService', () {
    test('a first launch loads the starting profile', () async {
      final storage = await storageWith({});

      expectSameProfile(await storage.loadProfile(), GameProfile.initial());
    });

    test('a saved profile comes back intact', () async {
      final storage = await storageWith({});
      final profile = populatedProfile();

      await storage.saveProfile(profile);

      expectSameProfile(await storage.loadProfile(), profile);
    });

    test('saving again overwrites rather than appending', () async {
      final storage = await storageWith({});
      final first = GameProfile.initial()
          .copyWith(totalCoins: 2000)
          .unlockSkin(BananaSkins.mintChip)
          .unlockSkin(BananaSkins.berryPop);
      await storage.saveProfile(first);

      final second = first.equipSkin(BananaSkins.defaultId);
      await storage.saveProfile(second);

      final loaded = await storage.loadProfile();
      expect(loaded.ownedSkinIds, first.ownedSkinIds);
      expect(loaded.equippedSkinId, BananaSkins.defaultId);
    });

    test('a run played then saved is still there on the next launch', () async {
      final storage = await storageWith({});
      final played = GameProfile.initial().applySession(
        GameSessionResult(
          score: 1800,
          distance: 540,
          coinsCollected: 22,
          runsPlayed: 1,
        ),
      );

      await storage.saveProfile(played);
      final reloaded = await storage.loadProfile();

      expect(reloaded.highScore, 1800);
      expect(reloaded.totalCoins, 22);
      expect(reloaded.totalRuns, 1);
      expect(
        reloaded.missionViews.where((view) => view.isComplete).length,
        played.missionViews.where((view) => view.isComplete).length,
      );
    });

    test('the sound setting is stored, including when it is off', () async {
      final storage = await storageWith({});

      await storage.saveProfile(GameProfile.initial().copyWith(soundOn: false));

      expect((await storage.loadProfile()).soundOn, isFalse);
    });

    test('a store left behind by a corrupt write still opens', () async {
      final storage = await storageWith({
        'highScore': 350,
        'missionProgress': 'truncated{',
        'dailyReward': 'truncated{',
      });

      final loaded = await storage.loadProfile();

      expect(loaded.highScore, 350);
      expect(loaded.missionProgress, GameProfile.initial().missionProgress);
      expect(loaded.dailyRewardState.lastClaimedAtEpochMs, isNull);
    });
  });
}
