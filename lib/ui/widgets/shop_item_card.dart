import 'package:banana_escape/l10n/strings.dart';
import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/ui/format.dart';
import 'package:flutter/material.dart';

/// One row of the Fruit Stand: an upgrade track or a consumable. Progress is
/// shown as filled pips, so the same card serves "level 3 of 5" and
/// "2 of 5 shields held".
class ShopItemCard extends StatelessWidget {
  const ShopItemCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.detail,
    required this.filled,
    required this.total,
    required this.price,
    required this.affordable,
    required this.onPressed,
    this.maxedLabel,
  });

  final IconData icon;
  final String title;
  final String description;

  /// Current effect, e.g. "4.5s → 5.5s".
  final String detail;
  final int filled;
  final int total;

  /// Null when nothing more can be bought.
  final int? price;
  final bool affordable;
  final VoidCallback onPressed;
  /// Shown once maxed; defaults to the generic "Maxed".
  final String? maxedLabel;

  @override
  Widget build(BuildContext context) {
    final maxed = price == null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.96),
            AppColors.panel.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.panelAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.softInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var index = 0; index < total; index++)
                      Container(
                        width: 14,
                        height: 8,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: index < filled
                              ? AppColors.bananaYellow
                              : AppColors.panelAlt,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        detail,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: maxed ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor:
                  affordable ? AppColors.orange : const Color(0xFFD9D4DC),
              foregroundColor: affordable ? Colors.white : AppColors.softInk,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: maxed
                ? Text(
                    maxedLabel ?? S.current.maxed,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        affordable
                            ? Icons.monetization_on_rounded
                            : Icons.lock_rounded,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatCoins(price!),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
