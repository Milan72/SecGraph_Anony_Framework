import '../models/benchmark_dataset_model.dart';

class BenchmarkDatasetRegistry {
  static const List<BenchmarkDataset> datasets = [
    BenchmarkDataset(
      id: 'sample_social_graph',
      name: 'Sample Social Network',
      description:
          'A small social-style benchmark graph for testing anonymization, structural attacks, and reconstruction.',
      assetPath: 'assets/benchmark_graphs/sample_social_graph.mtx',
      source: 'Synthetic benchmark inspired by social network topology',
      estimatedNodes: 12,
      estimatedEdges: 18,
    ),
    BenchmarkDataset(
      id: 'sample_email_graph',
      name: 'Sample Email Communication Network',
      description:
          'A compact communication-style graph with hubs and local clusters.',
      assetPath: 'assets/benchmark_graphs/sample_email_graph.mtx',
      source: 'Synthetic benchmark inspired by email communication networks',
      estimatedNodes: 14,
      estimatedEdges: 20,
    ),
    BenchmarkDataset(
      id: 'sample_citation_graph',
      name: 'Sample Citation Network',
      description:
          'A small citation-style graph with directed-like dependency structure represented as undirected edges.',
      assetPath: 'assets/benchmark_graphs/sample_citation_graph.mtx',
      source: 'Synthetic benchmark inspired by citation network structure',
      estimatedNodes: 15,
      estimatedEdges: 19,
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