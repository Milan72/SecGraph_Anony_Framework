import '../../models/attack_result_model.dart';
import '../../models/graph_model.dart';
import 'fingerprint_extractor.dart';
import 'privacy_risk_scorer.dart';

class DeanonymizationEngine {
  static List<AttackResult> runBlackBoxAttacks(GraphModel anonymizedGraph) {
    final fingerprints = FingerprintExtractor.extract(anonymizedGraph);

    final nodeRiskScores =
        PrivacyRiskScorer.calculateNodeRiskScores(fingerprints);

    final globalRisk =
        PrivacyRiskScorer.calculateGlobalRiskScore(nodeRiskScores);

    final uniquenessScore =
        PrivacyRiskScorer.calculateUniquenessScore(fingerprints);

    final vulnerableNodes =
        PrivacyRiskScorer.extractHighlyVulnerableNodes(nodeRiskScores);

    return [
      AttackResult(
        attackName: 'Structural Fingerprint Attack',
        riskScore: globalRisk,
        uniquenessScore: uniquenessScore,
        vulnerableNodeCount: vulnerableNodes.length,
        vulnerableNodes: vulnerableNodes,
        nodeRiskScores: nodeRiskScores,
      ),
    ];
  }
}