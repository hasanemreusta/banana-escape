import 'package:banana_escape/models/game_profile.dart';
import 'package:banana_escape/services/ad_service.dart';
import 'package:banana_escape/services/audio_service.dart';
import 'package:banana_escape/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppServices {
  AppServices({
    required this.storage,
    required this.audio,
    required this.ads,
    required this.profile,
  });

  final StorageService storage;
  final AudioService audio;
  final AdService ads;
  GameProfile profile;

  static Future<AppServices> bootstrap() async {
    final preferences = await SharedPreferences.getInstance();
    final storage = StorageService(preferences);
    final profile = await storage.loadProfile();
    final audio = AudioService(soundOn: profile.soundOn);
    await audio.init();
    final services = AppServices(
      storage: storage,
      audio: audio,
      ads: MockAdService(),
      profile: profile,
    );
    await services.ads.preloadInterstitial();
    await services.ads.preloadRewarded();
    return services;
  }

  Future<void> saveProfile(GameProfile profile) async {
    this.profile = profile;
    audio.setSoundEnabled(profile.soundOn);
    await storage.saveProfile(profile);
  }
}
