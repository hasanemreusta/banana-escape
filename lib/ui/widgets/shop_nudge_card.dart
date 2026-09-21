import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/models/shop_overview.dart';
import 'package:banana_escape/ui/format.dart';
import 'package:flutter/material.dart';

/// Ties the coin count to something to spend it on: either "you can buy N
/// things now" or progress toward the cheapest thing still out of reach.
/// Renders nothing once the shop has nothing left to sell.
class ShopNudgeCard extends StatelessWidget {
  const ShopNudgeCard({
    super.key,
    required this.overview,
    required this.coins,
    required this.onOpen,
    this.compact = false,
  });

  final ShopOverview overview;
  final int coins;
  final VoidCallback onOpen;

  /// Tighter padding for the run summary, where height is scarce.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final goal = overview.nextGoal;
    final canBuy = overview.affordableCount > 0;
    if (!canBuy && goal == null) {
      return const SizedBox.shrink();
    }

    final String headline;
    final String detail;
    if (canBuy) {
      headline = overview.affordableCount == 1
          ? '1 item ready to buy'
          : '${overview.affordableCount} items ready to buy';
      detail = 'Your coins are burning a hole in your peel.';
    } else {
      headline = 'Saving for ${goal!.title}';
      detail = '${formatCoins(goal.cost - coins)} coins to go';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: canBuy
                  ? const [Color(0xFFFFE9A8), Color(0xFFFFC87A)]
                  : [
                      Colors.white.withValues(alpha: 0.96),
                      AppColors.panel.withValues(alpha: 0.95),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 38 : 44,
                height: compact ? 38 : 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  canBuy
                      ? Icons.shopping_basket_rounded
                      : Icons.savings_rounded,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.softInk,
                      ),
                    ),
                    if (!canBuy) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (coins / goal!.cost).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: AppColors.panelAlt,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.bananaYellow,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}
