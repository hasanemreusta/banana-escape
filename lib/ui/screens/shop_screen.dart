import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/models/game_profile.dart';
import 'package:banana_escape/models/shop_overview.dart';
import 'package:banana_escape/models/skin.dart';
import 'package:banana_escape/models/upgrade.dart';
import 'package:banana_escape/services/app_services.dart';
import 'package:banana_escape/ui/format.dart';
import 'package:banana_escape/ui/shop_actions.dart';
import 'package:banana_escape/ui/widgets/banana_preview.dart';
import 'package:banana_escape/ui/widgets/banana_stage.dart';
import 'package:banana_escape/ui/widgets/coin_balance_pill.dart';
import 'package:banana_escape/ui/widgets/shop_item_card.dart';
import 'package:flutter/material.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.services,
    this.initialTab = ShopTab.upgrades,
  });

  final AppServices services;
  final ShopTab initialTab;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  GameProfile get profile => widget.services.profile;
  ShopActions get _actions => ShopActions(widget.services);

  /// The skin shown on the stage. Starts on the equipped one; tapping a tile
  /// previews it without buying or equipping anything.
  late BananaSkin _selected = BananaSkins.byId(profile.equippedSkinId);

  Future<void> _purchase({
    required int cost,
    required String itemName,
    required Future<PurchaseOutcome> Function() action,
    BananaSkin? skin,
  }) async {
    if (cost >= Shop.confirmThreshold && profile.totalCoins >= cost) {
      final confirmed = await _confirm(itemName, cost);
      if (!confirmed || !mounted) {
        return;
      }
    }
    final outcome = await action();
    if (!mounted) {
      return;
    }
    setState(() {});
    if (outcome.bought && skin != null) {
      await _celebrate(skin);
      return;
    }
    _toast(outcome.message);
  }

  Future<void> _equip(BananaSkin skin) async {
    final outcome = await _actions.equipSkin(skin);
    if (!mounted) {
      return;
    }
    setState(() {});
    _toast(outcome.message);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<bool> _confirm(String itemName, int cost) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Buy $itemName?',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'This spends ${formatCoins(cost)} of your '
          '${formatCoins(profile.totalCoins)} coins.',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
            child: const Text(
              'Buy it',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  Future<void> _celebrate(BananaSkin skin) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NEW SKIN!',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  color: skin.rarity.color,
                ),
              ),
              const SizedBox(height: 8),
              BananaStage(skin: skin, size: 140),
              const SizedBox(height: 12),
              Text(
                skin.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              RarityChip(rarity: skin.rarity),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Equipped — let\'s run!',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: ShopTab.values.length,
      initialIndex: widget.initialTab.index,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF85DBFF),
                Color(0xFFFFF4C7),
                Color(0xFFFFD98B),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Shop',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      CoinBalancePill(coins: profile.totalCoins),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.ink,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.bolt_rounded, size: 20),
                        text: 'Upgrades',
                        iconMargin: EdgeInsets.zero,
                      ),
                      Tab(
                        icon: Icon(Icons.checkroom_rounded, size: 20),
                        text: 'Skins',
                        iconMargin: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _upgradesTab(),
                      _skinsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _upgradesTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const _SectionLabel(
          title: 'POWER-UPS',
          subtitle: 'Permanent. Every run, forever.',
        ),
        for (final upgrade in Upgrades.all) ...[
          _upgradeCard(upgrade),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        const _SectionLabel(
          title: 'ITEMS',
          subtitle: 'Spent one crash at a time.',
        ),
        ShopItemCard(
          icon: Icons.shield_rounded,
          title: 'Peel Shield',
          description: 'Absorbs one crash per run. Used automatically.',
          detail: '${profile.shieldCount}/${Shop.maxShields} held',
          filled: profile.shieldCount,
          total: Shop.maxShields,
          price: profile.shieldCount < Shop.maxShields ? Shop.shieldCost : null,
          affordable: profile.canBuyShield,
          maxedLabel: 'Full',
          onPressed: () => _purchase(
            cost: Shop.shieldCost,
            itemName: 'a Peel Shield',
            action: _actions.buyShield,
          ),
        ),
      ],
    );
  }

  Widget _upgradeCard(UpgradeDefinition upgrade) {
    final level = profile.upgradeLevel(upgrade);
    final cost = upgrade.costToUpgradeFrom(level);
    final now = upgrade.formatValue(upgrade.valueAt(level));
    return ShopItemCard(
      icon: upgrade.icon,
      title: upgrade.title,
      description: upgrade.description,
      detail: cost == null
          ? now
          : '$now → ${upgrade.formatValue(upgrade.valueAt(level + 1))}',
      filled: level,
      total: UpgradeDefinition.maxLevel,
      price: cost,
      affordable: profile.canBuyUpgrade(upgrade),
      onPressed: () => _purchase(
        cost: cost ?? 0,
        itemName: '${upgrade.title} level ${level + 1}',
        action: () => _actions.buyUpgrade(upgrade),
      ),
    );
  }

  Widget _skinsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _SkinSpotlight(
          skin: _selected,
          profile: profile,
          onEquip: () => _equip(_selected),
          onBuy: () => _purchase(
            cost: _selected.cost,
            itemName: _selected.name,
            action: () => _actions.buySkin(_selected),
            skin: _selected,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
          children: [
            for (final skin in BananaSkins.all)
              _SkinTile(
                skin: skin,
                owned: skin.isOwned(profile.ownedSkinIds),
                equipped: skin.id == profile.equippedSkinId,
                selected: skin.id == _selected.id,
                onTap: () => setState(() => _selected = skin),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.softInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RarityChip extends StatelessWidget {
  const RarityChip({super.key, required this.rarity});

  final SkinRarity rarity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: rarity.color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        rarity.label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// The big preview at the top of the Skins tab, with the one action that
/// makes sense for the selected skin.
class _SkinSpotlight extends StatelessWidget {
  const _SkinSpotlight({
    required this.skin,
    required this.profile,
    required this.onEquip,
    required this.onBuy,
  });

  final BananaSkin skin;
  final GameProfile profile;
  final VoidCallback onEquip;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final owned = skin.isOwned(profile.ownedSkinIds);
    final equipped = skin.id == profile.equippedSkinId;
    final affordable = profile.totalCoins >= skin.cost;
    final missing = skin.cost - profile.totalCoins;

    final Widget action;
    if (equipped) {
      action = _SpotlightButton(
        label: 'Equipped',
        icon: Icons.check_rounded,
        color: AppColors.leafDeep,
        onPressed: null,
      );
    } else if (owned) {
      action = _SpotlightButton(
        label: 'Equip',
        icon: Icons.checkroom_rounded,
        color: AppColors.ink,
        onPressed: onEquip,
      );
    } else if (affordable) {
      action = _SpotlightButton(
        label: 'Unlock · ${formatCoins(skin.cost)}',
        icon: Icons.monetization_on_rounded,
        color: AppColors.orange,
        onPressed: onBuy,
      );
    } else {
      action = Column(
        children: [
          _SpotlightButton(
            label: formatCoins(skin.cost),
            icon: Icons.lock_rounded,
            color: const Color(0xFFB9B2BE),
            onPressed: onBuy,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (profile.totalCoins / skin.cost).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              valueColor: AlwaysStoppedAnimation<Color>(skin.rarity.color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatCoins(missing)} more coins to unlock',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.softInk,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.92),
            skin.auraColor.withValues(alpha: 0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: skin.rarity.color.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: RarityChip(rarity: skin.rarity),
          ),
          BananaStage(skin: skin, size: 130),
          const SizedBox(height: 10),
          Text(
            skin.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          action,
        ],
      ),
    );
  }
}

class _SpotlightButton extends StatelessWidget {
  const _SpotlightButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _SkinTile extends StatelessWidget {
  const _SkinTile({
    required this.skin,
    required this.owned,
    required this.equipped,
    required this.selected,
    required this.onTap,
  });

  final BananaSkin skin;
  final bool owned;
  final bool equipped;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, skin.auraColor.withValues(alpha: 0.45)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? skin.rarity.color : Colors.white,
            width: selected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.12 : 0.05),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: skin.rarity.color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Center(child: BananaPreview(skin: skin, showAura: false)),
                  if (equipped)
                    const Positioned(
                      top: 2,
                      right: 2,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.leafDeep,
                        child: Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              skin.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            if (owned)
              Text(
                equipped ? 'Equipped' : 'Owned',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.leafDeep,
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 12,
                    color: AppColors.softInk,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    formatCoins(skin.cost),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.softInk,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
