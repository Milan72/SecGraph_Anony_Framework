class EdgeModel {
  final int source;
  final int target;

  const EdgeModel({required this.source, required this.target});

  @override
  String toString() => 'Edge($source, $target)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdgeModel &&
          runtimeType == other.runtimeType &&
          ((source == other.source && target == other.target) ||
              (source == other.target && target == other.source));

  @override
  int get hashCode => source.hashCode ^ target.hashCode;
}

class GraphModel {
  final String? fileName;
  final int nodeCount;
  final List<EdgeModel> edges;
  final Set<int> nodes;

  GraphModel({
    this.fileName,
    required this.nodeCount,
    required this.edges,
  }) : nodes = _extractNodes(edges);

  static Set<int> _extractNodes(List<EdgeModel> edges) {
    final nodes = <int>{};
    for (final edge in edges) {
      nodes.add(edge.source);
      nodes.add(edge.target);
    }
    return nodes;
  }

  int get edgeCount => edges.length;
  int get actualNodeCount => nodes.length;

  double get density {
    if (actualNodeCount <= 1) return 0;
    final maxEdges = actualNodeCount * (actualNodeCount - 1) / 2;
    return edgeCount / maxEdges;
  }

  Map<int, int> get degreeDistribution {
    final degrees = <int, int>{};
    for (final node in nodes) {
      degrees[node] = 0;
    }
    for (final edge in edges) {
      degrees[edge.source] = (degrees[edge.source] ?? 0) + 1;
      degrees[edge.target] = (degrees[edge.target] ?? 0) + 1;
    }
    return degrees;
  }

  double get averageDegree {
    if (nodes.isEmpty) return 0;
    final degrees = degreeDistribution;
    final sum = degrees.values.fold(0, (a, b) => a + b);
    return sum / nodes.length;
  }

  GraphModel copyWith({
    String? fileName,
    int? nodeCount,
    List<EdgeModel>? edges,
  }) {
    return GraphModel(
      fileName: fileName ?? this.fileName,
      nodeCount: nodeCount ?? this.nodeCount,
      edges: edges ?? this.edges,
    );
  }
}
