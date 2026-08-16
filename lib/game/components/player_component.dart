import 'dart:math' as math;

import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/config/game_config.dart';
import 'package:banana_escape/game/data/player_mood.dart';
import 'package:banana_escape/models/skin.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlayerComponent extends PositionComponent {
  PlayerComponent({
    required this.skin,
  });

  BananaSkin skin;

  late List<double> laneCenters;
  int lane = 1;
  double _squashTimer = 0;
  double _startX = 0;
  double _targetX = 0;
  double _lean = 0;
  bool _magnetActive = false;
  double magnetPulse = 0;
  double _trailPulse = 0;
  int _targetLane = 1;
  double _moveElapsed = GameConfig.laneMoveDuration;

  /// Drives the run cycle. Legs, arms and body bob are all phase offsets of
  /// this single value so they can never drift out of sync.
  double _runPhase = 0;

  /// 0 at the opening crawl, 1 at [GameConfig.maxScrollSpeed]. Feeds stride
  /// cadence.
  double _speedFactor = 0;

  PlayerMood _mood = PlayerMood.running;
  double _moodRemaining = 0;

  /// Trailing peel sway. Lags [_lean] so the stem whips a beat late.
  double _stemSway = 0;

  void configureLanes(List<double> centers, double yPosition) {
    final snapLane = isChangingLane ? _targetLane : lane;
    laneCenters = centers;
    size = Vector2(70, 98);
    anchor = Anchor.center;
    _targetLane = snapLane;
    lane = snapLane;
    _startX = centers[snapLane];
    _targetX = centers[snapLane];
    _moveElapsed = GameConfig.laneMoveDuration;
    position = Vector2(_targetX, yPosition);
  }

  void moveBy(int delta) {
    if (delta == 0) {
      return;
    }
    if (isChangingLane) {
      // Lock movement until the banana settles into the next lane so one
      // swipe can never be interpreted as a double lane jump.
      return;
    }
    final baseLane = lane;
    final nextLane = (baseLane + delta).clamp(0, laneCenters.length - 1);
    if (nextLane == baseLane) {
      return;
    }
    _startX = position.x;
    _moveElapsed = 0;
    _targetLane = nextLane;
    lane = nextLane;
    _targetX = laneCenters[nextLane];
    _squashTimer = 0.16;
  }

  void triggerCollectBounce() {
    _squashTimer = 0.12;
    setMood(PlayerMood.delighted, 0.45);
  }

  void triggerNearMiss() {
    setMood(PlayerMood.startled, 0.6);
  }

  void setMood(PlayerMood mood, double duration) {
    // Never let a coin pickup stomp a startle mid-flash; the near miss is the
    // more interesting read.
    if (_mood == PlayerMood.startled &&
        _moodRemaining > 0 &&
        mood == PlayerMood.delighted) {
      return;
    }
    _mood = mood;
    _moodRemaining = duration;
  }

  void setMagnetActive(bool value) {
    _magnetActive = value;
  }

  /// [factor] is the current run speed normalised to 0..1.
  void setSpeedFactor(double factor) {
    _speedFactor = factor.clamp(0.0, 1.0).toDouble();
  }

  PlayerMood get mood {
    if (_moodRemaining > 0) {
      return _mood;
    }
    return _magnetActive ? PlayerMood.charged : PlayerMood.running;
  }

  Rect get hitbox => Rect.fromCenter(
        center: Offset(
          position.x + GameConfig.playerVisualOffsetX,
          position.y + 8,
        ),
        width: size.x *
            (GameConfig.playerHitboxWidthFactor -
                (isChangingLane ? 0.04 : 0.0)),
        height: size.y * GameConfig.playerHitboxHeightFactor,
      );

  bool get isChangingLane => _moveElapsed < GameConfig.laneMoveDuration;
  double get laneChangeProgress {
    return (_moveElapsed / GameConfig.laneMoveDuration)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  int get targetLane => _targetLane;
  double get horizontalTravelSign {
    final delta = _targetX - position.x;
    if (delta.abs() < 0.5) {
      return 0;
    }
    return delta.sign;
  }

  bool isEscapingFrom(double x) {
    if (!isChangingLane) {
      return false;
    }
    if (horizontalTravelSign > 0) {
      return x < position.x;
    }
    if (horizontalTravelSign < 0) {
      return x > position.x;
    }
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isChangingLane) {
      _moveElapsed = math.min(
        GameConfig.laneMoveDuration,
        _moveElapsed + dt,
      );
      final progress =
          (_moveElapsed / GameConfig.laneMoveDuration).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(progress);
      position.x = _startX + ((_targetX - _startX) * eased);
      if (_moveElapsed >= GameConfig.laneMoveDuration) {
        position.x = _targetX;
      }
    }
    final deltaX = _targetX - position.x;
    _lean += (((deltaX.sign) * math.min(0.18, deltaX.abs() / 160)) - _lean) *
        math.min(1, dt * 10);
    _stemSway += ((_lean * 1.6) - _stemSway) * math.min(1, dt * 6);
    if (_squashTimer > 0) {
      _squashTimer = math.max(0, _squashTimer - dt);
    }
    if (_moodRemaining > 0) {
      _moodRemaining = math.max(0, _moodRemaining - dt);
    }
    // Stride quickens with speed; the banana never fully stops running.
    _runPhase += dt * (11 + (_speedFactor * 9));
    magnetPulse += dt * 4;
    _trailPulse += dt * 7;
  }

  @override
  void render(Canvas canvas) {
    final squash =
        1.0 + (_squashTimer > 0 ? math.sin(_squashTimer * 18) * 0.08 : 0.0);
    final stride = math.sin(_runPhase);
    // Two bounces per stride: the body rises on each footfall, not each cycle.
    final bob = -(math.sin(_runPhase * 2).abs()) * 2.4;
    final activeMood = mood;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.translate(GameConfig.playerVisualOffsetX, 0);
    canvas.translate(
      0,
      (_squashTimer > 0 ? math.sin(_squashTimer * 18) * 3 : 0) + bob,
    );
    canvas.rotate(_lean);
    canvas.scale(1 - (_squashTimer * 0.1), squash);

    if (_magnetActive) {
      _drawMagnetAura(canvas);
    }

    _drawGroundShadow(canvas);

    if (isChangingLane) {
      _drawLaneTrail(canvas);
    }

    _drawLegs(canvas, stride);
    _drawBody(canvas);
    _drawStem(canvas);
    _drawArms(canvas, stride);
    _drawFace(canvas, activeMood);

    canvas.restore();
  }

  void _drawMagnetAura(Canvas canvas) {
    final auraRadius = 34 + math.sin(magnetPulse) * 3;
    canvas.drawCircle(
      const Offset(0, 4),
      auraRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            skin.auraColor.withValues(alpha: 0.34),
            skin.auraColor.withValues(alpha: 0.05),
          ],
        ).createShader(
          Rect.fromCircle(center: const Offset(0, 4), radius: auraRadius),
        ),
    );
    canvas.drawCircle(
      const Offset(0, 4),
      auraRadius + 8,
      Paint()
        ..color = skin.auraColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawGroundShadow(Canvas canvas) {
    // Shadow tightens as the banana peaks mid-stride, which sells the hop.
    final lift = math.sin(_runPhase * 2).abs();
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, size.y * 0.46),
        width: size.x * (1.02 - lift * 0.12),
        height: 13 - lift * 2.4,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.12 - lift * 0.02),
    );
  }

  void _drawLaneTrail(Canvas canvas) {
    final trailPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          skin.auraColor.withValues(alpha: 0.0),
          skin.auraColor.withValues(alpha: 0.16 + math.sin(_trailPulse) * 0.03),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(
        const Rect.fromLTWH(-42, -12, 84, 42),
      );
    final trailRect = Rect.fromLTWH(
      _lean > 0 ? -46 : -8,
      -8,
      54,
      38,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(trailRect, const Radius.circular(20)),
      trailPaint,
    );
  }

  void _drawLegs(Canvas canvas, double stride) {
    // Legs run in opposite phase: one swings forward and lifts while the other
    // plants.
    for (var i = 0; i < 2; i++) {
      final phase = i == 0 ? stride : -stride;
      final hipX = i == 0 ? -6.0 : 6.0;
      final swing = phase * 7;
      final lift = math.max(0.0, phase) * 6;
      final footX = hipX + swing;
      final footY = 42 - lift;

      canvas.drawPath(
        Path()
          ..moveTo(hipX, 29)
          ..quadraticBezierTo(
            hipX + swing * 0.5,
            35 - lift * 0.4,
            footX,
            footY - 3,
          ),
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(footX, footY),
            width: 14,
            height: 9,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFEB6B5E),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(footX + 3, footY - 1.5),
            width: 4,
            height: 3,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.38),
      );
    }
  }

  void _drawBody(Canvas canvas) {
    final bodyRect = Rect.fromCenter(
      center: const Offset(0, 6),
      width: size.x * 0.74,
      height: size.y * 0.92,
    );

    final bodyPath = Path()
      ..moveTo(-18, -34)
      ..quadraticBezierTo(16, -42, 18, -10)
      ..quadraticBezierTo(19, 18, 14, 34)
      ..quadraticBezierTo(8, 44, -4, 42)
      ..quadraticBezierTo(-18, 40, -20, 6)
      ..quadraticBezierTo(-21, -20, -18, -34)
      ..close();

    canvas.drawPath(
      bodyPath.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            skin.primaryColor,
            AppColors.bananaLight,
            skin.secondaryColor,
          ],
          stops: const [0.0, 0.48, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        ).createShader(bodyRect),
    );

    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8,
    );

    final sideShade = Path()
      ..moveTo(8, -26)
      ..quadraticBezierTo(20, -6, 16, 28)
      ..quadraticBezierTo(7, 40, -1, 38)
      ..quadraticBezierTo(10, 16, 8, -26);
    canvas.drawPath(
      sideShade,
      Paint()..color = AppColors.bananaDark.withValues(alpha: 0.18),
    );

    final highlight = Path()
      ..moveTo(-8, -22)
      ..quadraticBezierTo(8, -28, 10, -2)
      ..quadraticBezierTo(8, 20, 2, 28);
    canvas.drawPath(
      highlight,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    final innerRim = Path()
      ..moveTo(-10, -18)
      ..quadraticBezierTo(-1, -6, -2, 26);
    canvas.drawPath(
      innerRim,
      Paint()
        ..color = AppColors.bananaDark.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawStem(Canvas canvas) {
    canvas.save();
    // Pivot at the base of the stem so the sway reads as a whip, not a slide.
    canvas.translate(0, -36);
    canvas.rotate(-_stemSway);
    canvas.translate(0, 36);

    canvas.drawPath(
      Path()
        ..moveTo(-8, -38)
        ..quadraticBezierTo(-10, -56, -1, -46)
        ..quadraticBezierTo(1, -60, 6, -43)
        ..quadraticBezierTo(14, -54, 14, -36)
        ..close(),
      Paint()..color = skin.stemColor,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-4, -34)
        ..quadraticBezierTo(2, -46, 8, -35),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _drawArms(Canvas canvas, double stride) {
    // Arms counter-swing against the legs, the way a real gait works.
    for (var i = 0; i < 2; i++) {
      final phase = i == 0 ? -stride : stride;
      final side = i == 0 ? -1.0 : 1.0;
      final shoulderX = side * 18;
      final shoulderY = i == 0 ? 8.0 : 7.0;
      final handX = shoulderX + (side * 8) + (phase * 3);
      final handY = shoulderY + 18 - (phase * 9);

      canvas.drawPath(
        Path()
          ..moveTo(shoulderX, shoulderY)
          ..quadraticBezierTo(
            shoulderX + side * 9,
            shoulderY + 8 - phase * 4,
            handX,
            handY,
          ),
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(handX, handY),
        3.5,
        Paint()..color = AppColors.cream,
      );
    }
  }

  void _drawFace(Canvas canvas, PlayerMood mood) {
    // Eyes drift toward the lane being entered so the hero looks where it goes.
    final gaze = (_lean / 0.18).clamp(-1.0, 1.0) * 1.6;
    final leftEye = Offset(-7 + gaze, 0);
    final rightEye = Offset(9 + gaze, -2);

    canvas.drawCircle(
      const Offset(-7, 6),
      8.5,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      const Offset(9, 5),
      8.5,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    final facePaint = Paint()..color = AppColors.ink;
    final browPaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    switch (mood) {
      case PlayerMood.startled:
        // Brows shoot up, pupils shrink inside wide whites.
        canvas.drawPath(
          Path()
            ..moveTo(-12, -11)
            ..quadraticBezierTo(-7, -15, -2, -12),
          browPaint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5, -13)
            ..quadraticBezierTo(9, -17, 14, -15),
          browPaint,
        );
        canvas.drawCircle(leftEye, 5.0, Paint()..color = Colors.white);
        canvas.drawCircle(rightEye, 5.0, Paint()..color = Colors.white);
        canvas.drawCircle(leftEye, 2.4, facePaint);
        canvas.drawCircle(rightEye, 2.4, facePaint);
      case PlayerMood.delighted:
        final arc = Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(
          Path()
            ..moveTo(leftEye.dx - 4, leftEye.dy + 1)
            ..quadraticBezierTo(
                leftEye.dx, leftEye.dy - 5, leftEye.dx + 4, leftEye.dy + 1),
          arc,
        );
        canvas.drawPath(
          Path()
            ..moveTo(rightEye.dx - 4, rightEye.dy + 1)
            ..quadraticBezierTo(
                rightEye.dx, rightEye.dy - 5, rightEye.dx + 4, rightEye.dy + 1),
          arc,
        );
      case PlayerMood.charged:
        canvas.drawPath(
          Path()
            ..moveTo(-11, -8)
            ..quadraticBezierTo(-7, -11, -2, -10),
          browPaint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5, -10)
            ..quadraticBezierTo(9, -13, 13, -12),
          browPaint,
        );
        canvas.drawCircle(leftEye, 3.8, facePaint);
        canvas.drawCircle(rightEye, 3.8, facePaint);
        canvas.drawCircle(
          leftEye.translate(1.2, -1.4),
          1.5,
          Paint()..color = AppColors.mint,
        );
        canvas.drawCircle(
          rightEye.translate(1.2, -1.4),
          1.5,
          Paint()..color = AppColors.mint,
        );
      case PlayerMood.running:
        canvas.drawPath(
          Path()
            ..moveTo(-11, -7)
            ..quadraticBezierTo(-7, -10, -2, -8),
          browPaint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5, -9)
            ..quadraticBezierTo(9, -12, 13, -11),
          browPaint,
        );
        canvas.drawCircle(leftEye, 3.4, facePaint);
        canvas.drawCircle(rightEye, 3.4, facePaint);
        canvas.drawCircle(
          leftEye.translate(1, -1),
          1.1,
          Paint()..color = Colors.white.withValues(alpha: 0.72),
        );
        canvas.drawCircle(
          rightEye.translate(1, -1),
          1.1,
          Paint()..color = Colors.white.withValues(alpha: 0.72),
        );
    }

    canvas.drawCircle(
      const Offset(-11, 10),
      3.5,
      Paint()..color = const Color(0xFFFFA2A9).withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      const Offset(13, 10),
      3.5,
      Paint()..color = AppColors.blush.withValues(alpha: 0.7),
    );

    _drawMouth(canvas, mood);
  }

  void _drawMouth(Canvas canvas, PlayerMood mood) {
    final linePaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    switch (mood) {
      case PlayerMood.startled:
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(2, 18), width: 11, height: 13),
          Paint()..color = AppColors.ink,
        );
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(2, 20), width: 6, height: 6),
          Paint()..color = AppColors.coral.withValues(alpha: 0.6),
        );
      case PlayerMood.delighted:
        final grin = Path()
          ..moveTo(-9, 14)
          ..quadraticBezierTo(2, 30, 13, 12);
        canvas.drawPath(
          grin,
          Paint()..color = AppColors.coral.withValues(alpha: 0.22),
        );
        canvas.drawPath(grin, linePaint);
      case PlayerMood.charged:
        canvas.drawPath(
          Path()
            ..moveTo(-7, 15)
            ..quadraticBezierTo(3, 24, 12, 15),
          linePaint,
        );
      case PlayerMood.running:
        final mouthFill = Path()
          ..moveTo(-7, 16)
          ..quadraticBezierTo(2, 24, 11, 14)
          ..quadraticBezierTo(1, 22, -7, 16);
        canvas.drawPath(
          mouthFill,
          Paint()..color = AppColors.coral.withValues(alpha: 0.15),
        );
        canvas.drawPath(
          Path()
            ..moveTo(-7, 16)
            ..quadraticBezierTo(1, 27, 12, 12),
          linePaint,
        );
    }
  }
}
