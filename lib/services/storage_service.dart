import 'package:banana_escape/models/game_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService(this._preferences);

  final SharedPreferences _preferences;

  static const String _keyHighScore = 'highScore';
  static const String _keyTotalCoins = 'totalCoins';
  static const String _keySoundOn = 'soundOn';
  static const String _keyTotalRuns = 'totalRuns';
  static const String _keyMissionProgress = 'missionProgress';
  static const String _keyOwnedSkinIds = 'ownedSkinIds';
  static const String _keyEquippedSkinId = 'equippedSkinId';
  static const String _keyDailyReward = 'dailyReward';

  Future<GameProfile> loadProfile() async {
    return GameProfile.fromPrefs({
      'highScore': _preferences.getInt(_keyHighScore),
      'totalCoins': _preferences.getInt(_keyTotalCoins),
      'soundOn': _preferences.getBool(_keySoundOn),
      'totalRuns': _preferences.getInt(_keyTotalRuns),
      'missionProgress': _preferences.getString(_keyMissionProgress),
      'ownedSkinIds': _preferences.getStringList(_keyOwnedSkinIds),
      'equippedSkinId': _preferences.getString(_keyEquippedSkinId),
      'dailyReward': _preferences.getString(_keyDailyReward),
    });
  }

  Future<void> saveProfile(GameProfile profile) async {
    final prefsMap = profile.toPrefs();
    await _preferences.setInt(_keyHighScore, prefsMap['highScore']! as int);
    await _preferences.setInt(_keyTotalCoins, prefsMap['totalCoins']! as int);
    await _preferences.setBool(_keySoundOn, prefsMap['soundOn']! as bool);
    await _preferences.setInt(_keyTotalRuns, prefsMap['totalRuns']! as int);
    await _preferences.setString(
      _keyMissionProgress,
      prefsMap['missionProgress']! as String,
    );
    await _preferences.setStringList(
      _keyOwnedSkinIds,
      (prefsMap['ownedSkinIds']! as List<String>),
    );
    await _preferences.setString(
      _keyEquippedSkinId,
      prefsMap['equippedSkinId']! as String,
    );
    await _preferences.setString(
      _keyDailyReward,
      prefsMap['dailyReward']! as String,
    );
  }
}
