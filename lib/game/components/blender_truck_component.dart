import 'dart:math' as math;

import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/config/game_config.dart';
import 'package:banana_escape/game/banana_escape_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BlenderTruckComponent extends Component
    with HasGameReference<BananaEscapeGame> {
  double _bob = 0;
  double? _x;

  @override
  void update(double dt) {
    super.update(dt);
    _bob += dt * 5;
    final targetX = game.playerChaseX + GameConfig.truckVisualOffsetX;
    _x ??= targetX;
    _x = _x! + ((targetX - _x!) * math.min(1, dt * 8));
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(
      _x ?? (game.playerChaseX + GameConfig.truckVisualOffsetX),
      game.size.y - GameConfig.truckBottomOffset + math.sin(_bob) * 3,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 18), width: 136, height: 24),
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 22), width: 112, height: 16),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 0), width: 122, height: 40),
        const Radius.circular(16),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF705B), AppColors.danger],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(
          Rect.fromCenter(center: const Offset(0, 0), width: 122, height: 40),
        ),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 7), width: 110, height: 12),
        const Radius.circular(7),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -2), width: 122, height: 40),
        const Radius.circular(16),
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -7), width: 84, height: 8),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -20), width: 54, height: 30),
        const Radius.circular(12),
      ),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.88),
            const Color(0xFF9EEBFF).withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(
          Rect.fromCenter(center: const Offset(0, -20), width: 54, height: 30),
        ),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -39), width: 34, height: 28),
        const Radius.circular(10),
      ),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.82),
            const Color(0xFFD4F8FF).withValues(alpha: 0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(-17, -53, 34, 28)),
    );

    canvas.drawCircle(
        const Offset(-34, 18), 12, Paint()..color = AppColors.ink);
    canvas.drawCircle(const Offset(34, 18), 12, Paint()..color = AppColors.ink);
    canvas.drawCircle(const Offset(-34, 18), 5, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(34, 18), 5, Paint()..color = Colors.white);
    canvas.drawCircle(
        const Offset(-34, 18), 2, Paint()..color = AppColors.road);
    canvas.drawCircle(const Offset(34, 18), 2, Paint()..color = AppColors.road);

    final bladePaint = Paint()
      ..color = const Color(0xFF68C5FF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, -29), const Offset(10, -21), bladePaint);
    canvas.drawLine(const Offset(0, -29), const Offset(-10, -21), bladePaint);
    canvas.drawLine(const Offset(0, -29), const Offset(0, -16), bladePaint);
    canvas.drawCircle(
        const Offset(0, -29), 3, Paint()..color = const Color(0xFF68C5FF));
    canvas.drawCircle(
      const Offset(0, -39),
      6,
      Paint()..color = Colors.white.withValues(alpha: 0.26),
    );

    final facePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(-14, 1), 4.5, facePaint);
    canvas.drawCircle(const Offset(14, 1), 4.5, facePaint);
    canvas.drawCircle(const Offset(-14, 1), 2, Paint()..color = AppColors.ink);
    canvas.drawCircle(const Offset(14, 1), 2, Paint()..color = AppColors.ink);
    canvas.drawCircle(
      const Offset(-22, 9),
      3.5,
      Paint()..color = AppColors.blush.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      const Offset(22, 9),
      3.5,
      Paint()..color = AppColors.blush.withValues(alpha: 0.75),
    );
    final grin = Path()
      ..moveTo(-11, 11)
      ..quadraticBezierTo(0, 19, 11, 11);
    canvas.drawPath(
      grin,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawCircle(
        const Offset(-48, -3), 4, Paint()..color = const Color(0xFFFFF1A0));
    canvas.drawCircle(
        const Offset(48, -3), 4, Paint()..color = const Color(0xFFFFF1A0));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 8), width: 26, height: 7),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    canvas.restore();
  }
}
