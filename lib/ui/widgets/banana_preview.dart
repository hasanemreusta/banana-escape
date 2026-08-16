import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/models/skin.dart';
import 'package:flutter/material.dart';

class BananaPreview extends StatelessWidget {
  const BananaPreview({
    super.key,
    required this.skin,
    this.showAura = true,
    this.angle = -0.18,
  });

  final BananaSkin skin;
  final bool showAura;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _BananaPreviewPainter(
          skin: skin,
          showAura: showAura,
          angle: angle,
        ),
      ),
    );
  }
}

class _BananaPreviewPainter extends CustomPainter {
  const _BananaPreviewPainter({
    required this.skin,
    required this.showAura,
    required this.angle,
  });

  final BananaSkin skin;
  final bool showAura;
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (showAura) {
      canvas.drawCircle(
        center,
        size.width * 0.4,
        Paint()
          ..shader = RadialGradient(
            colors: [
              skin.auraColor.withValues(alpha: 0.28),
              skin.auraColor.withValues(alpha: 0.0),
            ],
          ).createShader(
              Rect.fromCircle(center: center, radius: size.width * 0.4)),
      );
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(size.width / 120, size.height / 120);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 40), width: 70, height: 16),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    final bodyRect =
        Rect.fromCenter(center: const Offset(0, 2), width: 58, height: 96);
    final bodyPath = Path()
      ..moveTo(-17, -38)
      ..quadraticBezierTo(19, -46, 22, -10)
      ..quadraticBezierTo(24, 18, 16, 36)
      ..quadraticBezierTo(9, 46, -1, 44)
      ..quadraticBezierTo(-22, 40, -24, 4)
      ..quadraticBezierTo(-23, -20, -17, -38)
      ..close();

    canvas.drawPath(
      bodyPath.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            skin.primaryColor,
            AppColors.bananaLight,
            skin.secondaryColor
          ],
          stops: const [0.0, 0.46, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        ).createShader(bodyRect),
    );

    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawPath(
      Path()
        ..moveTo(9, -22)
        ..quadraticBezierTo(22, 2, 16, 30)
        ..quadraticBezierTo(8, 40, 0, 36)
        ..quadraticBezierTo(10, 12, 9, -22),
      Paint()..color = AppColors.bananaDark.withValues(alpha: 0.16),
    );

    final peel = Path()
      ..moveTo(-10, -42)
      ..quadraticBezierTo(-12, -58, -2, -48)
      ..quadraticBezierTo(1, -62, 7, -47)
      ..quadraticBezierTo(16, -55, 14, -38)
      ..close();
    canvas.drawPath(peel, Paint()..color = skin.stemColor);
    canvas.drawPath(
      Path()
        ..moveTo(-5, -36)
        ..quadraticBezierTo(2, -48, 8, -37),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      Path()
        ..moveTo(-7, -26)
        ..quadraticBezierTo(10, -30, 10, 10)
        ..quadraticBezierTo(7, 24, 2, 31),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    final brow = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(-13, -7)
        ..quadraticBezierTo(-9, -10, -4, -8),
      brow,
    );
    canvas.drawPath(
      Path()
        ..moveTo(6, -9)
        ..quadraticBezierTo(10, -12, 14, -10),
      brow,
    );

    final eye = Paint()..color = AppColors.ink;
    canvas.drawCircle(const Offset(-9, 1), 3.5, eye);
    canvas.drawCircle(const Offset(10, -1), 3.5, eye);
    canvas.drawCircle(
      const Offset(-8, 0),
      1.1,
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );
    canvas.drawCircle(
      const Offset(11, -2),
      1.1,
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );

    final blush = Paint()..color = AppColors.blush.withValues(alpha: 0.75);
    canvas.drawCircle(const Offset(-14, 12), 4, blush);
    canvas.drawCircle(const Offset(14, 12), 4, blush);

    canvas.drawPath(
      Path()
        ..moveTo(-8, 17)
        ..quadraticBezierTo(2, 24, 12, 15)
        ..quadraticBezierTo(2, 22, -8, 17),
      Paint()..color = AppColors.coral.withValues(alpha: 0.14),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-9, 18)
        ..quadraticBezierTo(2, 28, 13, 15),
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    final glovePaint = Paint()..color = AppColors.cream;
    canvas.drawCircle(const Offset(-27, 28), 3.4, glovePaint);
    canvas.drawCircle(const Offset(22, 24), 3.4, glovePaint);

    final shoePaint = Paint()..color = const Color(0xFFEA6E5E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-10, 43), width: 14, height: 8),
        const Radius.circular(4),
      ),
      shoePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(10, 43), width: 14, height: 8),
        const Radius.circular(4),
      ),
      shoePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-7, 41.5), width: 4, height: 3),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.34),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(13, 41.5), width: 4, height: 3),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.34),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BananaPreviewPainter oldDelegate) {
    return oldDelegate.skin != skin ||
        oldDelegate.showAura != showAura ||
        oldDelegate.angle != angle;
  }
}
