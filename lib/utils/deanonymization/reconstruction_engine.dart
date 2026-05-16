import '../../models/attack_result_model.dart';
import '../../models/graph_model.dart';
import '../../models/inferred_edge_model.dart';

class ReconstructionEngine {
  static List<InferredEdge> generateInferredEdges({
    required GraphModel anonymizedGraph,
    required List<AttackResult> attackResults,
  }) {
    final highRiskNodes = _collectHighRiskNodes(attackResults);

    if (highRiskNodes.isEmpty) {
      return [];
    }

    final existingEdgeKeys = <String>{};

    for (final edge in anonymizedGraph.edges) {
      existingEdgeKeys.add(_edgeKey(edge.source, edge.target));
    }

    return _inferLikelyEdges(
      anonymizedGraph,
      highRiskNodes,
      existingEdgeKeys,
    );
  }

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

    for (final edge in anonymizedGraph.edges) {
      final sourceRisk = highRiskNodes.contains(edge.source);
      final targetRisk = highRiskNodes.contains(edge.target);

      if (sourceRisk || targetRisk) {
        reconstructedEdges.add(edge);
        existingEdgeKeys.add(_edgeKey(edge.source, edge.target));
      }
    }

    final inferredEdges = _inferLikelyEdges(
      anonymizedGraph,
      highRiskNodes,
      existingEdgeKeys,
    );

    for (final edge in inferredEdges) {
      reconstructedEdges.add(
        EdgeModel(
          source: edge.source,
          target: edge.target,
        ),
      );
    }

    return GraphModel(
      fileName: 'attack_reconstruction_${anonymizedGraph.fileName}',
      nodeCount: anonymizedGraph.nodeCount,
      edges: reconstructedEdges,
    );
  }

  static List<InferredEdge> _inferLikelyEdges(
    GraphModel graph,
    Set<int> highRiskNodes,
    Set<String> existingEdgeKeys,
  ) {
    final adjacency = _buildAdjacency(graph);
    final inferred = <InferredEdge>[];
    final nodes = highRiskNodes.toList();

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final a = nodes[i];
        final b = nodes[j];
        final key = _edgeKey(a, b);

        if (existingEdgeKeys.contains(key)) {
          continue;
        }

        final overlap = _neighborSimilarity(
          adjacency[a] ?? {},
          adjacency[b] ?? {},
        );

        if (overlap >= 0.45) {
          final confidence = _calculateConfidence(overlap);

          inferred.add(
            InferredEdge(
              source: a,
              target: b,
              confidence: confidence,
              neighborhoodOverlap: overlap,
              reasoning: _buildReasoning(overlap, confidence),
            ),
          );
        }
      }
    }

    inferred.sort((a, b) => b.confidence.compareTo(a.confidence));

    return inferred;
  }

  static double _calculateConfidence(double overlap) {
    if (overlap >= 0.75) return 0.95;
    if (overlap >= 0.60) return 0.85;
    if (overlap >= 0.45) return 0.70;
    return 0.0;
  }

  static List<String> _buildReasoning(
    double overlap,
    double confidence,
  ) {
    final reasons = <String>[];

    reasons.add(
      'Nodes share ${(overlap * 100).toStringAsFixed(1)}% neighborhood overlap.',
    );

    if (confidence >= 0.90) {
      reasons.add('Very strong structural similarity suggests a likely hidden relationship.');
    } else if (confidence >= 0.80) {
      reasons.add('Strong local topology similarity supports edge inference.');
    } else {
      reasons.add('Moderate shared-neighborhood evidence supports possible edge inference.');
    }

    reasons.add(
      'Both nodes appear in high-risk exposed regions of the anonymized graph.',
    );

    return reasons;
  }

  static Map<int, Set<int>> _buildAdjacency(GraphModel graph) {
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
    if (anonymizedGraph.edgeCount == 0) return 0.0;

    return reconstructedGraph.edgeCount / anonymizedGraph.edgeCount;
  }

  static double calculateNodeRecoveryScore({
    required GraphModel anonymizedGraph,
    required GraphModel reconstructedGraph,
  }) {
    if (anonymizedGraph.actualNodeCount == 0) return 0.0;

    return reconstructedGraph.actualNodeCount / anonymizedGraph.actualNodeCount;
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