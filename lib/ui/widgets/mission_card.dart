import 'package:banana_escape/config/app_colors.dart';
import 'package:banana_escape/models/mission.dart';
import 'package:flutter/material.dart';

class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.mission,
  });

  final MissionProgressView mission;

  @override
  Widget build(BuildContext context) {
    final progress = mission.progress.clamp(0, mission.definition.target);
    final progressRatio = progress / mission.definition.target;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: mission.isComplete
              ? [
                  const Color(0xFFE8FFE2),
                  const Color(0xFFD8F8C8),
                ]
              : [
                  Colors.white.withValues(alpha: 0.96),
                  AppColors.panel.withValues(alpha: 0.95),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mission.definition.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                mission.isComplete ? 'Done' : '$progress/${mission.definition.target}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: mission.isComplete ? AppColors.leafGreen : AppColors.softInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mission.definition.description,
            style: const TextStyle(
              color: AppColors.softInk,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 10,
              backgroundColor: AppColors.panelAlt,
              valueColor: AlwaysStoppedAnimation<Color>(
                mission.isComplete ? AppColors.leafGreen : AppColors.bananaYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
