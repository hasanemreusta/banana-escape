import 'package:banana_escape/l10n/strings.dart';
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
      return PurchaseOutcome(
        S.current.shieldRackFull(Shop.maxShields),
      );
    }
    if (!current.canBuyShield) {
      return _short(Shop.shieldCost - current.totalCoins);
    }
    await services.saveProfile(current.buyShield());
    return _bought(S.current.shieldAdded);
  }

  Future<PurchaseOutcome> buyUpgrade(UpgradeDefinition upgrade) async {
    await services.audio.playButton();
    final current = services.profile;
    final level = current.upgradeLevel(upgrade);
    final cost = upgrade.costToUpgradeFrom(level);
    if (cost == null) {
      return PurchaseOutcome(S.current.upgradeMaxed(upgrade.title));
    }
    if (!current.canBuyUpgrade(upgrade)) {
      return _short(cost - current.totalCoins);
    }
    await services.saveProfile(current.buyUpgrade(upgrade));
    return _bought(S.current.upgradeNowLevel(upgrade.title, level + 1));
  }

  Future<PurchaseOutcome> equipSkin(BananaSkin skin) async {
    await services.audio.playButton();
    final current = services.profile;
    if (!skin.isOwned(current.ownedSkinIds)) {
      return PurchaseOutcome(S.current.skinLocked(skin.name));
    }
    await services.saveProfile(current.equipSkin(skin.id));
    return PurchaseOutcome(S.current.skinEquipped(skin.name));
  }

  /// Unlocks and equips [skin].
  Future<PurchaseOutcome> buySkin(BananaSkin skin) async {
    await services.audio.playButton();
    final current = services.profile;
    if (skin.isOwned(current.ownedSkinIds)) {
      return PurchaseOutcome(S.current.skinAlreadyOwned(skin.name));
    }
    if (!current.canUnlockSkin(skin)) {
      return _short(skin.cost - current.totalCoins);
    }
    await services.saveProfile(current.unlockSkin(skin));
    return _bought(S.current.skinUnlocked(skin.name));
  }

  PurchaseOutcome _short(int missing) =>
      PurchaseOutcome(S.current.needMoreCoins(formatCoins(missing)));

  PurchaseOutcome _bought(String message) {
    HapticFeedback.mediumImpact();
    return PurchaseOutcome(message, bought: true);
  }
}
