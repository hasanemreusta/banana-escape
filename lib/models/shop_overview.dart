import 'package:banana_escape/models/game_profile.dart';
import 'package:banana_escape/models/skin.dart';
import 'package:banana_escape/models/upgrade.dart';

enum ShopTab { upgrades, skins }

/// One thing the shop could sell this profile right now.
class ShopOffer {
  const ShopOffer({
    required this.title,
    required this.cost,
    required this.tab,
  });

  final String title;
  final int cost;
  final ShopTab tab;
}

/// What the shop means to a profile at a glance: how many things it can buy
/// today, and the cheapest one it is still saving for. Drives the badge on the
/// menu's shop button and the nudge on the run summary.
class ShopOverview {
  const ShopOverview({
    required this.affordableCount,
    required this.nextGoal,
  });

  final int affordableCount;

  /// Cheapest offer the profile cannot afford yet, or null when everything
  /// left is affordable (or nothing is left).
  final ShopOffer? nextGoal;

  factory ShopOverview.of(GameProfile profile) {
    final offers = offersFor(profile);
    final affordable =
        offers.where((offer) => offer.cost <= profile.totalCoins).length;
    final saving = offers
        .where((offer) => offer.cost > profile.totalCoins)
        .toList()
      ..sort((a, b) => a.cost.compareTo(b.cost));
    return ShopOverview(
      affordableCount: affordable,
      nextGoal: saving.isEmpty ? null : saving.first,
    );
  }

  /// Every purchase still open to [profile]. A shield only counts while the
  /// stock is empty — otherwise a 200-coin shield would always be the "next"
  /// thing, and the nudge would never point at anything that lasts.
  static List<ShopOffer> offersFor(GameProfile profile) {
    return [
      if (profile.shieldCount == 0)
        const ShopOffer(
          title: 'Peel Shield',
          cost: Shop.shieldCost,
          tab: ShopTab.upgrades,
        ),
      for (final upgrade in Upgrades.all)
        if (upgrade.costToUpgradeFrom(profile.upgradeLevel(upgrade))
            case final cost?)
          ShopOffer(
            title: '${upgrade.title} Lv ${profile.upgradeLevel(upgrade) + 1}',
            cost: cost,
            tab: ShopTab.upgrades,
          ),
      for (final skin in BananaSkins.all)
        if (!skin.isOwned(profile.ownedSkinIds))
          ShopOffer(title: skin.name, cost: skin.cost, tab: ShopTab.skins),
    ];
  }
}
