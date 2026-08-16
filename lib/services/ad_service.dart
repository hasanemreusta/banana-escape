abstract class AdService {
  Future<void> preloadInterstitial();
  Future<void> preloadRewarded();
  Future<bool> showInterstitial();
  Future<bool> showRewardedSecondChance();
}

class MockAdService implements AdService {
  @override
  Future<void> preloadInterstitial() async {}

  @override
  Future<void> preloadRewarded() async {}

  @override
  Future<bool> showInterstitial() async => false;

  @override
  Future<bool> showRewardedSecondChance() async => false;
}
