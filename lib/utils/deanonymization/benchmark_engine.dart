import '../../models/benchmark_result_model.dart';
import '../../models/graph_model.dart';

class BenchmarkEngine {
  static BenchmarkResult evaluate({
    required GraphModel originalGraph,
    required GraphModel reconstructedGraph,
  }) {
    final originalNodes = originalGraph.nodes.toSet();
    final reconstructedNodes = reconstructedGraph.nodes.toSet();

    final originalEdges = _edgeSet(originalGraph);
    final reconstructedEdges = _edgeSet(reconstructedGraph);

    final recoveredNodes =
        originalNodes.intersection(reconstructedNodes).length;

    final recoveredEdges =
        originalEdges.intersection(reconstructedEdges).length;

    final nodePrecision = reconstructedNodes.isEmpty
        ? 0.0
        : recoveredNodes / reconstructedNodes.length;

    final nodeRecall = originalNodes.isEmpty
        ? 0.0
        : recoveredNodes / originalNodes.length;

    final edgePrecision = reconstructedEdges.isEmpty
        ? 0.0
        : recoveredEdges / reconstructedEdges.length;

    final edgeRecall = originalEdges.isEmpty
        ? 0.0
        : recoveredEdges / originalEdges.length;

    final structuralSimilarity = _jaccardSimilarity(
      originalEdges,
      reconstructedEdges,
    );

    return BenchmarkResult(
      nodePrecision: nodePrecision,
      nodeRecall: nodeRecall,
      edgePrecision: edgePrecision,
      edgeRecall: edgeRecall,
      structuralSimilarity: structuralSimilarity,
      recoveredEdges: recoveredEdges,
      recoveredNodes: recoveredNodes,
    );
  }

  static Set<String> _edgeSet(GraphModel graph) {
    return graph.edges.map((edge) {
      final a = edge.source < edge.target ? edge.source : edge.target;
      final b = edge.source < edge.target ? edge.target : edge.source;

      return '$a-$b';
    }).toSet();
  }

  static double _jaccardSimilarity(
    Set<String> a,
    Set<String> b,
  ) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final intersection = a.intersection(b).length;
    final union = a.union(b).length;

    return intersection / union;
  }
}