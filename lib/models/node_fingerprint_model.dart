class NodeFingerprint {
  final int nodeId;
  final int degree;
  final List<int> neighborDegrees;
  final int twoHopNeighborhoodSize;
  final double clusteringCoefficient;
  final int kCoreEstimate;

  NodeFingerprint({
    required this.nodeId,
    required this.degree,
    required this.neighborDegrees,
    required this.twoHopNeighborhoodSize,
    required this.clusteringCoefficient,
    required this.kCoreEstimate,
  });

  String get signature {
    final sortedNeighborDegrees = [...neighborDegrees]..sort();

    return [
      degree,
      sortedNeighborDegrees.join('-'),
      twoHopNeighborhoodSize,
      clusteringCoefficient.toStringAsFixed(3),
      kCoreEstimate,
    ].join('|');
  }

  Map<String, dynamic> toMap() {
    return {
      'nodeId': nodeId,
      'degree': degree,
      'neighborDegrees': neighborDegrees,
      'twoHopNeighborhoodSize': twoHopNeighborhoodSize,
      'clusteringCoefficient': clusteringCoefficient,
      'kCoreEstimate': kCoreEstimate,
      'signature': signature,
    };
  }
}