import '../../models/graph_model.dart';
import '../../models/node_fingerprint_model.dart';

class FingerprintExtractor {
  static Map<int, NodeFingerprint> extract(GraphModel graph) {
    final adjacency = _buildAdjacency(graph);
    final degrees = graph.degreeDistribution;
    final kCoreEstimates = _estimateKCoreValues(adjacency);

    final fingerprints = <int, NodeFingerprint>{};

    for (final node in graph.nodes) {
      final neighbors = adjacency[node] ?? <int>{};

      final neighborDegrees = neighbors
          .map((neighbor) => degrees[neighbor] ?? 0)
          .toList()
        ..sort();

      final twoHopSize = _calculateTwoHopNeighborhoodSize(
        node,
        adjacency,
      );

      final clustering = _calculateClusteringCoefficient(
        node,
        adjacency,
      );

      fingerprints[node] = NodeFingerprint(
        nodeId: node,
        degree: degrees[node] ?? 0,
        neighborDegrees: neighborDegrees,
        twoHopNeighborhoodSize: twoHopSize,
        clusteringCoefficient: clustering,
        kCoreEstimate: kCoreEstimates[node] ?? 0,
      );
    }

    return fingerprints;
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

  static int _calculateTwoHopNeighborhoodSize(
    int node,
    Map<int, Set<int>> adjacency,
  ) {
    final oneHop = adjacency[node] ?? <int>{};
    final twoHop = <int>{};

    for (final neighbor in oneHop) {
      twoHop.addAll(adjacency[neighbor] ?? <int>{});
    }

    twoHop.remove(node);
    twoHop.removeAll(oneHop);

    return twoHop.length;
  }

  static double _calculateClusteringCoefficient(
    int node,
    Map<int, Set<int>> adjacency,
  ) {
    final neighbors = adjacency[node] ?? <int>{};

    if (neighbors.length < 2) {
      return 0.0;
    }

    int existingLinks = 0;
    final neighborList = neighbors.toList();

    for (int i = 0; i < neighborList.length; i++) {
      for (int j = i + 1; j < neighborList.length; j++) {
        final a = neighborList[i];
        final b = neighborList[j];

        if (adjacency[a]?.contains(b) == true) {
          existingLinks++;
        }
      }
    }

    final possibleLinks = neighbors.length * (neighbors.length - 1) / 2;

    return existingLinks / possibleLinks;
  }

  static Map<int, int> _estimateKCoreValues(
    Map<int, Set<int>> adjacency,
  ) {
    final remaining = <int, Set<int>>{};

    adjacency.forEach((node, neighbors) {
      remaining[node] = Set<int>.from(neighbors);
    });

    final coreValues = <int, int>{};
    int currentK = 0;

    while (remaining.isNotEmpty) {
      bool removedAny = false;

      final nodesToRemove = remaining.entries
          .where((entry) => entry.value.length <= currentK)
          .map((entry) => entry.key)
          .toList();

      if (nodesToRemove.isNotEmpty) {
        removedAny = true;

        for (final node in nodesToRemove) {
          coreValues[node] = currentK;
          remaining.remove(node);

          for (final neighbors in remaining.values) {
            neighbors.remove(node);
          }
        }
      }

      if (!removedAny) {
        currentK++;
      }
    }

    return coreValues;
  }
}