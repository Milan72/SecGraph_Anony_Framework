class InferredEdge {
  final int source;
  final int target;
  final double confidence;
  final double neighborhoodOverlap;
  final List<String> reasoning;

  InferredEdge({
    required this.source,
    required this.target,
    required this.confidence,
    required this.neighborhoodOverlap,
    required this.reasoning,
  });

  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'target': target,
      'confidence': confidence,
      'neighborhoodOverlap': neighborhoodOverlap,
      'reasoning': reasoning,
    };
  }
}