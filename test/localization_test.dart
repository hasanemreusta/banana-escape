import 'package:banana_escape/l10n/strings.dart';
import 'package:banana_escape/models/mission.dart';
import 'package:banana_escape/models/skin.dart';
import 'package:banana_escape/ui/format.dart';
import 'package:banana_escape/models/upgrade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => S.debugOverride = null);

  test('defaults to English on a non-Turkish device', () {
    expect(S.current.play, 'PLAY');
  });

  test('model text follows the active language', () {
    S.debugOverride = S.turkish;
    expect(BananaSkins.defaultSkin.name, 'Klasik Kabuk');
    expect(Upgrades.magnet.title, 'Uzun Mıknatıs');
    expect(Missions.all.first.title, 'Muz Bankacısı');
    expect(SkinRarity.legendary.label, 'Efsanevi');

    S.debugOverride = S.english;
    expect(BananaSkins.defaultSkin.name, 'Classic Peel');
    expect(Upgrades.magnet.title, 'Longer Magnet');
    expect(SkinRarity.legendary.label, 'Legendary');
  });

  test('every skin, upgrade and mission has its own translation', () {
    for (final lang in [S.english, S.turkish]) {
      S.debugOverride = lang;
      final skinNames = BananaSkins.all.map((skin) => skin.name).toSet();
      expect(skinNames.length, BananaSkins.all.length);
      final upgradeTitles = Upgrades.all.map((u) => u.title).toSet();
      expect(upgradeTitles.length, Upgrades.all.length);
      final missionTitles = Missions.all.map((m) => m.title).toSet();
      expect(missionTitles.length, Missions.all.length);
    }
  });

  test('Turkish upper-casing keeps the dotted and dotless I apart', () {
    expect(S.turkish.upper('Efsanevi'), 'EFSANEVİ');
    expect(S.turkish.upper('Yaygın'), 'YAYGIN');
    expect(S.english.upper('Epic'), 'EPIC');
  });

  test('coin amounts group thousands the local way', () {
    S.debugOverride = S.turkish;
    expect(formatCoins(12500), '12.500');
    S.debugOverride = S.english;
    expect(formatCoins(12500), '12,500');
  });

  test('upgrade values use the language\'s seconds suffix', () {
    S.debugOverride = S.turkish;
    expect(Upgrades.magnet.formatValue(5.5), '5.5sn');
    S.debugOverride = S.english;
    expect(Upgrades.magnet.formatValue(5.5), '5.5s');
  });
}
