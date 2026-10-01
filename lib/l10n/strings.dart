import 'dart:ui' as ui;

/// Every player-facing string, in the language of the device.
///
/// A plain class instead of ARB files: the game has about a hundred strings,
/// two languages, and a lot of them are read from places without a
/// BuildContext (the Flame game, the models). An abstract class also makes the
/// compiler reject a translation that forgets a string.
abstract class S {
  const S();

  static const S _en = _EnglishStrings();
  static const S _tr = _TurkishStrings();

  /// Set by tests to pin a language; null means follow the device.
  static S? debugOverride;

  static S get english => _en;
  static S get turkish => _tr;

  static S get current {
    final override = debugOverride;
    if (override != null) {
      return override;
    }
    return ui.PlatformDispatcher.instance.locale.languageCode == 'tr'
        ? _tr
        : _en;
  }

  /// 12500 reads "12,500" in English and "12.500" in Turkish.
  String get thousandsSeparator;

  /// Upper-cases [text] the way the language does. Dart's own toUpperCase is
  /// not locale-aware, so Turkish "efsanevi" would come out with a dotless I.
  String upper(String text) => text.toUpperCase();

  // Menu and splash
  String get menuTagline;
  String get menuSubtitle;
  String get onboarding;
  String get splashTagline;
  String get play;
  String get shop;
  String get skins;
  String get missions;
  String get daily;

  // In-game
  String get dangerBanner;
  String get retryCta;
  String get hudScore;
  String get hudMeters;
  String get hudCoins;
  String get hudStage;
  String get hudCombo;
  String get hudShield;
  String get hudDoubleTap;
  String get hudMagnet;
  String get secondsUnit;
  String shieldStock(int count);
  String get statusShieldFaded;
  String get statusDoubleTapHint;
  String statusStageRush(int stage);
  String statusCloseOne(int bonus);
  String statusCombo(int multiplier);
  String get statusComboBanana;
  String get statusMagnet;
  String get statusShieldUp;
  String get statusShieldSaved;
  String get statusRevived;

  // Pause, continue and run summary
  String get pausedTitle;
  String get pausedSubtitle;
  String get resume;
  String get restart;
  String get mainMenu;
  String get continueTitle;
  String get continueSubtitle;
  String get yourCoins;
  String get thisRun;
  String runEndsIn(int seconds);
  String continueFor(String cost);
  String get noThanks;
  String get blendedTitle;
  String get blendedSubtitle;
  String get newBest;
  String get runScore;
  String get best;
  String get distance;
  String get missionProgress;
  String get retry;

  // Menu sheets
  String get dailyBunch;
  String get dailyBunchSubtitle;
  String dailyCollected(String coins);
  String get missionsSubtitle;
  String get dailyAlreadyClaimed;
  String get dailyCollectedTomorrow;
  String dailyDayReward(int day, int reward);
  String dailyClaim(int reward);
  String get missionDone;
  String shieldsHeld(int count);
  String get noShields;

  // Shop
  String get shopTitle;
  String get tabUpgrades;
  String get tabSkins;
  String get powerUps;
  String get powerUpsSubtitle;
  String get items;
  String get itemsSubtitle;
  String get shieldTitle;
  String get shieldDescription;
  String shieldHeld(int count, int max);
  String get full;
  String get maxed;
  String confirmBuy(String item);
  String confirmSpend(String cost, String balance);
  String get notYet;
  String get buyIt;
  String get newSkin;
  String get equippedRun;
  String get equipped;
  String get equip;
  String get owned;
  String unlockFor(String cost);
  String coinsToUnlock(String missing);
  String get itemShield;
  String upgradeLevelName(String title, int level);
  String upgradeShortLevel(String title, int level);

  // Shop nudge
  String get oneItemReady;
  String itemsReady(int count);
  String get nudgeDetail;
  String savingFor(String goal);
  String coinsToGo(String coins);

  // Purchase outcomes
  String shieldRackFull(int max);
  String get shieldAdded;
  String upgradeMaxed(String title);
  String upgradeNowLevel(String title, int level);
  String skinLocked(String name);
  String skinEquipped(String name);
  String skinAlreadyOwned(String name);
  String skinUnlocked(String name);
  String needMoreCoins(String missing);

  // Content, keyed by the ids that are saved to disk
  String rarityLabel(String rarityName);
  String skinName(String id);
  String upgradeTitle(String id);
  String upgradeDescription(String id);
  String missionTitle(String id);
  String missionDescription(String id);
}

