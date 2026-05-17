import 'package:flutter/services.dart';

import '../models/benchmark_dataset_model.dart';
import '../models/graph_model.dart';
import 'mtx_parser.dart';

class BenchmarkDatasetLoader {
  static Future<GraphModel> loadDataset(BenchmarkDataset dataset) async {
    final content = await rootBundle.loadString(dataset.assetPath);

    return MtxParser.parseContent(
      content,
      dataset.name,
    );
  }
}