class DailyRewardState {
  const DailyRewardState({
    required this.streakDay,
    this.lastClaimedAtEpochMs,
  });

  /// Day of the streak that was most recently collected, 1-based.
  /// Meaningless while [lastClaimedAtEpochMs] is null.
  final int streakDay;
  final int? lastClaimedAtEpochMs;

  /// Coins granted for each day of an unbroken streak.
  static const List<int> rewardTable = [40, 60, 90, 130, 180, 260, 400];

  static int get streakLength => rewardTable.length;

  DateTime? get lastClaimedAt => lastClaimedAtEpochMs == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(lastClaimedAtEpochMs!);

  /// Calendar-day comparison rather than a rolling 24h window: claiming at
  /// 23:00 and again at 08:00 the next morning counts as two separate days.
  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool canClaim(DateTime now) {
    final last = lastClaimedAt;
    if (last == null) {
      return true;
    }
    return _dayOf(now).isAfter(_dayOf(last));
  }

  /// Streak day that claiming at [now] would land on. Resets to 1 whenever a
  /// day was skipped, so the reward always matches the day actually earned.
  int pendingDay(DateTime now) {
    final last = lastClaimedAt;
    if (last == null) {
      return 1;
    }
    final gap = _dayOf(now).difference(_dayOf(last)).inDays;
    if (gap != 1) {
      return 1;
    }
    return streakDay >= streakLength ? 1 : streakDay + 1;
  }

  int pendingReward(DateTime now) => rewardTable[pendingDay(now) - 1];

  DailyRewardState claim(DateTime now) {
    if (!canClaim(now)) {
      return this;
    }
    return DailyRewardState(
      streakDay: pendingDay(now),
      lastClaimedAtEpochMs: now.millisecondsSinceEpoch,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'streakDay': streakDay,
      'lastClaimedAtEpochMs': lastClaimedAtEpochMs,
    };
  }

  factory DailyRewardState.fromMap(Map<String, Object?> map) {
    return DailyRewardState(
      streakDay: (map['streakDay'] as int?) ?? 1,
      lastClaimedAtEpochMs: map['lastClaimedAtEpochMs'] as int?,
    );
  }
}
