import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/models/skin.dart';
import 'package:banana_escape/ui/widgets/banana_preview.dart';
import 'package:flutter/material.dart';

class SkinPreviewCard extends StatelessWidget {
  const SkinPreviewCard({
    super.key,
    required this.skin,
    required this.isOwned,
    required this.isEquipped,
    required this.availableCoins,
    required this.onPressed,
    required this.buttonLabel,
  });

  final BananaSkin skin;
  final bool isOwned;
  final bool isEquipped;
  final int availableCoins;
  final VoidCallback onPressed;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 152,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            skin.auraColor.withValues(alpha: 0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isEquipped ? AppColors.orange : Colors.white.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 92,
                height: 92,
                child: BananaPreview(
                  skin: skin,
                  angle: -0.12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            skin.name,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isOwned
                ? (isEquipped ? 'Equipped' : 'Owned')
                : '${skin.cost} coins',
            style: TextStyle(
              color: isOwned ? AppColors.leafGreen : AppColors.softInk,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          if (!isOwned) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (availableCoins / skin.cost).clamp(0, 1).toDouble(),
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.55),
              valueColor: AlwaysStoppedAnimation<Color>(skin.secondaryColor),
              borderRadius: BorderRadius.circular(999),
            ),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              skin.badge,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: isEquipped ? AppColors.ink : AppColors.orange,
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
