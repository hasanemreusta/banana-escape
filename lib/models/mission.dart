enum MissionMetric {
  coinsSingleRun,
  distanceSingleRun,
  totalRuns,
}

class MissionDefinition {
  const MissionDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.metric,
  });

  final String id;
  final String title;
  final String description;
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
      title: 'Banana Banker',
      description: 'Collect 20 coins in one run',
      target: 20,
      metric: MissionMetric.coinsSingleRun,
    ),
    MissionDefinition(
      id: 'reach_500_distance',
      title: 'Long Peel',
      description: 'Reach 500 meters',
      target: 500,
      metric: MissionMetric.distanceSingleRun,
    ),
    MissionDefinition(
      id: 'play_3_runs',
      title: 'Warm Up',
      description: 'Play 3 runs',
      target: 3,
      metric: MissionMetric.totalRuns,
    ),
  ];
}
