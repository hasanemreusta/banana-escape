import 'dart:math' as math;

import 'package:banana_escape/models/skin.dart';
import 'package:banana_escape/ui/widgets/banana_preview.dart';
import 'package:flutter/material.dart';

/// The hero shot: the banana idling on a lit podium, bobbing and swaying so
/// the menu feels alive rather than a static card. The podium glow takes the
/// skin's rarity colour, so a legendary peel looks legendary from across the
/// room.
class BananaStage extends StatefulWidget {
  const BananaStage({
    super.key,
    required this.skin,
    required this.size,
  });

  final BananaSkin skin;
  final double size;

  @override
  State<BananaStage> createState() => _BananaStageState();
}

class _BananaStageState extends State<BananaStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final glow = widget.skin.rarity.color;
    return SizedBox(
      width: size * 1.3,
      height: size * 1.15,
      child: AnimatedBuilder(
        animation: _idle,
        builder: (context, _) {
          final phase = _idle.value * math.pi * 2;
          final lift = (math.sin(phase * 2).abs()) * size * 0.05;
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Podium: a lit ellipse with a rarity-coloured rim.
              Positioned(
                bottom: 0,
                child: Container(
                  width: size * 1.05,
                  height: size * 0.26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(size * 0.52, size * 0.13),
                    ),
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.95),
                        glow.withValues(alpha: 0.35),
                      ],
                    ),
                    border: Border.all(
                      color: glow.withValues(alpha: 0.8),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: glow.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: size * 0.1 + lift,
                child: Transform.rotate(
                  angle: math.sin(phase) * 0.06 - 0.08,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: BananaPreview(skin: widget.skin),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
