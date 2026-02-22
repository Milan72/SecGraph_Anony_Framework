import 'dart:io';
import '../models/graph_model.dart';

class MtxParser {
  /// Parse MTX file from path
  static Future<GraphModel> parseFile(String path, String fileName) async {
    final file = File(path);
    final content = await file.readAsString();
    return parseContent(content, fileName);
  }

  /// Parse MTX content string
  static GraphModel parseContent(String content, String fileName) {
    final lines = content.split('\n');
    final edges = <EdgeModel>[];
    bool headerParsed = false;
    int numNodes = 0;

    for (var line in lines) {
      line = line.trim();

      // Skip empty lines and comments
      if (line.isEmpty || line.startsWith('%')) continue;

      final parts = line.split(RegExp(r'\s+'));

      if (!headerParsed) {
        // First non-comment line is header: rows cols edges
        if (parts.length >= 3) {
          numNodes = int.tryParse(parts[0]) ?? 0;
          // parts[1] is cols (same as rows for square matrix)
          // parts[2] is number of edges (we'll count actual edges)
        }
        headerParsed = true;
        continue;
      }

      // Edge data: source target [weight]
      if (parts.length >= 2) {
        final source = int.tryParse(parts[0]);
        final target = int.tryParse(parts[1]);

        if (source != null && target != null) {
          edges.add(EdgeModel(source: source, target: target));
        }
      }
    }

    return GraphModel(
      fileName: fileName,
      nodeCount: numNodes,
      edges: edges,
    );
  }

  /// Generate MTX content from graph
  static String generateMtx(GraphModel graph, {String? comment}) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('%%MatrixMarket matrix coordinate pattern symmetric');

    if (comment != null) {
      buffer.writeln('% $comment');
    }

    // Dimensions: rows cols edges
    final maxNode = graph.nodes.isEmpty ? 0 : graph.nodes.reduce((a, b) => a > b ? a : b);
    buffer.writeln('$maxNode $maxNode ${graph.edgeCount}');

    // Edges
    for (final edge in graph.edges) {
      buffer.writeln('${edge.source} ${edge.target}');
    }

    return buffer.toString();
  }
}