class _EnglishStrings extends S {
  const _EnglishStrings();

  @override
  String get thousandsSeparator => ',';

  @override
  String get menuTagline => 'Run, Banana, Run!';
  @override
  String get menuSubtitle => 'Too ripe to quit!';
  @override
  String get onboarding =>
      'Swipe to dodge  •  Collect bananas  •  Don\'t get blended';
  @override
  String get splashTagline => 'Peel out before the blender catches up.';
  @override
  String get play => 'PLAY';
  @override
  String get shop => 'Shop';
  @override
  String get skins => 'Skins';
  @override
  String get missions => 'Missions';
  @override
  String get daily => 'Daily';

  @override
  String get dangerBanner => 'Blender is coming!';
  @override
  String get retryCta => 'One more run?';
  @override
  String get hudScore => 'Score';
  @override
  String get hudMeters => 'Meters';
  @override
  String get hudCoins => 'Coins';
  @override
  String get hudStage => 'Stage';
  @override
  String get hudCombo => 'Combo';
  @override
  String get hudShield => 'Shield';
  @override
  String get hudDoubleTap => 'Double-tap';
  @override
  String get hudMagnet => 'Magnet';
  @override
  String get secondsUnit => 's';
  @override
  String shieldStock(int count) => 'Shield ×$count';
  @override
  String get statusShieldFaded => 'Shield faded';
  @override
  String get statusDoubleTapHint => 'Double-tap to raise a shield';
  @override
  String statusStageRush(int stage) => 'Stage $stage Rush!';
  @override
  String statusCloseOne(int bonus) => 'Close one! +$bonus';
  @override
  String statusCombo(int multiplier) => 'Combo x$multiplier!';
  @override
  String get statusComboBanana => 'Combo Banana!';
  @override
  String get statusMagnet => 'Magnet mode!';
  @override
  String get statusShieldUp => 'Shield up!';
  @override
  String get statusShieldSaved => 'Shield saved you!';
  @override
  String get statusRevived => 'Back in the race!';

  @override
  String get pausedTitle => 'Paused';
  @override
  String get pausedSubtitle =>
      'Catch your breath. The blender is still lurking.';
  @override
  String get resume => 'Continue';
  @override
  String get restart => 'Restart';
  @override
  String get mainMenu => 'Main Menu';
  @override
  String get continueTitle => 'So close!';
  @override
  String get continueSubtitle =>
      'Spend coins to shake off the blender and keep this run going.';
  @override
  String get yourCoins => 'Your coins';
  @override
  String get thisRun => 'This run';
  @override
  String runEndsIn(int seconds) => 'Run ends in ${seconds}s';
  @override
  String continueFor(String cost) => 'Continue for $cost coins';
  @override
  String get noThanks => 'No thanks';
  @override
  String get blendedTitle => 'Blended!';
  @override
  String get blendedSubtitle =>
      'Too ripe to quit. Hit retry and beat that run.';
  @override
  String get newBest => 'New Best!';
  @override
  String get runScore => 'Run Score';
  @override
  String get best => 'Best';
  @override
  String get distance => 'Distance';
  @override
  String get missionProgress => 'Mission Progress';
  @override
  String get retry => 'Retry';

  @override
  String get dailyBunch => 'Daily Bunch';
  @override
  String get dailyBunchSubtitle =>
      'Come back every day — the reward grows with your streak.';
  @override
  String dailyCollected(String coins) => 'Daily bunch collected: +$coins coins';
  @override
  String get missionsSubtitle =>
      'Short goals that add a bit of "one more run".';
  @override
  String get dailyAlreadyClaimed => 'Already claimed today';
  @override
  String get dailyCollectedTomorrow => 'Collected. Come back tomorrow.';
  @override
  String dailyDayReward(int day, int reward) =>
      'Day $day reward: $reward coins';
  @override
  String dailyClaim(int reward) => 'Claim $reward coins';
  @override
  String get missionDone => 'Done';
  @override
  String shieldsHeld(int count) => 'Shields ×$count · double-tap in a run';
  @override
  String get noShields => 'No shields — grab one for tough runs';

