import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/game/data/collectible_type.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CollectibleComponent extends PositionComponent {
  CollectibleComponent({
    required this.type,
    required this.lane,
    required this.speed,
  }) {
    anchor = Anchor.center;
  }

  final CollectibleType type;
  final int lane;
  double speed;
  double _pulse = 0;

  static final Map<String, ui.Picture> _pictureCache = {};

  Rect get hitbox => Rect.fromCenter(
        center: Offset(position.x, position.y),
        width: size.x * 0.75,
        height: size.y * 0.75,
      );

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    _pulse += dt * 5;
  }

  @override
  void render(Canvas canvas) {
    final picture = _pictureCache.putIfAbsent(_cacheKey, _buildPicture);
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    final scale = 1 + math.sin(_pulse) * 0.06;
    canvas.scale(scale);
    canvas.translate(-size.x / 2, -size.y / 2);
    canvas.drawPicture(picture);
    canvas.restore();
  }

  String get _cacheKey =>
      '${type.name}_${size.x.round()}_${size.y.round()}';

  ui.Picture _buildPicture() {
    final recorder = ui.PictureRecorder();
    final cacheCanvas = Canvas(recorder);
    cacheCanvas.save();
    cacheCanvas.translate(size.x / 2, size.y / 2);
    switch (type) {
      case CollectibleType.coin:
        _drawCoin(cacheCanvas);
      case CollectibleType.combo:
        _drawCombo(cacheCanvas);
      case CollectibleType.magnet:
        _drawMagnet(cacheCanvas);
    }
    cacheCanvas.restore();
    return recorder.endRecording();
  }

  void _drawCoin(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 46, height: 54),
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.coin.withValues(alpha: 0.42),
            AppColors.coin.withValues(alpha: 0.0),
          ],
        ).createShader(
          const Rect.fromLTWH(-23, -23, 46, 54),
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 34, height: 44),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFF7A0), AppColors.coin, AppColors.coinDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(
          Rect.fromCenter(center: Offset.zero, width: 34, height: 44),
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 34, height: 44),
      Paint()
        ..color = const Color(0xFFFFF7C6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 26, height: 34),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-4, -6), width: 12, height: 18),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset.zero, width: 28, height: 38),
      -1.1,
      2.2,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    final bananaPaint = Paint()
      ..color = AppColors.bananaDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final banana = Path()
      ..moveTo(-8, 4)
      ..quadraticBezierTo(-2, -10, 10, -2)
      ..quadraticBezierTo(2, 12, -8, 4);
    canvas.drawPath(banana, bananaPaint);
    canvas.drawCircle(
      const Offset(10, -14),
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.32),
    );
  }

  void _drawCombo(Canvas canvas) {
    canvas.drawCircle(
        Offset.zero, 24, Paint()..color = const Color(0x38FF8B3D));
    canvas.drawCircle(
      Offset.zero,
      20,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFB15F), AppColors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 20)),
    );
    canvas.drawCircle(
      Offset.zero,
      20,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final sparklePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, -28), const Offset(0, -20), sparklePaint);
    canvas.drawLine(const Offset(-22, 0), const Offset(-14, 0), sparklePaint);
    canvas.drawLine(const Offset(22, 0), const Offset(14, 0), sparklePaint);
    canvas.drawCircle(
      const Offset(-5, -6),
      6,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    final text = TextPainter(
      text: const TextSpan(
        text: 'x5',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
  }

  void _drawMagnet(Canvas canvas) {
    canvas.drawCircle(
      Offset.zero,
      24,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.ocean.withValues(alpha: 0.26),
            AppColors.ocean.withValues(alpha: 0.0),
          ],
        ).createShader(const Rect.fromLTWH(-24, -24, 48, 48)),
    );
    canvas.drawCircle(
      Offset.zero,
      18,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    final paint = Paint()
      ..color = AppColors.coral
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(-14, -10)
      ..quadraticBezierTo(-18, 14, -2, 18)
      ..moveTo(14, -10)
      ..quadraticBezierTo(18, 14, 2, 18);
    canvas.drawPath(path, paint);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(-12, -12), width: 10, height: 14),
      Paint()..color = const Color(0xFF7FDFFF),
    );
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(12, -12), width: 10, height: 14),
      Paint()..color = const Color(0xFF7FDFFF),
    );
    canvas.drawCircle(
      const Offset(-12, -16),
      2.2,
      Paint()..color = Colors.white.withValues(alpha: 0.32),
    );
    canvas.drawCircle(
      const Offset(12, -16),
      2.2,
      Paint()..color = Colors.white.withValues(alpha: 0.32),
    );
  }
}
