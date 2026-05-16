class BenchmarkResult {
  final double nodePrecision;
  final double nodeRecall;
  final double edgePrecision;
  final double edgeRecall;
  final double structuralSimilarity;
  final int recoveredEdges;
  final int recoveredNodes;

  BenchmarkResult({
    required this.nodePrecision,
    required this.nodeRecall,
    required this.edgePrecision,
    required this.edgeRecall,
    required this.structuralSimilarity,
    required this.recoveredEdges,
    required this.recoveredNodes,
  });

  Map<String, dynamic> toMap() {
    return {
      'nodePrecision': nodePrecision,
      'nodeRecall': nodeRecall,
      'edgePrecision': edgePrecision,
      'edgeRecall': edgeRecall,
      'structuralSimilarity': structuralSimilarity,
      'recoveredEdges': recoveredEdges,
      'recoveredNodes': recoveredNodes,
    };
  }
}