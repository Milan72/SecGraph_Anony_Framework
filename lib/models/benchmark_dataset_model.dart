class BenchmarkDataset {
  final String id;
  final String name;
  final String description;
  final String assetPath;
  final String source;
  final int estimatedNodes;
  final int estimatedEdges;

  const BenchmarkDataset({
    required this.id,
    required this.name,
    required this.description,
    required this.assetPath,
    required this.source,
    required this.estimatedNodes,
    required this.estimatedEdges,
  });
}