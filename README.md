<div align="center">

<img src="assets/branding/playstore-icon-512.png" width="120" alt="Banana Escape icon">

# Banana Escape

**A three-lane endless runner built with Flutter and Flame.**
You are a banana. A blender truck wants you. Swipe or die trying.

[![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Flame](https://img.shields.io/badge/Flame-1.38-FF6B35)](https://flame-engine.org)
[![Android](https://img.shields.io/badge/Android-API%2024–36-3DDC84?logo=android&logoColor=white)](https://developer.android.com)

</div>

---

## What it is

A hypercasual mobile runner with a deliberate constraint: **every visual is drawn
in code**. There is not a single sprite, texture, or image asset in the gameplay
layer. The banana, the blender truck chasing it, the obstacles, the coins, the
sky, the palm trees, the road markings — all of it is `Canvas` path work
rendered per frame.

That constraint is why the release bundle stays around 20 MB, why the art
retargets to any screen size for free, and why a colour swap is a one-line
change instead of a re-export.

## Gameplay

| | |
|---|---|
| **Controls** | Swipe left / right to change lane |
| **Goal** | Survive, collect coins, chase the high score |
| **Pressure** | Speed and obstacle density climb on a timer; a stage banner marks each step up |
| **Combo** | Consecutive pickups build a multiplier up to ×5, and it lapses if you go quiet |
| **Power-ups** | Magnet pulls nearby coins; combo bananas pay a lump sum |
| **Style points** | Threading a gap at the last moment scores a near-miss bonus |
| **Meta** | Daily login streak, four unlockable skins, three missions, persistent high score |

## How it looks in motion

The scene runs four parallax layers at different scroll rates to fake depth:
ridge lines barely drift, palms slide past at a middling pace, roadside bushes
and marker posts rush by, and the road itself moves fastest. On top of that a
continuous day/night cycle interpolates between four palettes — noon, sunset,
night, dawn — over roughly 72 seconds, so a long run visibly travels through
time. Stars fade in as the sky darkens. Speed lines only appear past a
threshold, so they read as a reward for surviving rather than constant noise.

The banana runs a real gait cycle: legs alternate in opposite phase, arms
counter-swing against them, the body bounces twice per stride, and the ground
shadow tightens as it peaks mid-step. Its face reacts to what just happened —
wide-eyed and open-mouthed after a near miss, eyes squeezed into happy arcs on a
pickup, a determined smirk with a spark in the eye while the magnet runs. The
peel stem lags behind the lean so it whips a beat late.

## Architecture

```text
lib/
  app/            MaterialApp shell and theme
  config/         Tunable constants — balance lives here, not scattered in logic
  core/           Value types crossing the game/UI boundary
  game/
    components/   Flame components: player, obstacles, collectibles, background, truck
    data/         Enums and palettes: obstacle types, player moods, sky palettes
    systems/      Spawn controller — wave composition and lane-safety rules
  models/         Persistence-facing types: profile, skins, missions, daily reward
  services/       Storage, audio, ads abstraction
  ui/
    screens/      Splash, main menu, gameplay
    widgets/      Reusable cards and previews
```

Two boundaries are worth calling out:

**The game never touches storage.** `BananaEscapeGame` emits a
`GameSessionResult` when a run ends; `GameProfile.applySession` folds that into
the saved profile. The simulation stays testable without mocking
`SharedPreferences`.

**Balance is data, not code.** Scroll speed, acceleration, spawn intervals,
hitbox factors, combo windows, and collision-forgiveness thresholds all live in
[`lib/config/game_config.dart`](lib/config/game_config.dart). Tuning the game
does not mean reading the game loop.

### Collision forgiveness

A naive rectangle overlap makes a lane runner feel cheap, because the player
reads a near miss as a hit. `_shouldCrash` layers extra rules on top of the
overlap test: grazing the edge of a hitbox while mid-lane-change does not kill
you, an obstacle you are actively moving *away from* is forgiven, and a minimum
overlap on both axes is required before anything counts. The numbers are all in
`GameConfig` so the feel can be tuned without touching the logic.

## Running it

Requires Flutter 3.47 or newer and a configured Android SDK.

```bash
flutter pub get
flutter run
```

```bash
flutter test        # unit + widget tests
flutter analyze     # static analysis
```

## Building for release

Release signing reads `android/key.properties`. Copy the example and point it at
your own upload keystore:

```bash
cp android/key.properties.example android/key.properties
```

```bash
flutter build appbundle --release   # build/app/outputs/bundle/release/app-release.aab
flutter build apk --release
```

The build intentionally fails with a clear message if `key.properties` is
missing, rather than silently signing a Play upload with debug keys.

The Android config tracks the Flutter SDK rather than pinning numbers:
`compileSdk`, `targetSdk`, `minSdk`, and `ndkVersion` all read from
`flutter.*`, so a toolchain upgrade carries the target API bump with it.

> **Note on Kotlin:** the standalone Kotlin Gradle Plugin is used deliberately.
> AGP 9.1's built-in Kotlin bundles 2.2.10, which is below the 2.2.20 minimum
> the Flutter Gradle plugin enforces. See the comment in
> [`android/settings.gradle`](android/settings.gradle).

## Status

Shipping on Google Play. The game collects no data, uses no analytics, and has
no network calls — `AdService` exists as an abstraction with a mock
implementation, deliberately unwired.

## License

Not currently licensed for reuse. All rights reserved.
