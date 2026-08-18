import 'package:flutter/material.dart';

/// Colour set for one moment of the day/night cycle.
///
/// The background interpolates between the [cycle] keyframes continuously, so
/// a long run visibly travels from noon through sunset into night and back.
@immutable
class SkyPalette {
  const SkyPalette({
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.orb,
    required this.orbGlow,
    required this.ground,
    required this.ridgeFar,
    required this.ridgeNear,
    required this.palmLeaf,
    required this.palmTrunk,
    required this.roadEdge,
    required this.roadCore,
    required this.rail,
    required this.starAlpha,
  });

  final Color skyTop;
  final Color skyMid;
  final Color skyBottom;

  /// Sun by day, moon by night.
  final Color orb;
  final Color orbGlow;

  final Color ground;
  final Color ridgeFar;
  final Color ridgeNear;
  final Color palmLeaf;
  final Color palmTrunk;
  final Color roadEdge;
  final Color roadCore;
  final Color rail;

  /// 0 in daylight, 1 at full dark. Drives star visibility.
  final double starAlpha;

  static SkyPalette lerp(SkyPalette a, SkyPalette b, double t) {
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return SkyPalette(
      skyTop: c(a.skyTop, b.skyTop),
      skyMid: c(a.skyMid, b.skyMid),
      skyBottom: c(a.skyBottom, b.skyBottom),
      orb: c(a.orb, b.orb),
      orbGlow: c(a.orbGlow, b.orbGlow),
      ground: c(a.ground, b.ground),
      ridgeFar: c(a.ridgeFar, b.ridgeFar),
      ridgeNear: c(a.ridgeNear, b.ridgeNear),
      palmLeaf: c(a.palmLeaf, b.palmLeaf),
      palmTrunk: c(a.palmTrunk, b.palmTrunk),
      roadEdge: c(a.roadEdge, b.roadEdge),
      roadCore: c(a.roadCore, b.roadCore),
      rail: c(a.rail, b.rail),
      starAlpha: a.starAlpha + (b.starAlpha - a.starAlpha) * t,
    );
  }

  // Saturation is deliberately high and the road is kept dark. Coins and the
  // banana are the brightest things on screen, so the surface they sit on has
  // to stay out of their way.
  static const SkyPalette noon = SkyPalette(
    skyTop: Color(0xFF12B4FF),
    skyMid: Color(0xFF62DBFF),
    skyBottom: Color(0xFFFFEE93),
    orb: Color(0xFFFFE45C),
    orbGlow: Color(0x88FFD93B),
    ground: Color(0xFFF7C445),
    ridgeFar: Color(0xFFFFD968),
    ridgeNear: Color(0xFFE09B2E),
    palmLeaf: Color(0xFF23B84B),
    palmTrunk: Color(0xFFB55A24),
    roadEdge: Color(0xFF6B5F7A),
    roadCore: Color(0xFF352F42),
    rail: Color(0xFFFFB300),
    starAlpha: 0,
  );

  static const SkyPalette sunset = SkyPalette(
    skyTop: Color(0xFF2E4BB8),
    skyMid: Color(0xFFFF6B3D),
    skyBottom: Color(0xFFFFC048),
    orb: Color(0xFFFF8A2B),
    orbGlow: Color(0x88FF5E2B),
    ground: Color(0xFFE0803A),
    ridgeFar: Color(0xFFFFA85C),
    ridgeNear: Color(0xFFA85126),
    palmLeaf: Color(0xFF17803A),
    palmTrunk: Color(0xFF7A3818),
    roadEdge: Color(0xFF5A4763),
    roadCore: Color(0xFF2C2136),
    rail: Color(0xFFFF9500),
    starAlpha: 0.15,
  );

  static const SkyPalette night = SkyPalette(
    skyTop: Color(0xFF060B33),
    skyMid: Color(0xFF14205C),
    skyBottom: Color(0xFF2E3C8C),
    orb: Color(0xFFF2F6FF),
    orbGlow: Color(0x666FA0FF),
    ground: Color(0xFF2A2B63),
    ridgeFar: Color(0xFF34386F),
    ridgeNear: Color(0xFF1D1E45),
    palmLeaf: Color(0xFF0E5C3C),
    palmTrunk: Color(0xFF33204A),
    roadEdge: Color(0xFF2A2545),
    roadCore: Color(0xFF14101F),
    rail: Color(0xFFFFD028),
    starAlpha: 1,
  );

  static const SkyPalette dawn = SkyPalette(
    skyTop: Color(0xFF4A5CD6),
    skyMid: Color(0xFFB07EE8),
    skyBottom: Color(0xFFFFB48C),
    orb: Color(0xFFFFD08A),
    orbGlow: Color(0x77FFA06B),
    ground: Color(0xFFE0A05E),
    ridgeFar: Color(0xFFFFC08F),
    ridgeNear: Color(0xFF9E6440),
    palmLeaf: Color(0xFF1D9455),
    palmTrunk: Color(0xFF7D4626),
    roadEdge: Color(0xFF534566),
    roadCore: Color(0xFF261F36),
    rail: Color(0xFFFFC02E),
    starAlpha: 0.35,
  );

  /// Keyframes in cycle order. The background wraps from the last back to the
  /// first, so the loop is seamless.
  static const List<SkyPalette> cycle = [noon, sunset, night, dawn];

  /// Samples the cycle at [progress] (0..1 across a full day).
  static SkyPalette at(double progress) {
    final scaled = (progress % 1.0) * cycle.length;
    final index = scaled.floor() % cycle.length;
    final next = (index + 1) % cycle.length;
    return lerp(cycle[index], cycle[next], scaled - scaled.floor());
  }
}