  @override
  String get shopTitle => 'Shop';
  @override
  String get tabUpgrades => 'Upgrades';
  @override
  String get tabSkins => 'Skins';
  @override
  String get powerUps => 'POWER-UPS';
  @override
  String get powerUpsSubtitle => 'Permanent. Every run, forever.';
  @override
  String get items => 'ITEMS';
  @override
  String get itemsSubtitle => 'Yours to raise when it counts.';
  @override
  String get shieldTitle => 'Peel Shield';
  @override
  String get shieldDescription =>
      'Double-tap in a run to raise it for 5s. Absorbs one crash.';
  @override
  String shieldHeld(int count, int max) => '$count/$max held';
  @override
  String get full => 'Full';
  @override
  String get maxed => 'Maxed';
  @override
  String confirmBuy(String item) => 'Buy $item?';
  @override
  String confirmSpend(String cost, String balance) =>
      'This spends $cost of your $balance coins.';
  @override
  String get notYet => 'Not yet';
  @override
  String get buyIt => 'Buy it';
  @override
  String get newSkin => 'NEW SKIN!';
  @override
  String get equippedRun => 'Equipped — let\'s run!';
  @override
  String get equipped => 'Equipped';
  @override
  String get equip => 'Equip';
  @override
  String get owned => 'Owned';
  @override
  String unlockFor(String cost) => 'Unlock · $cost';
  @override
  String coinsToUnlock(String missing) => '$missing more coins to unlock';
  @override
  String get itemShield => 'a Peel Shield';
  @override
  String upgradeLevelName(String title, int level) => '$title level $level';
  @override
  String upgradeShortLevel(String title, int level) => '$title Lv $level';

  @override
  String get oneItemReady => '1 item ready to buy';
  @override
  String itemsReady(int count) => '$count items ready to buy';
  @override
  String get nudgeDetail => 'Your coins are burning a hole in your peel.';
  @override
  String savingFor(String goal) => 'Saving for $goal';
  @override
  String coinsToGo(String coins) => '$coins coins to go';

  @override
  String shieldRackFull(int max) => 'Shield rack is full — $max at most.';
  @override
  String get shieldAdded =>
      'Shield added. Double-tap during a run to raise it.';
  @override
  String upgradeMaxed(String title) => '$title is already maxed.';
  @override
  String upgradeNowLevel(String title, int level) =>
      '$title is now level $level!';
  @override
  String skinLocked(String name) => '$name is still locked.';
  @override
  String skinEquipped(String name) => '$name equipped.';
  @override
  String skinAlreadyOwned(String name) => 'You already own $name.';
  @override
  String skinUnlocked(String name) => '$name unlocked!';
  @override
  String needMoreCoins(String missing) => 'Need $missing more coins.';

  @override
  String rarityLabel(String rarityName) => switch (rarityName) {
        'standard' => 'Standard',
        'common' => 'Common',
        'rare' => 'Rare',
        'epic' => 'Epic',
        _ => 'Legendary',
      };
  @override
  String skinName(String id) => switch (id) {
        'classic' => 'Classic Peel',
        'mint_chip' => 'Mint Chip',
        'berry_pop' => 'Berry Pop',
        'choco_dip' => 'Choco Dip',
        'galaxy_peel' => 'Galaxy Peel',
        'lava_peel' => 'Lava Peel',
        'frost_bite' => 'Frost Bite',
        _ => 'Golden Banana',
      };
  @override
  String upgradeTitle(String id) => switch (id) {
        'magnet_duration' => 'Longer Magnet',
        'combo_window' => 'Steady Combo',
        _ => 'Juicier Bananas',
      };
  @override
  String upgradeDescription(String id) => switch (id) {
        'magnet_duration' => 'Magnet pickups pull coins for longer.',
        'combo_window' => 'More time between pickups before a combo lapses.',
        _ => 'Coins paid out per combo banana.',
      };
  @override
  String missionTitle(String id) => switch (id) {
        'collect_20_in_run' => 'Banana Banker',
        'reach_500_distance' => 'Long Peel',
        _ => 'Warm Up',
      };
  @override
  String missionDescription(String id) => switch (id) {
        'collect_20_in_run' => 'Collect 20 coins in one run',
        'reach_500_distance' => 'Reach 500 meters',
        _ => 'Play 3 runs',
      };
}

class _TurkishStrings extends S {
  const _TurkishStrings();

  @override
  String get thousandsSeparator => '.';
  @override
  String upper(String text) =>
      text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

