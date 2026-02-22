import 'dart:math';
import '../models/graph_model.dart';
import '../models/algorithm_model.dart';
import '../models/metric_model.dart';

class GraphAlgorithms {
  static final _random = Random();

  /// Run anonymization algorithm
  static Future<GraphModel> runAlgorithm(
    GraphModel graph,
    AlgorithmType algorithm,
    int k,
  ) async {
    switch (algorithm) {
      case AlgorithmType.naive:
        return _naiveAnonymization(graph);
      case AlgorithmType.randomAddDelete:
        return _randomAddDelete(graph, k);
      case AlgorithmType.randomSwitch:
        return _randomSwitch(graph, k);
      case AlgorithmType.randomWalk:
        return _randomWalk(graph, k);
    }
  }

  /// Naive Anonymization - relabel nodes with generic IDs
  static GraphModel _naiveAnonymization(GraphModel graph) {
    final nodeList = graph.nodes.toList()..sort();
    final mapping = <int, int>{};

    for (var i = 0; i < nodeList.length; i++) {
      mapping[nodeList[i]] = i;
    }

    final newEdges = graph.edges.map((edge) {
      return EdgeModel(
        source: mapping[edge.source]!,
        target: mapping[edge.target]!,
      );
    }).toList();

    return GraphModel(
      fileName: '${graph.fileName}_anonymized',
      nodeCount: graph.nodeCount,
      edges: newEdges,
    );
  }

  /// Random Add/Delete - add random edges and delete random edges
  static GraphModel _randomAddDelete(GraphModel graph, int k) {
    final edges = Set<EdgeModel>.from(graph.edges);
    final nodes = graph.nodes.toList();

    for (var i = 0; i < k; i++) {
      // Find non-existing edge to add
      EdgeModel? newEdge;
      for (var attempt = 0; attempt < 100; attempt++) {
        final u = nodes[_random.nextInt(nodes.length)];
        final v = nodes[_random.nextInt(nodes.length)];
        if (u != v) {
          final candidate = EdgeModel(source: min(u, v), target: max(u, v));
          if (!edges.contains(candidate)) {
            newEdge = candidate;
            break;
          }
        }
      }

      if (newEdge != null) {
        edges.add(newEdge);
      }

      // Delete random edge
      if (edges.isNotEmpty) {
        final edgeList = edges.toList();
        final toRemove = edgeList[_random.nextInt(edgeList.length)];
        edges.remove(toRemove);
      }
    }

    return GraphModel(
      fileName: '${graph.fileName}_randadddel',
      nodeCount: graph.nodeCount,
      edges: edges.toList(),
    );
  }

  /// Random Switch - swap edge endpoints
  static GraphModel _randomSwitch(GraphModel graph, int k) {
    final edges = List<EdgeModel>.from(graph.edges);

    for (var i = 0; i < k; i++) {
      if (edges.length < 2) break;

      // Pick two random edges
      final idx1 = _random.nextInt(edges.length);
      var idx2 = _random.nextInt(edges.length);
      while (idx2 == idx1 && edges.length > 1) {
        idx2 = _random.nextInt(edges.length);
      }

      final e1 = edges[idx1];
      final e2 = edges[idx2];

      final a = e1.source;
      final b = e1.target;
      final c = e2.source;
      final d = e2.target;

      // Check all 4 nodes are distinct
      if ({a, b, c, d}.length < 4) continue;

      // Check new edges don't exist
      final newEdge1 = EdgeModel(source: min(a, d), target: max(a, d));
      final newEdge2 = EdgeModel(source: min(b, c), target: max(b, c));

      if (edges.contains(newEdge1) || edges.contains(newEdge2)) continue;

      // Perform switch
      edges[idx1] = newEdge1;
      edges[idx2] = newEdge2;
    }

    return GraphModel(
      fileName: '${graph.fileName}_randswitch',
      nodeCount: graph.nodeCount,
      edges: edges,
    );
  }

  /// Random Walk - replace edges via random walk endpoint
  static GraphModel _randomWalk(GraphModel graph, int k) {
    // Build adjacency list
    final adjacency = <int, List<int>>{};
    for (final node in graph.nodes) {
      adjacency[node] = [];
    }
    for (final edge in graph.edges) {
      adjacency[edge.source]!.add(edge.target);
      adjacency[edge.target]!.add(edge.source);
    }

    final newEdges = <EdgeModel>[];
    final existingEdges = <String>{};

    for (final edge in graph.edges) {
      final u = edge.source;
      var current = edge.target;

      // Random walk of k steps
      for (var step = 0; step < k; step++) {
        final neighbors = adjacency[current];
        if (neighbors == null || neighbors.isEmpty) break;
        current = neighbors[_random.nextInt(neighbors.length)];
      }

      // Avoid self-loops and duplicates
      if (current != u) {
        final key = '${min(u, current)}-${max(u, current)}';
        if (!existingEdges.contains(key)) {
          newEdges.add(EdgeModel(source: min(u, current), target: max(u, current)));
          existingEdges.add(key);
        }
      }
    }

    return GraphModel(
      fileName: '${graph.fileName}_randomwalk',
      nodeCount: graph.nodeCount,
      edges: newEdges,
    );
  }

  /// Calculate utility metric
  static double calculateMetric(GraphModel graph, MetricType metric, int k) {
    switch (metric) {
      case MetricType.betweennessCentrality:
        return _calculateBetweenness(graph, k);
      case MetricType.closenessCentrality:
        return _calculateCloseness(graph, k);
      case MetricType.kCore:
        return _calculateKCore(graph, k);
      case MetricType.kShell:
        return _calculateKShell(graph, k);
    }
  }

  static double _calculateBetweenness(GraphModel graph, int k) {
    // Simplified betweenness: ratio of nodes with degree >= k
    final degrees = graph.degreeDistribution;
    final surviving = degrees.values.where((d) => d >= k).length;
    return surviving / graph.actualNodeCount;
  }

  static double _calculateCloseness(GraphModel graph, int k) {
    // Simplified: return average degree normalized
    return min(1.0, graph.averageDegree / (graph.actualNodeCount - 1));
  }

  static double _calculateKCore(GraphModel graph, int k) {
    // Calculate k-core size
    final degrees = Map<int, int>.from(graph.degreeDistribution);
    final removed = <int>{};

    bool changed = true;
    while (changed) {
      changed = false;
      for (final node in graph.nodes) {
        if (!removed.contains(node) && (degrees[node] ?? 0) < k) {
          removed.add(node);
          // Update neighbor degrees
          for (final edge in graph.edges) {
            if (edge.source == node && !removed.contains(edge.target)) {
              degrees[edge.target] = (degrees[edge.target] ?? 1) - 1;
            }
            if (edge.target == node && !removed.contains(edge.source)) {
              degrees[edge.source] = (degrees[edge.source] ?? 1) - 1;
            }
          }
          changed = true;
        }
      }
    }

    final coreSize = graph.actualNodeCount - removed.length;
    return coreSize / graph.actualNodeCount;
  }

  static double _calculateKShell(GraphModel graph, int k) {
    // K-shell is nodes in k-core but not (k+1)-core
    final kCoreRatio = _calculateKCore(graph, k);
    final kPlusOneCoreRatio = _calculateKCore(graph, k + 1);
    return max(0, kCoreRatio - kPlusOneCoreRatio);
  }
}
