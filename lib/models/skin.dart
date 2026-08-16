import 'package:flutter/material.dart';

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
    required this.badge,
  });

  final String id;
  final String name;
  final int cost;
  final bool isDefault;
  final Color primaryColor;
  final Color secondaryColor;
  final Color stemColor;
  final Color auraColor;
  final String badge;

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
    badge: 'Default',
  );

  static const BananaSkin mintChip = BananaSkin(
    id: 'mint_chip',
    name: 'Mint Chip',
    cost: 250,
    isDefault: false,
    primaryColor: Color(0xFFB8F1A5),
    secondaryColor: Color(0xFF72C46C),
    stemColor: Color(0xFF2E8C57),
    auraColor: Color(0x665AD7B1),
    badge: 'Fresh',
  );

  static const BananaSkin berryPop = BananaSkin(
    id: 'berry_pop',
    name: 'Berry Pop',
    cost: 500,
    isDefault: false,
    primaryColor: Color(0xFFFF8AC6),
    secondaryColor: Color(0xFFE85D92),
    stemColor: Color(0xFF6BBD5B),
    auraColor: Color(0x66FF8AC6),
    badge: 'Sweet',
  );

  static const BananaSkin galaxyPeel = BananaSkin(
    id: 'galaxy_peel',
    name: 'Galaxy Peel',
    cost: 900,
    isDefault: false,
    primaryColor: Color(0xFF8EA4FF),
    secondaryColor: Color(0xFF5763E0),
    stemColor: Color(0xFF83D6B1),
    auraColor: Color(0x667A83FF),
    badge: 'Rare',
  );

  static const List<BananaSkin> all = [
    defaultSkin,
    mintChip,
    berryPop,
    galaxyPeel,
  ];

  static BananaSkin byId(String id) {
    return all.firstWhere(
      (skin) => skin.id == id,
      orElse: () => defaultSkin,
    );
  }
}
