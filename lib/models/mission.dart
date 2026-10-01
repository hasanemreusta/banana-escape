import 'package:banana_escape/l10n/strings.dart';

enum MissionMetric {
  coinsSingleRun,
  distanceSingleRun,
  totalRuns,
}

class MissionDefinition {
  const MissionDefinition({
    required this.id,
    required this.target,
    required this.metric,
  });

  final String id;
  String get title => S.current.missionTitle(id);
  String get description => S.current.missionDescription(id);

  final int target;
  final MissionMetric metric;
}

class MissionProgressView {
  const MissionProgressView({
    required this.definition,
    required this.progress,
  });

  final MissionDefinition definition;
  final int progress;

  bool get isComplete => progress >= definition.target;
}

class Missions {
  const Missions._();

  static const List<MissionDefinition> all = [
    MissionDefinition(
      id: 'collect_20_in_run',
      target: 20,
      metric: MissionMetric.coinsSingleRun,
    ),
    MissionDefinition(
      id: 'reach_500_distance',
      target: 500,
      metric: MissionMetric.distanceSingleRun,
    ),
    MissionDefinition(
      id: 'play_3_runs',
      target: 3,
      metric: MissionMetric.totalRuns,
    ),
  ];
}
