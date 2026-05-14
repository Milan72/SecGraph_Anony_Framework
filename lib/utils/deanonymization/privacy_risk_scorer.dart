import '../../models/node_fingerprint_model.dart';

class PrivacyRiskScorer {
  static Map<int, double> calculateNodeRiskScores(
    Map<int, NodeFingerprint> fingerprints,
  ) {
    final signatureCounts = <String, int>{};

    for (final fp in fingerprints.values) {
      signatureCounts[fp.signature] =
          (signatureCounts[fp.signature] ?? 0) + 1;
    }

    final riskScores = <int, double>{};

    for (final fp in fingerprints.values) {
      final frequency = signatureCounts[fp.signature] ?? 1;

      double uniquenessRisk = 1 / frequency;

      uniquenessRisk *= _structuralComplexityBoost(fp);

      riskScores[fp.nodeId] =
          uniquenessRisk.clamp(0.0, 1.0);
    }

    return riskScores;
  }

  static double calculateGlobalRiskScore(
    Map<int, double> nodeRiskScores,
  ) {
    if (nodeRiskScores.isEmpty) return 0.0;

    final total = nodeRiskScores.values
        .reduce((a, b) => a + b);

    return total / nodeRiskScores.length;
  }

  static double calculateUniquenessScore(
    Map<int, NodeFingerprint> fingerprints,
  ) {
    final seen = <String>{};

    for (final fp in fingerprints.values) {
      seen.add(fp.signature);
    }

    return seen.length / fingerprints.length;
  }

  static List<int> extractHighlyVulnerableNodes(
    Map<int, double> nodeRiskScores,
  ) {
    return nodeRiskScores.entries
        .where((entry) => entry.value >= 0.7)
        .map((entry) => entry.key)
        .toList();
  }

  static double _structuralComplexityBoost(
    NodeFingerprint fp,
  ) {
    double boost = 1.0;

    if (fp.degree > 15) {
      boost += 0.15;
    }

    if (fp.kCoreEstimate > 5) {
      boost += 0.15;
    }

    if (fp.twoHopNeighborhoodSize > 25) {
      boost += 0.1;
    }

    return boost;
  }
}