/// The player's shields during one run: a stock carried in from the profile
/// and at most one raised at a time.
///
/// Raising a shield is the player's call (a double-tap), and a raised shield
/// only lasts [duration] — long enough to thread one nasty stretch, short
/// enough that timing it is the skill. It absorbs the first crash inside
/// that window and drops.
class ShieldState {
  ShieldState({required int stock}) : _stock = stock < 0 ? 0 : stock;

  static const double duration = 5;

  int _stock;
  double _remaining = 0;

  int get stock => _stock;
  bool get isActive => _remaining > 0;

  /// Seconds left on the raised shield; 0 when none is up.
  double get remaining => _remaining;

  bool get canActivate => _stock > 0 && !isActive;

  /// Spends one shield from the stock and raises it. Returns false, changing
  /// nothing, when the stock is empty or a shield is already up.
  bool activate() {
    if (!canActivate) {
      return false;
    }
    _stock -= 1;
    _remaining = duration;
    return true;
  }

  /// Advances the clock. Returns true on the tick the shield runs out
  /// without having absorbed anything.
  bool tick(double dt) {
    if (!isActive) {
      return false;
    }
    _remaining -= dt;
    if (_remaining <= 0) {
      _remaining = 0;
      return true;
    }
    return false;
  }

  /// Uses the raised shield up on a crash. Returns false when none was up,
  /// meaning the crash stands.
  bool absorb() {
    if (!isActive) {
      return false;
    }
    _remaining = 0;
    return true;
  }
}