  @override
  String get menuTagline => 'Koş Muz, Koş!';
  @override
  String get menuSubtitle => 'Pes etmek için fazla olgunum!';
  @override
  String get onboarding =>
      'Kaydırarak kaç  •  Muz topla  •  Blendera yakalanma';
  @override
  String get splashTagline => 'Blender yetişmeden kabuk atıp kaç.';
  @override
  String get play => 'OYNA';
  @override
  String get shop => 'Mağaza';
  @override
  String get skins => 'Kostümler';
  @override
  String get missions => 'Görevler';
  @override
  String get daily => 'Günlük';

  @override
  String get dangerBanner => 'Blender geliyor!';
  @override
  String get retryCta => 'Bir tur daha?';
  @override
  String get hudScore => 'Skor';
  @override
  String get hudMeters => 'Metre';
  @override
  String get hudCoins => 'Altın';
  @override
  String get hudStage => 'Aşama';
  @override
  String get hudCombo => 'Kombo';
  @override
  String get hudShield => 'Kalkan';
  @override
  String get hudDoubleTap => 'Çift dokun';
  @override
  String get hudMagnet => 'Mıknatıs';
  @override
  String get secondsUnit => 'sn';
  @override
  String shieldStock(int count) => 'Kalkan ×$count';
  @override
  String get statusShieldFaded => 'Kalkan söndü';
  @override
  String get statusDoubleTapHint => 'Kalkan için çift dokun';
  @override
  String statusStageRush(int stage) => '$stage. Aşama Hücumu!';
  @override
  String statusCloseOne(int bonus) => 'Kıl payı! +$bonus';
  @override
  String statusCombo(int multiplier) => 'Kombo x$multiplier!';
  @override
  String get statusComboBanana => 'Kombo Muzu!';
  @override
  String get statusMagnet => 'Mıknatıs modu!';
  @override
  String get statusShieldUp => 'Kalkan hazır!';
  @override
  String get statusShieldSaved => 'Kalkan seni kurtardı!';
  @override
  String get statusRevived => 'Yarışa geri döndün!';

  @override
  String get pausedTitle => 'Duraklatıldı';
  @override
  String get pausedSubtitle => 'Bir nefes al. Blender hâlâ pusuda.';
  @override
  String get resume => 'Devam';
  @override
  String get restart => 'Yeniden Başla';
  @override
  String get mainMenu => 'Ana Menü';
  @override
  String get continueTitle => 'Ramak kaldı!';
  @override
  String get continueSubtitle =>
      'Altınlarını harcayıp blenderdan kurtul ve turuna devam et.';
  @override
  String get yourCoins => 'Altınların';
  @override
  String get thisRun => 'Bu tur';
  @override
  String runEndsIn(int seconds) => 'Tur $seconds sn içinde bitiyor';
  @override
  String continueFor(String cost) => '$cost altınla devam et';
  @override
  String get noThanks => 'Hayır, teşekkürler';
  @override
  String get blendedTitle => 'Karıştın!';
  @override
  String get blendedSubtitle =>
      'Pes etmek için fazla olgunsun. Tekrar dene, rekoru kır.';
  @override
  String get newBest => 'Yeni Rekor!';
  @override
  String get runScore => 'Tur Skoru';
  @override
  String get best => 'Rekor';
  @override
  String get distance => 'Mesafe';
  @override
  String get missionProgress => 'Görev İlerlemesi';
  @override
  String get retry => 'Tekrar Dene';

  @override
  String get dailyBunch => 'Günlük Salkım';
  @override
  String get dailyBunchSubtitle =>
      'Her gün gel — ödül serinle birlikte büyür.';
  @override
  String dailyCollected(String coins) => 'Günlük salkım alındı: +$coins altın';
  @override
  String get missionsSubtitle => 'Bir tur daha oynatan kısa hedefler.';
  @override
  String get dailyAlreadyClaimed => 'Bugün zaten alındı';
  @override
  String get dailyCollectedTomorrow => 'Alındı. Yarın tekrar gel.';
  @override
  String dailyDayReward(int day, int reward) =>
      '$day. gün ödülü: $reward altın';
  @override
  String dailyClaim(int reward) => '$reward altını al';
  @override
  String get missionDone => 'Tamam';
  @override
  String shieldsHeld(int count) => 'Kalkan ×$count · turda çift dokun';
  @override
  String get noShields => 'Kalkan yok — zor turlar için bir tane al';

