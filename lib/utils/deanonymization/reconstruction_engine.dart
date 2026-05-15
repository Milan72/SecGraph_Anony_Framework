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
    final existingEdgeKeys = <String>{};

    // Preserve directly exposed edges
    for (final edge in anonymizedGraph.edges) {
      final sourceRisk = highRiskNodes.contains(edge.source);
      final targetRisk = highRiskNodes.contains(edge.target);

      if (sourceRisk || targetRisk) {
        reconstructedEdges.add(edge);

        existingEdgeKeys.add(
          _edgeKey(edge.source, edge.target),
        );
      }
    }

    // Infer likely hidden edges
    final inferredEdges = _inferLikelyEdges(
      anonymizedGraph,
      highRiskNodes,
      existingEdgeKeys,
    );

    reconstructedEdges.addAll(inferredEdges);

    return GraphModel(
      fileName: 'attack_reconstruction_${anonymizedGraph.fileName}',
      nodeCount: anonymizedGraph.nodeCount,
      edges: reconstructedEdges,
    );
  }

  static List<EdgeModel> _inferLikelyEdges(
    GraphModel graph,
    Set<int> highRiskNodes,
    Set<String> existingEdgeKeys,
  ) {
    final adjacency = _buildAdjacency(graph);

    final inferred = <EdgeModel>[];

    final nodes = highRiskNodes.toList();

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final a = nodes[i];
        final b = nodes[j];

        final key = _edgeKey(a, b);

        if (existingEdgeKeys.contains(key)) {
          continue;
        }

        final similarity = _neighborSimilarity(
          adjacency[a] ?? {},
          adjacency[b] ?? {},
        );

        if (similarity >= 0.45) {
          inferred.add(
            EdgeModel(
              source: a,
              target: b,
            ),
          );
        }
      }
    }

    return inferred;
  }

  static double _neighborSimilarity(
    Set<int> a,
    Set<int> b,
  ) {
    if (a.isEmpty || b.isEmpty) {
      return 0.0;
    }

    final intersection = a.intersection(b).length;
    final union = a.union(b).length;

    if (union == 0) {
      return 0.0;
    }

    return intersection / union;
  }

  static Map<int, Set<int>> _buildAdjacency(
    GraphModel graph,
  ) {
    final adjacency = <int, Set<int>>{};

    for (final node in graph.nodes) {
      adjacency[node] = <int>{};
    }

    for (final edge in graph.edges) {
      adjacency.putIfAbsent(edge.source, () => <int>{});
      adjacency.putIfAbsent(edge.target, () => <int>{});

      adjacency[edge.source]!.add(edge.target);
      adjacency[edge.target]!.add(edge.source);
    }

    return adjacency;
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

  static String _edgeKey(int a, int b) {
    final minVal = a < b ? a : b;
    final maxVal = a < b ? b : a;

    return '$minVal-$maxVal';
  }
}