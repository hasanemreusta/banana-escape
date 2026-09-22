import 'package:banana_escape/models/skin.dart';
import 'package:banana_escape/models/upgrade.dart';
import 'package:banana_escape/services/app_services.dart';
import 'package:banana_escape/ui/format.dart';
import 'package:flutter/services.dart';

class PurchaseOutcome {
  const PurchaseOutcome(this.message, {this.bought = false});

  final String message;

  /// True only when coins actually changed hands.
  final bool bought;
}

/// Purchase flows shared by the shop screen and the menu's quick-buy. Each
/// one saves the profile when it changes and reports what happened, so every
/// entry point tells the player the same thing.
class ShopActions {
  const ShopActions(this.services);

  final AppServices services;

  Future<PurchaseOutcome> buyShield() async {
    await services.audio.playButton();
    final current = services.profile;
    if (current.shieldCount >= Shop.maxShields) {
      return const PurchaseOutcome(
        'Shield rack is full — ${Shop.maxShields} at most.',
      );
    }
    if (!current.canBuyShield) {
      return _short(Shop.shieldCost - current.totalCoins);
    }
    await services.saveProfile(current.buyShield());
    return _bought('Shield added. Double-tap during a run to raise it.');
  }

  Future<PurchaseOutcome> buyUpgrade(UpgradeDefinition upgrade) async {
    await services.audio.playButton();
    final current = services.profile;
    final level = current.upgradeLevel(upgrade);
    final cost = upgrade.costToUpgradeFrom(level);
    if (cost == null) {
      return PurchaseOutcome('${upgrade.title} is already maxed.');
    }
    if (!current.canBuyUpgrade(upgrade)) {
      return _short(cost - current.totalCoins);
    }
    await services.saveProfile(current.buyUpgrade(upgrade));
    return _bought('${upgrade.title} is now level ${level + 1}!');
  }

  Future<PurchaseOutcome> equipSkin(BananaSkin skin) async {
    await services.audio.playButton();
    final current = services.profile;
    if (!skin.isOwned(current.ownedSkinIds)) {
      return PurchaseOutcome('${skin.name} is still locked.');
    }
    await services.saveProfile(current.equipSkin(skin.id));
    return PurchaseOutcome('${skin.name} equipped.');
  }

  /// Unlocks and equips [skin].
  Future<PurchaseOutcome> buySkin(BananaSkin skin) async {
    await services.audio.playButton();
    final current = services.profile;
    if (skin.isOwned(current.ownedSkinIds)) {
      return PurchaseOutcome('You already own ${skin.name}.');
    }
    if (!current.canUnlockSkin(skin)) {
      return _short(skin.cost - current.totalCoins);
    }
    await services.saveProfile(current.unlockSkin(skin));
    return _bought('${skin.name} unlocked!');
  }

  PurchaseOutcome _short(int missing) =>
      PurchaseOutcome('Need ${formatCoins(missing)} more coins.');

  PurchaseOutcome _bought(String message) {
    HapticFeedback.mediumImpact();
    return PurchaseOutcome(message, bought: true);
  }
}
