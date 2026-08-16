import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/models/daily_reward.dart';
import 'package:flutter/material.dart';

class DailyRewardCard extends StatelessWidget {
  const DailyRewardCard({
    super.key,
    required this.state,
    required this.now,
    required this.onClaim,
  });

  final DailyRewardState state;
  final DateTime now;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final claimable = state.canClaim(now);
    final pendingDay = state.pendingDay(now);
    final reward = state.pendingReward(now);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: claimable
              ? const [Color(0xFF8DE7C4), Color(0xFF4FC1A0)]
              : [
                  Colors.white.withValues(alpha: 0.94),
                  Colors.white.withValues(alpha: 0.82),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                claimable
                    ? Icons.card_giftcard_rounded
                    : Icons.check_circle_rounded,
                color: claimable ? Colors.white : AppColors.leafDeep,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Bunch',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: claimable ? Colors.white : AppColors.ink,
                      ),
                    ),
                    Text(
                      claimable
                          ? 'Day $pendingDay reward: $reward coins'
                          : 'Collected. Come back tomorrow.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: claimable
                            ? Colors.white.withValues(alpha: 0.92)
                            : AppColors.softInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var day = 1; day <= DailyRewardState.streakLength; day++)
                Expanded(
                  child: _StreakPip(
                    day: day,
                    claimed: _isClaimed(day, pendingDay, claimable),
                    isNext: claimable && day == pendingDay,
                    onLight: claimable,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: claimable ? onClaim : null,
              style: FilledButton.styleFrom(
                backgroundColor:
                    claimable ? Colors.white : AppColors.panelAlt,
                foregroundColor: AppColors.ink,
                disabledBackgroundColor:
                    AppColors.panelAlt.withValues(alpha: 0.6),
                disabledForegroundColor:
                    AppColors.softInk.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                claimable ? 'Claim $reward coins' : 'Already claimed today',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A pip is lit when its day has already been banked in the current streak.
  /// While a reward is waiting, the pending day itself is not yet claimed.
  bool _isClaimed(int day, int pendingDay, bool claimable) {
    if (claimable) {
      return day < pendingDay;
    }
    return day <= state.streakDay;
  }
}

class _StreakPip extends StatelessWidget {
  const _StreakPip({
    required this.day,
    required this.claimed,
    required this.isNext,
    required this.onLight,
  });

  final int day;
  final bool claimed;
  final bool isNext;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color text;
    if (isNext) {
      fill = AppColors.bananaYellow;
      text = AppColors.ink;
    } else if (claimed) {
      fill = onLight
          ? Colors.white.withValues(alpha: 0.85)
          : AppColors.leafGreen.withValues(alpha: 0.75);
      text = AppColors.ink;
    } else {
      fill = onLight
          ? Colors.white.withValues(alpha: 0.26)
          : AppColors.panelAlt.withValues(alpha: 0.7);
      text = onLight ? Colors.white : AppColors.softInk;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          Container(
            height: 30,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: text,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${DailyRewardState.rewardTable[day - 1]}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: onLight
                  ? Colors.white.withValues(alpha: 0.9)
                  : AppColors.softInk,
            ),
          ),
        ],
      ),
    );
  }
}