  @override
  String get shopTitle => 'Mağaza';
  @override
  String get tabUpgrades => 'Geliştirmeler';
  @override
  String get tabSkins => 'Kostümler';
  @override
  String get powerUps => 'GÜÇLENDİRMELER';
  @override
  String get powerUpsSubtitle => 'Kalıcı. Her tur, sonsuza dek.';
  @override
  String get items => 'EŞYALAR';
  @override
  String get itemsSubtitle => 'Gerektiğinde kaldırman için.';
  @override
  String get shieldTitle => 'Kabuk Kalkanı';
  @override
  String get shieldDescription =>
      'Turda çift dokunup 5 sn kaldır. Bir çarpışmayı emer.';
  @override
  String shieldHeld(int count, int max) => '$count/$max elde';
  @override
  String get full => 'Dolu';
  @override
  String get maxed => 'Maks.';
  @override
  String confirmBuy(String item) => '$item satın alınsın mı?';
  @override
  String confirmSpend(String cost, String balance) =>
      '$balance altınından $cost altın harcanacak.';
  @override
  String get notYet => 'Şimdi değil';
  @override
  String get buyIt => 'Satın al';
  @override
  String get newSkin => 'YENİ KOSTÜM!';
  @override
  String get equippedRun => 'Giyildi — hadi koşalım!';
  @override
  String get equipped => 'Giyildi';
  @override
  String get equip => 'Giy';
  @override
  String get owned => 'Sahipsin';
  @override
  String unlockFor(String cost) => 'Aç · $cost';
  @override
  String coinsToUnlock(String missing) => 'Açmak için $missing altın daha';
  @override
  String get itemShield => 'Kabuk Kalkanı';
  @override
  String upgradeLevelName(String title, int level) => '$title $level. seviye';
  @override
  String upgradeShortLevel(String title, int level) => '$title Sv $level';

  @override
  String get oneItemReady => '1 ürün satın almaya hazır';
  @override
  String itemsReady(int count) => '$count ürün satın almaya hazır';
  @override
  String get nudgeDetail => 'Altınlar cebini yakıyor.';
  @override
  String savingFor(String goal) => '$goal için biriktiriyorsun';
  @override
  String coinsToGo(String coins) => '$coins altın kaldı';

  @override
  String shieldRackFull(int max) => 'Kalkan rafı dolu — en fazla $max.';
  @override
  String get shieldAdded => 'Kalkan eklendi. Turda çift dokunarak kaldır.';
  @override
  String upgradeMaxed(String title) => '$title zaten son seviyede.';
  @override
  String upgradeNowLevel(String title, int level) =>
      '$title artık $level. seviye!';
  @override
  String skinLocked(String name) => '$name henüz kilitli.';
  @override
  String skinEquipped(String name) => '$name giyildi.';
  @override
  String skinAlreadyOwned(String name) => '$name zaten sende.';
  @override
  String skinUnlocked(String name) => '$name açıldı!';
  @override
  String needMoreCoins(String missing) => '$missing altın daha lazım.';

  @override
  String rarityLabel(String rarityName) => switch (rarityName) {
        'standard' => 'Standart',
        'common' => 'Yaygın',
        'rare' => 'Nadir',
        'epic' => 'Epik',
        _ => 'Efsanevi',
      };
  @override
  String skinName(String id) => switch (id) {
        'classic' => 'Klasik Kabuk',
        'mint_chip' => 'Nane Esintisi',
        'berry_pop' => 'Meyve Patlaması',
        'choco_dip' => 'Çikolata Banyosu',
        'galaxy_peel' => 'Galaksi Kabuğu',
        'lava_peel' => 'Lav Kabuğu',
        'frost_bite' => 'Buz Isırığı',
        _ => 'Altın Muz',
      };
  @override
  String upgradeTitle(String id) => switch (id) {
        'magnet_duration' => 'Uzun Mıknatıs',
        'combo_window' => 'Sağlam Kombo',
        _ => 'Sulu Muzlar',
      };
  @override
  String upgradeDescription(String id) => switch (id) {
        'magnet_duration' => 'Mıknatıs altınları daha uzun süre çeker.',
        'combo_window' =>
          'Kombo sönmeden önce toplamalar arası daha fazla süre.',
        _ => 'Kombo muzu başına ödenen altın.',
      };
  @override
  String missionTitle(String id) => switch (id) {
        'collect_20_in_run' => 'Muz Bankacısı',
        'reach_500_distance' => 'Uzun Kabuk',
        _ => 'Isınma',
      };
  @override
  String missionDescription(String id) => switch (id) {
        'collect_20_in_run' => 'Tek turda 20 altın topla',
        'reach_500_distance' => '500 metreye ulaş',
        _ => '3 tur oyna',
      };
}
