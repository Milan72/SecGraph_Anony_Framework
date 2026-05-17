class AttackPipelineResult {
  final List<String> stages;
  final List<double> stageRisks;
  final double cumulativeRisk;

  AttackPipelineResult({
    required this.stages,
    required this.stageRisks,
    required this.cumulativeRisk,
  });

  Map<String, dynamic> toMap() {
    return {
      'stages': stages,
      'stageRisks': stageRisks,
      'cumulativeRisk': cumulativeRisk,
    };
  }
}