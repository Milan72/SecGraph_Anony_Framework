import '../../models/attack_pipeline_model.dart';
import '../../models/graph_model.dart';
import 'deanonymization_engine.dart';

class PipelineEngine {
  static AttackPipelineResult runDefaultPipeline(GraphModel anonymizedGraph) {
    final stages = [
      DeanonymizationEngine.degreeUniquenessAttack,
      DeanonymizationEngine.neighborhoodSignatureAttack,
      DeanonymizationEngine.kCoreExposureAttack,
      DeanonymizationEngine.compositeAttack,
    ];

    final stageRisks = <double>[];

    for (final stage in stages) {
      final results = DeanonymizationEngine.runSelectedAttacks(
        anonymizedGraph,
        [stage],
      );

      if (results.isNotEmpty) {
        stageRisks.add(results.first.riskScore);
      } else {
        stageRisks.add(0.0);
      }
    }

    final cumulativeRisk = _calculateCumulativeRisk(stageRisks);

    return AttackPipelineResult(
      stages: stages,
      stageRisks: stageRisks,
      cumulativeRisk: cumulativeRisk,
    );
  }

  static double _calculateCumulativeRisk(List<double> risks) {
    if (risks.isEmpty) return 0.0;

    double survivalPrivacy = 1.0;

    for (final risk in risks) {
      survivalPrivacy *= (1 - risk).clamp(0.0, 1.0);
    }

    return (1 - survivalPrivacy).clamp(0.0, 1.0);
  }
}