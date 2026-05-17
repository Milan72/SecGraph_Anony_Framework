import '../models/benchmark_dataset_model.dart';

class BenchmarkDatasetRegistry {
  static const List<BenchmarkDataset> datasets = [
    BenchmarkDataset(
      id: 'soc_dolphins',
      name: 'Dolphins Social Network',
      description:
          'A real social network of bottlenose dolphins, commonly used as a benchmark for community detection and graph structure analysis.',
      assetPath: 'assets/benchmark_graphs/soc-dolphins.mtx',
      source: 'Network Repository',
      estimatedNodes: 62,
      estimatedEdges: 159,
    ),
    BenchmarkDataset(
      id: 'soc_tribes',
      name: 'Tribes Social Network',
      description:
          'A real social network representing relationships between tribes, useful for testing community leakage and structural exposure.',
      assetPath: 'assets/benchmark_graphs/soc-tribes.mtx',
      source: 'Network Repository',
      estimatedNodes: 16,
      estimatedEdges: 58,
    ),
    BenchmarkDataset(
      id: 'soc_firm_hi_tech',
      name: 'High-Tech Firm Social Network',
      description:
          'A real organizational social network from a high-tech firm, useful for studying workplace structure, hubs, and privacy leakage.',
      assetPath: 'assets/benchmark_graphs/soc-firm-hi-tech.mtx',
      source: 'Network Repository',
      estimatedNodes: 33,
      estimatedEdges: 91,
    ),
  ];

  static BenchmarkDataset? findById(String id) {
    for (final dataset in datasets) {
      if (dataset.id == id) {
        return dataset;
      }
    }

    return null;
  }
}