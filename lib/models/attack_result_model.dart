class AttackResult {
  final String attackName;
  final double riskScore;
  final double uniquenessScore;
  final int vulnerableNodeCount;
  final List<int> vulnerableNodes;
  final Map<int, double> nodeRiskScores;

  AttackResult({
    required this.attackName,
    required this.riskScore,
    required this.uniquenessScore,
    required this.vulnerableNodeCount,
    required this.vulnerableNodes,
    required this.nodeRiskScores,
  });

  Map<String, dynamic> toMap() {
    return {
      'attackName': attackName,
      'riskScore': riskScore,
      'uniquenessScore': uniquenessScore,
      'vulnerableNodeCount': vulnerableNodeCount,
      'vulnerableNodes': vulnerableNodes,
      'nodeRiskScores': nodeRiskScores,
    };
  }
}