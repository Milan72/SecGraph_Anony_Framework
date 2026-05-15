import '../../models/attack_result_model.dart';
import '../../models/graph_model.dart';

class ReconstructionEngine {
  static GraphModel buildReconstructedGraph({
    required GraphModel anonymizedGraph,
    required List<AttackResult> attackResults,
  }) {
    final highRiskNodes = _collectHighRiskNodes(attackResults);

    if (highRiskNodes.isEmpty) {
      return GraphModel(
        fileName: 'attack_reconstruction_${anonymizedGraph.fileName}',
        nodeCount: anonymizedGraph.nodeCount,
        edges: [],
      );
    }

    final reconstructedEdges = <EdgeModel>[];

    for (final edge in anonymizedGraph.edges) {
      final sourceRisk = highRiskNodes.contains(edge.source);
      final targetRisk = highRiskNodes.contains(edge.target);

      if (sourceRisk || targetRisk) {
        reconstructedEdges.add(
          EdgeModel(
            source: edge.source,
            target: edge.target,
          ),
        );
      }
    }

    return GraphModel(
      fileName: 'attack_reconstruction_${anonymizedGraph.fileName}',
      nodeCount: anonymizedGraph.nodeCount,
      edges: reconstructedEdges,
    );
  }

  static double calculateStructuralRecoveryScore({
    required GraphModel anonymizedGraph,
    required GraphModel reconstructedGraph,
  }) {
    if (anonymizedGraph.edgeCount == 0) {
      return 0.0;
    }

    return reconstructedGraph.edgeCount /
        anonymizedGraph.edgeCount;
  }

  static double calculateNodeRecoveryScore({
    required GraphModel anonymizedGraph,
    required GraphModel reconstructedGraph,
  }) {
    if (anonymizedGraph.actualNodeCount == 0) {
      return 0.0;
    }

    return reconstructedGraph.actualNodeCount /
        anonymizedGraph.actualNodeCount;
  }

  static Set<int> _collectHighRiskNodes(
    List<AttackResult> attackResults,
  ) {
    final nodes = <int>{};

    for (final result in attackResults) {
      nodes.addAll(result.vulnerableNodes);

      for (final entry in result.nodeRiskScores.entries) {
        if (entry.value >= 0.70) {
          nodes.add(entry.key);
        }
      }
    }

    return nodes;
  }
}