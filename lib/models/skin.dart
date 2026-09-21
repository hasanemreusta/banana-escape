import 'package:flutter/material.dart';

/// How hard a skin is to get. Drives its price band and the colour it is
/// framed in across the shop, so rarity reads before the price does.
enum SkinRarity {
  standard('Standard', Color(0xFF9A93A0)),
  common('Common', Color(0xFF4FB477)),
  rare('Rare', Color(0xFF3E8EDE)),
  epic('Epic', Color(0xFF9B59D6)),
  legendary('Legendary', Color(0xFFF2A100));

  const SkinRarity(this.label, this.color);

  final String label;
  final Color color;
}

class BananaSkin {
  const BananaSkin({
    required this.id,
    required this.name,
    required this.cost,
    required this.isDefault,
    required this.primaryColor,
    required this.secondaryColor,
    required this.stemColor,
    required this.auraColor,
    required this.rarity,
  });

  /// Storage key. Never rename one that has shipped — ownership is saved by it.
  final String id;
  final String name;
  final int cost;
  final bool isDefault;
  final Color primaryColor;
  final Color secondaryColor;
  final Color stemColor;
  final Color auraColor;
  final SkinRarity rarity;

  bool isOwned(List<String> ownedIds) => isDefault || ownedIds.contains(id);
}

class BananaSkins {
  const BananaSkins._();

  static const String defaultId = 'classic';

  static const BananaSkin defaultSkin = BananaSkin(
    id: defaultId,
    name: 'Classic Peel',
    cost: 0,
    isDefault: true,
    primaryColor: Color(0xFFFFD447),
    secondaryColor: Color(0xFFE0AE17),
    stemColor: Color(0xFF5BBE58),
    auraColor: Color(0x66FFD447),
    rarity: SkinRarity.standard,
  );

  static const BananaSkin mintChip = BananaSkin(
    id: 'mint_chip',
    name: 'Mint Chip',
    cost: 1500,
    isDefault: false,
    primaryColor: Color(0xFFB8F1A5),
    secondaryColor: Color(0xFF72C46C),
    stemColor: Color(0xFF2E8C57),
    auraColor: Color(0x665AD7B1),
    rarity: SkinRarity.common,
  );

  static const BananaSkin berryPop = BananaSkin(
    id: 'berry_pop',
    name: 'Berry Pop',
    cost: 3000,
    isDefault: false,
    primaryColor: Color(0xFFFF8AC6),
    secondaryColor: Color(0xFFE85D92),
    stemColor: Color(0xFF6BBD5B),
    auraColor: Color(0x66FF8AC6),
    rarity: SkinRarity.common,
  );

  static const BananaSkin chocoDip = BananaSkin(
    id: 'choco_dip',
    name: 'Choco Dip',
    cost: 6000,
    isDefault: false,
    primaryColor: Color(0xFFB27A4E),
    secondaryColor: Color(0xFF7A4A2A),
    stemColor: Color(0xFF4E8C3A),
    auraColor: Color(0x66C08A5C),
    rarity: SkinRarity.rare,
  );

  static const BananaSkin galaxyPeel = BananaSkin(
    id: 'galaxy_peel',
    name: 'Galaxy Peel',
    cost: 12000,
    isDefault: false,
    primaryColor: Color(0xFF8EA4FF),
    secondaryColor: Color(0xFF5763E0),
    stemColor: Color(0xFF83D6B1),
    auraColor: Color(0x667A83FF),
    rarity: SkinRarity.rare,
  );

  static const BananaSkin lavaPeel = BananaSkin(
    id: 'lava_peel',
    name: 'Lava Peel',
    cost: 20000,
    isDefault: false,
    primaryColor: Color(0xFFFF7A45),
    secondaryColor: Color(0xFFD9381E),
    stemColor: Color(0xFF3A3A3A),
    auraColor: Color(0x66FF5A2E),
    rarity: SkinRarity.epic,
  );

  static const BananaSkin frostBite = BananaSkin(
    id: 'frost_bite',
    name: 'Frost Bite',
    cost: 28000,
    isDefault: false,
    primaryColor: Color(0xFFD6F4FF),
    secondaryColor: Color(0xFF8CCBEA),
    stemColor: Color(0xFF5FA8C9),
    auraColor: Color(0x669FE3FF),
    rarity: SkinRarity.epic,
  );

  static const BananaSkin goldenBanana = BananaSkin(
    id: 'golden_banana',
    name: 'Golden Banana',
    cost: 50000,
    isDefault: false,
    primaryColor: Color(0xFFFFD86B),
    secondaryColor: Color(0xFFC99A1E),
    stemColor: Color(0xFFB8860B),
    auraColor: Color(0x88FFE27A),
    rarity: SkinRarity.legendary,
  );

  /// Shop order: cheapest first, so the grid reads as a ladder to climb.
  static const List<BananaSkin> all = [
    defaultSkin,
    mintChip,
    berryPop,
    chocoDip,
    galaxyPeel,
    lavaPeel,
    frostBite,
    goldenBanana,
  ];

  static BananaSkin byId(String id) {
    return all.firstWhere(
      (skin) => skin.id == id,
      orElse: () => defaultSkin,
    );
  }
}
