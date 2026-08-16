/// Short-lived emotional states the banana drops into during a run.
///
/// [running] is the resting state; everything else is entered by a gameplay
/// event and decays back to [running] on its own timer.
enum PlayerMood {
  running,

  /// Squeaked past an obstacle. Wide eyes, open mouth.
  startled,

  /// Just grabbed a coin or combo token. Big grin, closed happy eyes.
  delighted,

  /// Magnet is active. Determined smirk plus a spark in the eyes.
  charged,
}
