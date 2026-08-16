import 'dart:ui' as ui;

import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/config/game_config.dart';
import 'package:banana_escape/game/data/obstacle_type.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ObstacleComponent extends PositionComponent {
  ObstacleComponent({
    required this.type,
    required this.lane,
    required this.speed,
  }) {
    anchor = Anchor.center;
  }

  final ObstacleType type;
  final int lane;
  double speed;
  bool nearMissAwarded = false;

  static final Map<String, ui.Picture> _pictureCache = {};

  Rect get hitbox => Rect.fromCenter(
        center: Offset(position.x, position.y),
        width: size.x * GameConfig.obstacleHitboxWidthFactor,
        height: size.y * GameConfig.obstacleHitboxHeightFactor,
      );

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
  }

  @override
  void render(Canvas canvas) {
    final picture = _pictureCache.putIfAbsent(_cacheKey, _buildPicture);
    canvas.drawPicture(picture);
  }

  String get _cacheKey =>
      '${type.name}_${size.x.round()}_${size.y.round()}';

  ui.Picture _buildPicture() {
    final recorder = ui.PictureRecorder();
    final cacheCanvas = Canvas(recorder);
    cacheCanvas.save();
    cacheCanvas.translate(size.x / 2, size.y / 2);
    switch (type) {
      case ObstacleType.peel:
        _drawPeel(cacheCanvas);
      case ObstacleType.crate:
        _drawCrate(cacheCanvas);
      case ObstacleType.cart:
        _drawCart(cacheCanvas);
      case ObstacleType.rock:
        _drawRock(cacheCanvas);
      case ObstacleType.pit:
        _drawPit(cacheCanvas);
      case ObstacleType.smoothieBox:
        _drawSmoothieBox(cacheCanvas);
    }
    cacheCanvas.restore();
    return recorder.endRecording();
  }

  void _drawPeel(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 14), width: 52, height: 14),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF1A0), Color(0xFFF9D24E), AppColors.bananaDark],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(-24, -26, 48, 46));
    final path = Path()
      ..moveTo(-24, 12)
      ..quadraticBezierTo(-14, -26, -1, 0)
      ..quadraticBezierTo(12, -28, 24, 12)
      ..quadraticBezierTo(0, 20, -24, 12)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-5, -2)
        ..quadraticBezierTo(0, 7, 6, -1),
      Paint()
        ..color = AppColors.bananaDark.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawCrate(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 26), width: 48, height: 12),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );
    final rect = Rect.fromCenter(center: Offset.zero, width: 52, height: 52);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFDDA267), Color(0xFFC78A48)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    final linePaint = Paint()
      ..color = const Color(0xFF8E5C2E)
      ..strokeWidth = 4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawLine(const Offset(-18, -18), const Offset(18, 18), linePaint);
    canvas.drawLine(const Offset(18, -18), const Offset(-18, 18), linePaint);
    canvas.drawLine(
        const Offset(-20, 0), const Offset(20, 0), linePaint..strokeWidth = 3);
    for (final nail in [
      const Offset(-14, -14),
      const Offset(14, -14),
      const Offset(-14, 14),
      const Offset(14, 14),
    ]) {
      canvas.drawCircle(nail, 2, Paint()..color = const Color(0xFF75461F));
    }
  }

  void _drawCart(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 28), width: 50, height: 12),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );
    final paint = Paint()..color = const Color(0xFF7EC5FF);
    final basket =
        Rect.fromCenter(center: const Offset(0, -2), width: 56, height: 28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(basket, const Radius.circular(8)),
      paint,
    );
    final framePaint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(basket, const Radius.circular(8)),
      framePaint,
    );
    canvas.drawLine(const Offset(-22, 12), const Offset(-12, 26), framePaint);
    canvas.drawLine(const Offset(22, 12), const Offset(12, 26), framePaint);
    canvas.drawCircle(const Offset(-12, 26), 5, Paint()..color = AppColors.ink);
    canvas.drawCircle(const Offset(12, 26), 5, Paint()..color = AppColors.ink);
    canvas.drawLine(const Offset(-12, -10), const Offset(-12, 8),
        framePaint..strokeWidth = 2.8);
    canvas.drawLine(const Offset(0, -10), const Offset(0, 8), framePaint);
    canvas.drawLine(const Offset(12, -10), const Offset(12, 8), framePaint);
    canvas.drawCircle(
      const Offset(-6, -2),
      3,
      Paint()..color = AppColors.coral.withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      const Offset(6, -1),
      3,
      Paint()..color = AppColors.leafGreen.withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      const Offset(-8, 2),
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  void _drawRock(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 20), width: 48, height: 12),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );
    final path = Path()
      ..moveTo(-24, 18)
      ..lineTo(-18, -8)
      ..lineTo(-2, -22)
      ..lineTo(18, -16)
      ..lineTo(24, 10)
      ..lineTo(10, 22)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFC0BCC7), Color(0xFF7E7983)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(-24, -22, 48, 44)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-6, -8)
        ..lineTo(2, -14)
        ..lineTo(8, -4),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(-10, 6),
      5,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  void _drawPit(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 82, height: 50),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 60, height: 34),
      Paint()..color = const Color(0xFF2D2524),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 70, height: 44),
      Paint()
        ..color = const Color(0xFF7E5E4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-6, -2), width: 26, height: 12),
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );
    final crackPaint = Paint()
      ..color = const Color(0xFFA17A5A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(-26, -4)
        ..lineTo(-38, -16)
        ..lineTo(-44, -10),
      crackPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(22, 0)
        ..lineTo(38, -10)
        ..lineTo(46, -2),
      crackPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, 0), width: 78, height: 48),
      3.6,
      0.6,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawSmoothieBox(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 27), width: 44, height: 10),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );
    final rect = Rect.fromCenter(center: Offset.zero, width: 48, height: 54);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFB463), AppColors.orange],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(0, -20), width: 10, height: 14),
      Paint()..color = AppColors.leafGreen,
    );
    canvas.drawCircle(
      const Offset(0, 2),
      9,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 7), width: 24, height: 14),
        const Radius.circular(7),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.26),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-7, 7)
        ..quadraticBezierTo(0, 2, 7, 7),
      Paint()
        ..color = AppColors.coral.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(0, -5), width: 30, height: 4),
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );
  }
}
