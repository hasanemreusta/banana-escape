import 'dart:math' as math;

import 'package:banana_escape/config/game_config.dart';
import 'package:banana_escape/game/banana_escape_game.dart';
import 'package:banana_escape/game/data/sky_palette.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Sky, horizon and road.
///
/// Layers scroll at different rates to fake depth: the ridge line barely
/// drifts, palms slide past at a middling pace, and roadside props rush by
/// almost as fast as the road itself.
class BackgroundComponent extends Component
    with HasGameReference<BananaEscapeGame> {
  /// Seconds for one full noon -> sunset -> night -> dawn loop.
  ///
  /// Deliberately short. Emulator runs ended around 15-20 seconds, so a longer
  /// cycle would mean most players never see past midday and night would be
  /// effectively dead content. At 44s a routine run reaches sunset and a good
  /// one runs through night into dawn.
  static const double _dayCycleSeconds = 44;

  static const double _horizonFactor = 0.57;

  double _roadScroll = 0;
  double _cloudScroll = 0;
  double _ridgeScroll = 0;
  double _palmScroll = 0;
  double _propScroll = 0;

  SkyPalette _palette = SkyPalette.noon;
  final List<_Star> _stars = [];
  final math.Random _random = math.Random(7);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    _seedStars(size);
  }

  void _seedStars(Vector2 size) {
    _stars
      ..clear()
      ..addAll(
        List.generate(38, (_) {
          return _Star(
            dx: _random.nextDouble() * size.x,
            dy: _random.nextDouble() * size.y * _horizonFactor,
            radius: 0.7 + _random.nextDouble() * 1.3,
            twinkleOffset: _random.nextDouble() * math.pi * 2,
          );
        }),
      );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final speed = game.scrollSpeed;
    _roadScroll += speed * dt;
    _cloudScroll += 12 * dt;
    _ridgeScroll += speed * dt * 0.035;
    _palmScroll += speed * dt * 0.16;
    _propScroll += speed * dt * 0.62;
    _palette = SkyPalette.at(game.runTime / _dayCycleSeconds);
  }

  @override
  void render(Canvas canvas) {
    final size = game.size;
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    final horizonY = size.y * _horizonFactor;

    _drawSky(canvas, size);
    _drawStars(canvas);
    _drawOrb(canvas, size);
    _drawClouds(canvas, size);
    _drawRidges(canvas, size, horizonY);
    _drawGround(canvas, size, horizonY);
    _drawPalms(canvas, size, horizonY);
    _drawRoadBase(canvas, size);
    _drawRoadsideProps(canvas, size);
    _drawRoadMotion(canvas, size);
    _drawSpeedLines(canvas, size);
  }

  void _drawSky(Canvas canvas, Vector2 size) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [_palette.skyTop, _palette.skyMid, _palette.skyBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
  }

  void _drawStars(Canvas canvas) {
    if (_palette.starAlpha <= 0.02) {
      return;
    }
    for (final star in _stars) {
      final twinkle =
          0.65 + math.sin(_cloudScroll * 0.6 + star.twinkleOffset) * 0.35;
      canvas.drawCircle(
        Offset(star.dx, star.dy),
        star.radius,
        Paint()
          ..color = Colors.white
              .withValues(alpha: _palette.starAlpha * twinkle * 0.9),
      );
    }
  }

  void _drawOrb(Canvas canvas, Vector2 size) {
    final center = Offset(size.x * 0.82, size.y * 0.16);
    canvas.drawCircle(
      center,
      110,
      Paint()..color = _palette.orbGlow.withValues(alpha: 0.13),
    );
    canvas.drawCircle(
      center,
      72,
      Paint()..color = _palette.orbGlow.withValues(alpha: 0.4),
    );
    canvas.drawCircle(center, 54, Paint()..color = _palette.orb);
  }

  void _drawClouds(Canvas canvas, Vector2 size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75 - _palette.starAlpha * 0.5);
    for (var i = 0; i < 4; i++) {
      final cloudX = (i * 150 + 40 - _cloudScroll) % (size.x + 120);
      final center = Offset(cloudX, 90 + (i % 2) * 52);
      canvas.drawCircle(center, 18, paint);
      canvas.drawCircle(center.translate(18, 2), 14, paint);
      canvas.drawCircle(center.translate(-18, 4), 14, paint);
      canvas.drawOval(
        Rect.fromCenter(center: center.translate(2, 10), width: 60, height: 22),
        paint,
      );
    }
  }

  void _drawRidges(Canvas canvas, Vector2 size, double horizonY) {
    // Two ridge bands drift horizontally at different rates. The offset wraps
    // on the band width so the silhouette never shows a seam.
    _drawRidgeBand(
      canvas,
      size,
      horizonY - 8,
      _ridgeScroll * 0.5,
      _palette.ridgeFar,
      42,
    );
    _drawRidgeBand(
      canvas,
      size,
      horizonY,
      _ridgeScroll,
      _palette.ridgeNear,
      28,
    );
  }

  void _drawRidgeBand(
    Canvas canvas,
    Vector2 size,
    double baseY,
    double scroll,
    Color color,
    double amplitude,
  ) {
    const span = 96.0;
    final offset = -(scroll % span);
    final path = Path()..moveTo(offset, baseY);
    var index = 0;
    for (var x = offset; x < size.x + span; x += span) {
      // Deterministic zig-zag: alternating peak heights keep it readable at a
      // glance without looking machine-regular.
      final peak = baseY - amplitude * (index.isEven ? 1.0 : 0.55);
      path.lineTo(x + span / 2, peak);
      path.lineTo(x + span, baseY);
      index++;
    }
    path
      ..lineTo(size.x + span, baseY + 60)
      ..lineTo(offset, baseY + 60)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawGround(Canvas canvas, Vector2 size, double horizonY) {
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.x, size.y - horizonY),
      Paint()..color = _palette.ground,
    );
    final hazeRect = Rect.fromLTWH(0, horizonY - 12, size.x, 12);
    canvas.drawRect(
      hazeRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _palette.skyBottom.withValues(alpha: 0.0),
            _palette.skyBottom.withValues(alpha: 0.22),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(hazeRect),
    );
  }

  void _drawPalms(Canvas canvas, Vector2 size, double horizonY) {
    // Mid-depth palms: they sit near the horizon and slide sideways, reading
    // as distant scenery rather than roadside objects.
    const span = 150.0;
    final offset = -(_palmScroll % span);
    var index = 0;
    for (var x = offset; x < size.x + span; x += span) {
      final scale = index.isEven ? 1.0 : 0.78;
      _drawPalm(
        canvas,
        Offset(x + (index.isEven ? 18 : 96), horizonY + 4),
        scale,
      );
      index++;
    }
  }

  void _drawPalm(Canvas canvas, Offset base, double scale) {
    final trunkHeight = 82 * scale;
    canvas.drawRect(
      Rect.fromLTWH(base.dx, base.dy - trunkHeight, 8 * scale, trunkHeight),
      Paint()..color = _palette.palmTrunk,
    );
    final leafPaint = Paint()
      ..color = _palette.palmLeaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round;
    for (var i = -2; i <= 2; i++) {
      canvas.drawPath(
        Path()
          ..moveTo(base.dx + 4 * scale, base.dy - trunkHeight + 4)
          ..quadraticBezierTo(
            base.dx + 18 * i * scale,
            base.dy - trunkHeight - 26 * scale,
            base.dx + 28 * i * scale,
            base.dy - trunkHeight + 22 * scale,
          ),
        leafPaint,
      );
    }
  }

  void _drawRoadBase(Canvas canvas, Vector2 size) {
    final roadWidth = game.roadWidth;
    final roadLeft = game.roadLeft;
    final shoulderWidth = size.x <= 360 ? 18.0 : 24.0;

    final shoulderRect = Rect.fromLTWH(
      roadLeft - shoulderWidth,
      0,
      roadWidth + shoulderWidth * 2,
      size.y,
    );
    canvas.drawRect(
      shoulderRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _palette.roadEdge,
            Color.lerp(_palette.roadEdge, _palette.roadCore, 0.5)!,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(shoulderRect),
    );

    final roadRect = Rect.fromLTWH(roadLeft, 0, roadWidth, size.y);
    canvas.drawRect(
      roadRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(_palette.roadCore, Colors.white, 0.06)!,
            _palette.roadCore,
            Color.lerp(_palette.roadCore, Colors.white, 0.05)!,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(roadRect),
    );

    final railWidth = size.x <= 360 ? 3.0 : 4.0;
    final railInset = size.x <= 360 ? 12.0 : 16.0;
    final railPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color.lerp(_palette.rail, Colors.white, 0.5)!,
          _palette.rail,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, 12, size.y));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(roadLeft - railInset, 0, railWidth, size.y),
        const Radius.circular(8),
      ),
      railPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          roadLeft + roadWidth + (railInset - railWidth),
          0,
          railWidth,
          size.y,
        ),
        const Radius.circular(8),
      ),
      railPaint,
    );
  }

  void _drawRoadsideProps(Canvas canvas, Vector2 size) {
    // Near layer: bushes and marker posts streaming down past the shoulder.
    // These carry most of the felt speed.
    const span = 132.0;
    final roadLeft = game.roadLeft;
    final roadRight = game.roadLeft + game.roadWidth;
    final inset = size.x <= 360 ? 26.0 : 38.0;

    for (var side = 0; side < 2; side++) {
      final x = side == 0 ? roadLeft - inset : roadRight + inset;
      var index = 0;
      for (var y = -(_propScroll % span) - span; y < size.y + span; y += span) {
        final isBush = ((index + side) % 2) == 0;
        if (isBush) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(x, y),
              width: 34,
              height: 20,
            ),
            Paint()..color = _palette.palmLeaf.withValues(alpha: 0.85),
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(x - 6, y - 5),
              width: 18,
              height: 12,
            ),
            Paint()..color = Colors.white.withValues(alpha: 0.12),
          );
        } else {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(x, y),
                width: 7,
                height: 26,
              ),
              const Radius.circular(3),
            ),
            Paint()..color = Colors.white.withValues(alpha: 0.72),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(x, y - 8),
                width: 7,
                height: 8,
              ),
              const Radius.circular(3),
            ),
            Paint()..color = _palette.rail,
          );
        }
        index++;
      }
    }
  }

  void _drawRoadMotion(Canvas canvas, Vector2 size) {
    final roadWidth = game.roadWidth;
    final roadLeft = game.roadLeft;
    final dashPaint = Paint()..color = Colors.white.withValues(alpha: 0.82);
    for (var lane = 1; lane < GameConfig.laneCount; lane++) {
      final x = roadLeft + lane * roadWidth / GameConfig.laneCount;
      for (var i = -1; i < 12; i++) {
        final y = ((i * 86.0) + (_roadScroll * 1.2)) % (size.y + 120) - 60;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 4, y, 8, 42),
            const Radius.circular(4),
          ),
          dashPaint,
        );
      }
    }

    final edgeLightPaint = Paint()..color = _palette.rail;
    for (var i = -1; i < 16; i++) {
      final y = ((i * 54.0) + (_roadScroll * 1.4)) % (size.y + 70) - 35;
      for (final x in [roadLeft - 10, roadLeft + roadWidth + 10]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 8, height: 10),
            const Radius.circular(4),
          ),
          edgeLightPaint,
        );
      }
    }
  }

  void _drawSpeedLines(Canvas canvas, Vector2 size) {
    // Only appear once the run is genuinely fast, so they read as a reward for
    // surviving rather than as constant visual noise.
    final speedFactor = ((game.scrollSpeed - GameConfig.initialScrollSpeed) /
            (GameConfig.maxScrollSpeed - GameConfig.initialScrollSpeed))
        .clamp(0.0, 1.0);
    if (speedFactor < 0.35) {
      return;
    }
    final intensity = (speedFactor - 0.35) / 0.65;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05 + intensity * 0.16)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var side = 0; side < 2; side++) {
      final baseX = side == 0 ? size.x * 0.06 : size.x * 0.94;
      for (var i = 0; i < 5; i++) {
        final y =
            ((i * 150.0) + (_roadScroll * 2.4)) % (size.y + 160) - 80;
        canvas.drawLine(
          Offset(baseX, y),
          Offset(baseX, y + 46 + intensity * 40),
          paint,
        );
      }
    }
  }
}

class _Star {
  const _Star({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.twinkleOffset,
  });

  final double dx;
  final double dy;
  final double radius;
  final double twinkleOffset;
}
