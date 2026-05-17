import '../../models/attack_result_model.dart';
import '../../models/graph_model.dart';
import '../../models/node_fingerprint_model.dart';
import 'attack_explainer.dart';
import 'fingerprint_extractor.dart';
import 'privacy_risk_scorer.dart';

class DeanonymizationEngine {
  static const String structuralFingerprintAttack =
      'Structural Fingerprint Attack';
  static const String degreeUniquenessAttack = 'Degree Uniqueness Attack';
  static const String neighborhoodSignatureAttack =
      'Neighborhood Signature Attack';
  static const String kCoreExposureAttack = 'K-Core Exposure Attack';
  static const String clusteringExposureAttack = 'Clustering Exposure Attack';
  static const String compositeAttack = 'Composite Structural Attack';

  static List<String> get availableAttacks => [
        structuralFingerprintAttack,
        degreeUniquenessAttack,
        neighborhoodSignatureAttack,
        kCoreExposureAttack,
        clusteringExposureAttack,
        compositeAttack,
      ];

  static List<AttackResult> runBlackBoxAttacks(GraphModel anonymizedGraph) {
    return runSelectedAttacks(
      anonymizedGraph,
      [structuralFingerprintAttack],
    );
  }

  static List<AttackResult> runSelectedAttacks(
    GraphModel anonymizedGraph,
    List<String> selectedAttacks,
  ) {
    final fingerprints = FingerprintExtractor.extract(anonymizedGraph);
    final results = <AttackResult>[];

    for (final attack in selectedAttacks) {
      switch (attack) {
        case structuralFingerprintAttack:
          results.add(
            _buildAttackResult(
              attack,
              fingerprints,
              _structuralFingerprintRisk(fingerprints),
            ),
          );
          break;

        case degreeUniquenessAttack:
          results.add(
            _buildAttackResult(
              attack,
              fingerprints,
              _degreeRisk(fingerprints),
            ),
          );
          break;

        case neighborhoodSignatureAttack:
          results.add(
            _buildAttackResult(
              attack,
              fingerprints,
              _neighborhoodRisk(fingerprints),
            ),
          );
          break;

        case kCoreExposureAttack:
          results.add(
            _buildAttackResult(
              attack,
              fingerprints,
              _kCoreRisk(fingerprints),
            ),
          );
          break;

        case clusteringExposureAttack:
          results.add(
            _buildAttackResult(
              attack,
              fingerprints,
              _clusteringRisk(fingerprints),
            ),
          );
          break;

        case compositeAttack:
          results.add(
            _buildAttackResult(
              attack,
              fingerprints,
              _compositeRisk(fingerprints),
            ),
          );
          break;
      }
    }

    return results;
  }

  static AttackResult _buildAttackResult(
    String attackName,
    Map<int, NodeFingerprint> fingerprints,
    Map<int, double> nodeRiskScores,
  ) {
    final globalRisk =
        PrivacyRiskScorer.calculateGlobalRiskScore(nodeRiskScores);

    final uniquenessScore =
        PrivacyRiskScorer.calculateUniquenessScore(fingerprints);

    final vulnerableNodes =
        PrivacyRiskScorer.extractHighlyVulnerableNodes(nodeRiskScores);

    final explanations = AttackExplainer.explainTopRiskNodes(
      fingerprints: fingerprints,
      nodeRiskScores: nodeRiskScores,
    );

    return AttackResult(
      attackName: attackName,
      riskScore: globalRisk,
      uniquenessScore: uniquenessScore,
      vulnerableNodeCount: vulnerableNodes.length,
      vulnerableNodes: vulnerableNodes,
      nodeRiskScores: nodeRiskScores,
      explanations: explanations,
    );
  }

  static Map<int, double> _structuralFingerprintRisk(
    Map<int, NodeFingerprint> fingerprints,
  ) {
    return PrivacyRiskScorer.calculateNodeRiskScores(fingerprints);
  }

  static Map<int, double> _degreeRisk(
    Map<int, NodeFingerprint> fingerprints,
  ) {
    final degreeCounts = <int, int>{};

    for (final fp in fingerprints.values) {
      degreeCounts[fp.degree] = (degreeCounts[fp.degree] ?? 0) + 1;
    }

    return {
      for (final fp in fingerprints.values)
        fp.nodeId: (1 / (degreeCounts[fp.degree] ?? 1)).clamp(0.0, 1.0),
    };
  }

  static Map<int, double> _neighborhoodRisk(
    Map<int, NodeFingerprint> fingerprints,
  ) {
    final patternCounts = <String, int>{};

    for (final fp in fingerprints.values) {
      final pattern = fp.neighborDegrees.join('-');
      patternCounts[pattern] = (patternCounts[pattern] ?? 0) + 1;
    }

    return {
      for (final fp in fingerprints.values)
        fp.nodeId:
            (1 / (patternCounts[fp.neighborDegrees.join('-')] ?? 1))
                .clamp(0.0, 1.0),
    };
  }

  static Map<int, double> _kCoreRisk(
    Map<int, NodeFingerprint> fingerprints,
  ) {
    final maxCore = fingerprints.values
        .map((fp) => fp.kCoreEstimate)
        .fold<int>(0, (a, b) => a > b ? a : b);

    if (maxCore == 0) {
      return {
        for (final fp in fingerprints.values) fp.nodeId: 0.0,
      };
    }

    return {
      for (final fp in fingerprints.values)
        fp.nodeId: (fp.kCoreEstimate / maxCore).clamp(0.0, 1.0),
    };
  }

  static Map<int, double> _clusteringRisk(
    Map<int, NodeFingerprint> fingerprints,
  ) {
    final clusteringCounts = <String, int>{};

    for (final fp in fingerprints.values) {
      final key = fp.clusteringCoefficient.toStringAsFixed(2);
      clusteringCounts[key] = (clusteringCounts[key] ?? 0) + 1;
    }

    return {
      for (final fp in fingerprints.values)
        fp.nodeId:
            (1 /
                    (clusteringCounts[
                            fp.clusteringCoefficient.toStringAsFixed(2)] ??
                        1))
                .clamp(0.0, 1.0),
    };
  }

  static Map<int, double> _compositeRisk(
    Map<int, NodeFingerprint> fingerprints,
  ) {
    final structural = _structuralFingerprintRisk(fingerprints);
    final degree = _degreeRisk(fingerprints);
    final neighborhood = _neighborhoodRisk(fingerprints);
    final kCore = _kCoreRisk(fingerprints);
    final clustering = _clusteringRisk(fingerprints);

    return {
      for (final node in fingerprints.keys)
        node: ((structural[node] ?? 0) * 0.35 +
                (degree[node] ?? 0) * 0.15 +
                (neighborhood[node] ?? 0) * 0.25 +
                (kCore[node] ?? 0) * 0.15 +
                (clustering[node] ?? 0) * 0.10)
            .clamp(0.0, 1.0),
    };
  }
}