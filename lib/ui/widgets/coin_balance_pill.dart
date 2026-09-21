import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/ui/format.dart';
import 'package:flutter/material.dart';

/// The player's bank, kept on screen wherever coins can be spent. With
/// [onTap] it grows a "+" and doubles as a way into the shop.
class CoinBalancePill extends StatelessWidget {
  const CoinBalancePill({super.key, required this.coins, this.onTap});

  final int coins;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: EdgeInsets.fromLTRB(10, 6, onTap == null ? 14 : 6, 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: AppColors.coinDeep,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                formatCoins(coins),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.leafGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
