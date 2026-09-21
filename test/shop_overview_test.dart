import 'package:banana_escape/models/game_profile.dart';
import 'package:banana_escape/models/shop_overview.dart';
import 'package:banana_escape/models/skin.dart';
import 'package:banana_escape/models/upgrade.dart';
import 'package:flutter_test/flutter_test.dart';

GameProfile withCoins(int coins) =>
    GameProfile.initial().copyWith(totalCoins: coins);

/// Everything bought: every skin owned, every upgrade maxed, shields full.
GameProfile everythingOwned() {
  return GameProfile.initial().copyWith(
    totalCoins: 0,
    ownedSkinIds: [for (final skin in BananaSkins.all) skin.id],
    upgradeLevels: {
      for (final upgrade in Upgrades.all)
        upgrade.id: UpgradeDefinition.maxLevel,
    },
    shieldCount: Shop.maxShields,
  );
}

void main() {
  group('ShopOverview', () {
    test('a broke new player is saving for the cheapest thing', () {
      final overview = ShopOverview.of(withCoins(0));
      expect(overview.affordableCount, 0);
      expect(overview.nextGoal, isNotNull);
      expect(overview.nextGoal!.cost, UpgradeDefinition.levelCosts[0]);
    });

    test('counts every offer the bank covers', () {
      // Enough for the three level-1 upgrades and a shield, but not the
      // cheapest skin.
      final bank = BananaSkins.mintChip.cost - 1;
      expect(bank, greaterThanOrEqualTo(Shop.shieldCost));
      expect(bank, greaterThanOrEqualTo(UpgradeDefinition.levelCosts[0]));
      final overview = ShopOverview.of(withCoins(bank));
      expect(overview.affordableCount, Upgrades.all.length + 1);
      expect(overview.nextGoal!.title, BananaSkins.mintChip.name);
      expect(overview.nextGoal!.tab, ShopTab.skins);
    });

    test('the goal is the cheapest thing still out of reach', () {
      final overview = ShopOverview.of(withCoins(BananaSkins.mintChip.cost));
      final cheapestLeft = ShopOverview.offersFor(
        withCoins(BananaSkins.mintChip.cost),
      )
          .map((offer) => offer.cost)
          .where((cost) => cost > BananaSkins.mintChip.cost)
          .reduce((a, b) => a < b ? a : b);
      expect(overview.nextGoal!.cost, cheapestLeft);
    });

    test('a held shield stops counting as something to buy', () {
      final withShield = withCoins(1000).buyShield();
      final titles = ShopOverview.offersFor(withShield).map((o) => o.title);
      expect(titles, isNot(contains('Peel Shield')));
    });

    test('upgrade offers name the level they lead to', () {
      final profile = withCoins(1000).buyUpgrade(Upgrades.magnet);
      final titles = ShopOverview.offersFor(profile).map((o) => o.title);
      expect(titles, contains('${Upgrades.magnet.title} Lv 2'));
    });

    test('maxed upgrades and owned skins drop out', () {
      final offers = ShopOverview.offersFor(everythingOwned());
      expect(offers, isEmpty);
      final overview = ShopOverview.of(everythingOwned());
      expect(overview.affordableCount, 0);
      expect(overview.nextGoal, isNull);
    });

    test('with everything affordable there is no goal left to save for', () {
      final overview = ShopOverview.of(withCoins(1000000));
      expect(overview.nextGoal, isNull);
      expect(
        overview.affordableCount,
        ShopOverview.offersFor(withCoins(1000000)).length,
      );
    });
  });
}
