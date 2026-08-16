import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FeedbackBurstComponent extends PositionComponent {
  FeedbackBurstComponent({
    required super.position,
    required this.color,
    this.duration = 0.42,
    this.particles = 8,
    this.baseRadius = 28,
    this.ring = false,
  }) {
    anchor = Anchor.center;
    size = Vector2.all(baseRadius * 2);
  }

  final Color color;
  final double duration;
  final int particles;
  final double baseRadius;
  final bool ring;

  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    final progress = (_elapsed / duration).clamp(0.0, 1.0).toDouble();
    final eased = Curves.easeOutCubic.transform(progress);
    final alpha = 1 - Curves.easeIn.transform(progress);

    if (ring) {
      canvas.drawCircle(
        Offset.zero,
        baseRadius * (0.4 + eased * 1.2),
        Paint()
          ..color = color.withValues(alpha: alpha * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 - (progress * 2.4),
      );
    }

    for (var i = 0; i < particles; i++) {
      final angle = (math.pi * 2 * i) / particles;
      final travel = baseRadius * (0.24 + eased);
      final offset = Offset(math.cos(angle) * travel, math.sin(angle) * travel);
      final radius = 2.6 + (1 - progress) * 2.8;
      canvas.drawCircle(
        offset,
        radius,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }

    canvas.drawCircle(
      Offset.zero,
      6 + (1 - progress) * 6,
      Paint()..color = color.withValues(alpha: alpha * 0.5),
    );
    canvas.restore();
  }
}
