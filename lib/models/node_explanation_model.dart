class NodeExplanation {
  final int nodeId;
  final double riskScore;
  final List<String> reasons;
  final Map<String, String> evidence;

  NodeExplanation({
    required this.nodeId,
    required this.riskScore,
    required this.reasons,
    required this.evidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'nodeId': nodeId,
      'riskScore': riskScore,
      'reasons': reasons,
      'evidence': evidence,
    };
  }
}