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

  static const SkyPalette noon = SkyPalette(
    skyTop: Color(0xFF66CFFF),
    skyMid: Color(0xFFA9ECFF),
    skyBottom: Color(0xFFFFF4CC),
    orb: Color(0xFFFFF2B0),
    orbGlow: Color(0x66FFF6C4),
    ground: Color(0xFFE8CB8B),
    ridgeFar: Color(0xFFF0D8A1),
    ridgeNear: Color(0xFFD4B77B),
    palmLeaf: Color(0xFF5BBE58),
    palmTrunk: Color(0xFFB06F42),
    roadEdge: Color(0xFF7F7680),
    roadCore: Color(0xFF4F4954),
    rail: Color(0xFFFFC85A),
    starAlpha: 0,
  );

  static const SkyPalette sunset = SkyPalette(
    skyTop: Color(0xFF4E7BC8),
    skyMid: Color(0xFFFF9E6B),
    skyBottom: Color(0xFFFFD9A0),
    orb: Color(0xFFFFB169),
    orbGlow: Color(0x66FF9A5C),
    ground: Color(0xFFD9A874),
    ridgeFar: Color(0xFFE0B189),
    ridgeNear: Color(0xFFA9805F),
    palmLeaf: Color(0xFF3E8F52),
    palmTrunk: Color(0xFF8A5334),
    roadEdge: Color(0xFF6C5F6B),
    roadCore: Color(0xFF453C4B),
    rail: Color(0xFFFFB05A),
    starAlpha: 0.15,
  );

  static const SkyPalette night = SkyPalette(
    skyTop: Color(0xFF14204A),
    skyMid: Color(0xFF27356B),
    skyBottom: Color(0xFF4A4E85),
    orb: Color(0xFFEFF3FF),
    orbGlow: Color(0x449FB6FF),
    ground: Color(0xFF4A4462),
    ridgeFar: Color(0xFF3C3A5C),
    ridgeNear: Color(0xFF2C2A46),
    palmLeaf: Color(0xFF1F5741),
    palmTrunk: Color(0xFF43304A),
    roadEdge: Color(0xFF3A3548),
    roadCore: Color(0xFF272232),
    rail: Color(0xFFFFD98B),
    starAlpha: 1,
  );

  static const SkyPalette dawn = SkyPalette(
    skyTop: Color(0xFF6E7FCB),
    skyMid: Color(0xFFC3A6E0),
    skyBottom: Color(0xFFFFD7C2),
    orb: Color(0xFFFFE3C0),
    orbGlow: Color(0x55FFC9A8),
    ground: Color(0xFFCDB394),
    ridgeFar: Color(0xFFD9C0AC),
    ridgeNear: Color(0xFF9C8478),
    palmLeaf: Color(0xFF44916A),
    palmTrunk: Color(0xFF8C6249),
    roadEdge: Color(0xFF635A6B),
    roadCore: Color(0xFF3D3746),
    rail: Color(0xFFFFD07A),
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
