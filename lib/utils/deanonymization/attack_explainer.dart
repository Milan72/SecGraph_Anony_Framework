import '../../models/node_explanation_model.dart';
import '../../models/node_fingerprint_model.dart';

class AttackExplainer {
  static List<NodeExplanation> explainTopRiskNodes({
    required Map<int, NodeFingerprint> fingerprints,
    required Map<int, double> nodeRiskScores,
    int limit = 8,
  }) {
    final sortedNodes = nodeRiskScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedNodes.take(limit).map((entry) {
      final nodeId = entry.key;
      final riskScore = entry.value;
      final fp = fingerprints[nodeId];

      if (fp == null) {
        return NodeExplanation(
          nodeId: nodeId,
          riskScore: riskScore,
          reasons: const ['Fingerprint data unavailable.'],
          evidence: const {},
        );
      }

      final reasons = <String>[];
      final evidence = <String, String>{};

      if (fp.degree >= 10) {
        reasons.add('High-degree node may remain structurally identifiable.');
        evidence['Degree'] = '${fp.degree} connections';
      } else if (fp.degree <= 1) {
        reasons.add('Extremely low-degree node may be easy to isolate.');
        evidence['Degree'] = '${fp.degree} connection(s)';
      } else {
        evidence['Degree'] = '${fp.degree} connections';
      }

      if (fp.neighborDegrees.isNotEmpty) {
        final neighborPattern = fp.neighborDegrees.join(', ');

        reasons.add('Neighbor-degree pattern creates a structural signature.');
        evidence['Neighbor Pattern'] = '[$neighborPattern]';
      }

      if (fp.twoHopNeighborhoodSize >= 15) {
        reasons.add('Large two-hop neighborhood increases exposure.');
        evidence['Two-Hop Neighborhood'] =
            '${fp.twoHopNeighborhoodSize} reachable nodes';
      } else {
        evidence['Two-Hop Neighborhood'] =
            '${fp.twoHopNeighborhoodSize} reachable nodes';
      }

      if (fp.kCoreEstimate >= 3) {
        reasons.add('Node remains embedded in a dense k-core region.');
        evidence['K-Core Estimate'] = '${fp.kCoreEstimate}';
      } else {
        evidence['K-Core Estimate'] = '${fp.kCoreEstimate}';
      }

      if (fp.clusteringCoefficient > 0.4) {
        reasons.add('Distinctive local clustering may expose community structure.');
        evidence['Clustering'] =
            fp.clusteringCoefficient.toStringAsFixed(3);
      } else {
        evidence['Clustering'] =
            fp.clusteringCoefficient.toStringAsFixed(3);
      }

      if (riskScore >= 0.85) {
        reasons.insert(0, 'Very high uniqueness score across selected attack features.');
      } else if (riskScore >= 0.7) {
        reasons.insert(0, 'High structural uniqueness detected.');
      }

      if (reasons.isEmpty) {
        reasons.add('Moderate structural risk based on combined graph features.');
      }

      return NodeExplanation(
        nodeId: nodeId,
        riskScore: riskScore,
        reasons: reasons,
        evidence: evidence,
      );
    }).toList();
  }
}