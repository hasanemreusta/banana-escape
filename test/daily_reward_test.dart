import 'package:banana_escape/models/daily_reward.dart';
import 'package:banana_escape/models/game_profile.dart';
import 'package:flutter_test/flutter_test.dart';

DailyRewardState claimedOn(DateTime when, {required int streakDay}) {
  return DailyRewardState(
    streakDay: streakDay,
    lastClaimedAtEpochMs: when.millisecondsSinceEpoch,
  );
}

void main() {
  group('DailyRewardState', () {
    test('a fresh profile can claim day one', () {
      const state = DailyRewardState(streakDay: 1);
      final now = DateTime(2026, 8, 16, 9);

      expect(state.canClaim(now), isTrue);
      expect(state.pendingDay(now), 1);
      expect(state.pendingReward(now), DailyRewardState.rewardTable.first);
    });

    test('claiming twice on the same calendar day is refused', () {
      final morning = DateTime(2026, 8, 16, 9);
      final evening = DateTime(2026, 8, 16, 22);
      final state = const DailyRewardState(streakDay: 1).claim(morning);

      expect(state.canClaim(evening), isFalse);
      expect(state.claim(evening), same(state));
    });

    test('a late-night claim and an early-morning one are different days', () {
      final lateNight = DateTime(2026, 8, 16, 23, 30);
      final earlyMorning = DateTime(2026, 8, 17, 6, 15);
      final state = claimedOn(lateNight, streakDay: 1);

      expect(state.canClaim(earlyMorning), isTrue);
      expect(state.pendingDay(earlyMorning), 2);
    });

    test('consecutive days advance the streak', () {
      var state = const DailyRewardState(streakDay: 1);
      for (var day = 1; day <= 4; day++) {
        final now = DateTime(2026, 8, 15 + day);
        expect(state.pendingDay(now), day);
        state = state.claim(now);
        expect(state.streakDay, day);
      }
    });

    test('a skipped day restarts the streak at day one', () {
      final state = claimedOn(DateTime(2026, 8, 16), streakDay: 5);
      final twoDaysLater = DateTime(2026, 8, 18);

      expect(state.canClaim(twoDaysLater), isTrue);
      expect(state.pendingDay(twoDaysLater), 1);
      expect(
        state.pendingReward(twoDaysLater),
        DailyRewardState.rewardTable.first,
        reason: 'missing a day must not pay out the old high streak reward',
      );
    });

    test('the streak wraps after the last table entry', () {
      final state = claimedOn(
        DateTime(2026, 8, 16),
        streakDay: DailyRewardState.streakLength,
      );

      expect(state.pendingDay(DateTime(2026, 8, 17)), 1);
    });

    test('state survives a round trip through the persistence map', () {
      final original = claimedOn(DateTime(2026, 8, 16, 12), streakDay: 3);
      final restored = DailyRewardState.fromMap(original.toMap());

      expect(restored.streakDay, original.streakDay);
      expect(restored.lastClaimedAtEpochMs, original.lastClaimedAtEpochMs);
    });
  });

  group('GameProfile daily reward', () {
    test('claiming credits exactly the pending reward', () {
      final profile = GameProfile.initial();
      final now = DateTime(2026, 8, 16, 9);
      final expected = profile.dailyRewardState.pendingReward(now);

      final claimed = profile.claimDailyReward(now);

      expect(claimed.totalCoins, profile.totalCoins + expected);
      expect(claimed.canClaimDailyReward(now), isFalse);
    });

    test('a second claim on the same day is a no-op', () {
      final now = DateTime(2026, 8, 16, 9);
      final claimed = GameProfile.initial().claimDailyReward(now);

      final again = claimed.claimDailyReward(now);

      expect(again.totalCoins, claimed.totalCoins);
    });
  });
}
