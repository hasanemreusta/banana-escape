import 'dart:convert';

import 'package:banana_escape/config/game_config.dart';
import 'package:banana_escape/models/game_profile.dart';
import 'package:banana_escape/models/upgrade.dart';
import 'package:banana_escape/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameProfile withCoins(int coins) =>
    GameProfile.initial().copyWith(totalCoins: coins);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('upgrade definitions', () {
    test('level 0 matches the untouched game config', () {
      expect(Upgrades.magnet.valueAt(0), GameConfig.magnetDuration);
      expect(Upgrades.comboWindow.valueAt(0), GameConfig.comboWindow);
      expect(Upgrades.comboBanana.valueAt(0), GameConfig.comboCoinValue);
    });

    test('every level has a price and the last one has none', () {
      for (final upgrade in Upgrades.all) {
        for (var level = 0; level < UpgradeDefinition.maxLevel; level++) {
          expect(upgrade.costToUpgradeFrom(level), isNotNull);
        }
        expect(upgrade.costToUpgradeFrom(UpgradeDefinition.maxLevel), isNull);
      }
    });

    test('each step costs more than the one before', () {
      const costs = UpgradeDefinition.levelCosts;
      expect(costs, hasLength(UpgradeDefinition.maxLevel));
      for (var index = 1; index < costs.length; index++) {
        expect(costs[index], greaterThan(costs[index - 1]));
      }
    });

    test('values stop growing past the max level', () {
      expect(
        Upgrades.magnet.valueAt(UpgradeDefinition.maxLevel + 3),
        Upgrades.magnet.valueAt(UpgradeDefinition.maxLevel),
      );
    });

    test('storage ids are unique', () {
      final ids = Upgrades.all.map((upgrade) => upgrade.id).toSet();
      expect(ids, hasLength(Upgrades.all.length));
    });
  });

  group('buying upgrades', () {
    test('a purchase spends the coins and raises the level by one', () {
      final bought = withCoins(1000).buyUpgrade(Upgrades.magnet);
      expect(bought.upgradeLevel(Upgrades.magnet), 1);
      expect(bought.totalCoins, 1000 - UpgradeDefinition.levelCosts[0]);
    });

    test('upgrades are not sold on credit', () {
      final profile = withCoins(UpgradeDefinition.levelCosts[0] - 1);
      expect(profile.canBuyUpgrade(Upgrades.magnet), isFalse);
      expect(identical(profile.buyUpgrade(Upgrades.magnet), profile), isTrue);
    });

    test('a maxed upgrade cannot be bought again', () {
      var profile = withCoins(100000);
      for (var step = 0; step < UpgradeDefinition.maxLevel; step++) {
        profile = profile.buyUpgrade(Upgrades.comboWindow);
      }
      expect(
        profile.upgradeLevel(Upgrades.comboWindow),
        UpgradeDefinition.maxLevel,
      );
      final coinsAtMax = profile.totalCoins;
      expect(profile.canBuyUpgrade(Upgrades.comboWindow), isFalse);
      expect(
        profile.buyUpgrade(Upgrades.comboWindow).totalCoins,
        coinsAtMax,
      );
    });

    test('maxing a track costs exactly the sum of its steps', () {
      var profile = withCoins(100000);
      for (var step = 0; step < UpgradeDefinition.maxLevel; step++) {
        profile = profile.buyUpgrade(Upgrades.magnet);
      }
      final total = UpgradeDefinition.levelCosts.reduce((a, b) => a + b);
      expect(profile.totalCoins, 100000 - total);
    });

    test('buying one track leaves the others alone', () {
      final bought = withCoins(1000).buyUpgrade(Upgrades.comboBanana);
      expect(bought.upgradeLevel(Upgrades.magnet), 0);
      expect(bought.upgradeLevel(Upgrades.comboWindow), 0);
    });

    test('the purchase does not touch the profile it was called on', () {
      final profile = withCoins(1000);
      profile.buyUpgrade(Upgrades.magnet);
      expect(profile.upgradeLevel(Upgrades.magnet), 0);
      expect(profile.totalCoins, 1000);
    });
  });

  group('run loadout', () {
    test('a fresh profile runs with the base config and no shield', () {
      final loadout = GameProfile.initial().runLoadout;
      expect(loadout.magnetDuration, GameConfig.magnetDuration);
      expect(loadout.comboWindow, GameConfig.comboWindow);
      expect(loadout.comboCoinValue, GameConfig.comboCoinValue);
      expect(loadout.hasShield, isFalse);
    });

    test('bought levels and shields reach the run', () {
      final profile = withCoins(10000)
          .buyUpgrade(Upgrades.magnet)
          .buyUpgrade(Upgrades.magnet)
          .buyUpgrade(Upgrades.comboBanana)
          .buyShield();
      final loadout = profile.runLoadout;
      expect(loadout.magnetDuration, Upgrades.magnet.valueAt(2));
      expect(loadout.comboCoinValue, Upgrades.comboBanana.valueAt(1));
      expect(loadout.comboWindow, GameConfig.comboWindow);
      expect(loadout.hasShield, isTrue);
    });
  });

  group('shields', () {
    test('buying one spends the price and adds it to the stock', () {
      final bought = withCoins(Shop.shieldCost + 50).buyShield();
      expect(bought.shieldCount, 1);
      expect(bought.totalCoins, 50);
    });

    test('the stock is capped', () {
      var profile = withCoins(100000);
      for (var step = 0; step < Shop.maxShields + 3; step++) {
        profile = profile.buyShield();
      }
      expect(profile.shieldCount, Shop.maxShields);
      expect(profile.totalCoins, 100000 - Shop.shieldCost * Shop.maxShields);
      expect(profile.canBuyShield, isFalse);
    });

    test('shields are not sold on credit', () {
      final profile = withCoins(Shop.shieldCost - 1);
      expect(profile.canBuyShield, isFalse);
      expect(profile.buyShield().shieldCount, 0);
    });

    test('consuming takes one and never goes below zero', () {
      final profile = withCoins(Shop.shieldCost * 2).buyShield().buyShield();
      expect(profile.consumeShield().shieldCount, 1);
      expect(GameProfile.initial().consumeShield().shieldCount, 0);
    });
  });

  group('revive', () {
    test('each continue in a run doubles the price', () {
      expect(Shop.reviveCost(0), Shop.reviveBaseCost);
      expect(Shop.reviveCost(1), Shop.reviveBaseCost * 2);
      expect(Shop.reviveCost(2), Shop.reviveBaseCost * 4);
    });

    test('a silly use count cannot overflow the price', () {
      expect(Shop.reviveCost(500), greaterThan(0));
      expect(Shop.reviveCost(-3), Shop.reviveBaseCost);
    });

    test('spending takes exactly the amount from the bank', () {
      expect(withCoins(400).spendCoins(150).totalCoins, 250);
    });

    test('spending more than the bank holds changes nothing', () {
      final profile = withCoins(100);
      expect(identical(profile.spendCoins(150), profile), isTrue);
      expect(identical(profile.spendCoins(-5), profile), isTrue);
    });
  });

  group('shop storage', () {
    test('a save from before the shop existed loads with nothing bought', () {
      final profile = GameProfile.fromPrefs({
        'highScore': 900,
        'totalCoins': 1200,
      });
      for (final upgrade in Upgrades.all) {
        expect(profile.upgradeLevel(upgrade), 0);
      }
      expect(profile.shieldCount, 0);
      expect(profile.totalCoins, 1200);
    });

    test('a corrupt upgrade blob falls back instead of bricking the launch',
        () {
      final profile = GameProfile.fromPrefs({'upgradeLevels': '{"magnet'});
      expect(profile.upgradeLevels, GameProfile.initial().upgradeLevels);
    });

    test('an upgrade blob of the wrong shape falls back too', () {
      final profile = GameProfile.fromPrefs({'upgradeLevels': '[1, 2, 3]'});
      expect(profile.upgradeLevels, GameProfile.initial().upgradeLevels);
    });

    test('out-of-range stored levels and shield counts are clamped', () {
      final profile = GameProfile.fromPrefs({
        'upgradeLevels': jsonEncode({
          Upgrades.magnet.id: 99,
          Upgrades.comboWindow.id: -4,
        }),
        'shieldCount': 40,
      });
      expect(profile.upgradeLevel(Upgrades.magnet), UpgradeDefinition.maxLevel);
      expect(profile.upgradeLevel(Upgrades.comboWindow), 0);
      expect(profile.shieldCount, Shop.maxShields);
    });

    test('an upgrade that no longer exists is dropped', () {
      final profile = GameProfile.fromPrefs({
        'upgradeLevels': jsonEncode({'retired_upgrade': 3}),
      });
      expect(profile.upgradeLevels.containsKey('retired_upgrade'), isFalse);
    });

    test('purchases survive StorageService', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService(await SharedPreferences.getInstance());
      final profile = withCoins(5000)
          .buyUpgrade(Upgrades.comboWindow)
          .buyUpgrade(Upgrades.comboWindow)
          .buyShield();
      await storage.saveProfile(profile);

      final loaded = await storage.loadProfile();
      expect(loaded.upgradeLevel(Upgrades.comboWindow), 2);
      expect(loaded.shieldCount, 1);
      expect(loaded.totalCoins, profile.totalCoins);
    });
  });
}
