import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/attack_result_model.dart';
import '../models/inferred_edge_model.dart';
import '../providers/app_provider.dart';
import '../utils/deanonymization/deanonymization_engine.dart';
import '../widgets/attack_results_card.dart';
import '../widgets/graph_stats_card.dart';
import '../widgets/graph_visualizer.dart';

class DeanonymizationLabScreen extends StatefulWidget {
  const DeanonymizationLabScreen({super.key});

  @override
  State<DeanonymizationLabScreen> createState() =>
      _DeanonymizationLabScreenState();
}

class _DeanonymizationLabScreenState extends State<DeanonymizationLabScreen> {
  final Set<String> _selectedAttacks = {
    DeanonymizationEngine.compositeAttack,
  };

  List<AttackResult> _results = [];
  bool _hasRun = false;

  void _toggleAttack(String attack) {
    setState(() {
      if (_selectedAttacks.contains(attack)) {
        _selectedAttacks.remove(attack);
      } else {
        _selectedAttacks.add(attack);
      }
    });
  }

  Future<void> _runAttacks(AppProvider provider) async {
    if (provider.anonymizedGraph == null || _selectedAttacks.isEmpty) return;

    await provider.runSelectedDeanonymizationAttacks(
      _selectedAttacks.toList(),
    );

    setState(() {
      _results = provider.attackResults;
      _hasRun = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('De-Anonymization Lab'),
      ),
      body: provider.anonymizedGraph == null
          ? const Center(
              child: Text('No anonymized graph available.'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adversarial Privacy Evaluation',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose structural attacks to test how vulnerable the anonymized graph is to re-identification.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 28),
                  _buildGraphSummary(provider),
                  const SizedBox(height: 28),

                  Text(
                    'Attack Selection',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),

                  ...DeanonymizationEngine.availableAttacks.map(
                    (attack) => _buildAttackOption(attack),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: provider.isProcessing || _selectedAttacks.isEmpty
                        ? null
                        : () => _runAttacks(provider),
                    icon: const Icon(Icons.security),
                    label: Text(
                      provider.isProcessing
                          ? 'Running Attacks...'
                          : 'Run Selected Attacks',
                    ),
                  ),

                  if (_hasRun) ...[
                    const SizedBox(height: 32),
                    _buildAttackDashboard(context),
                    const SizedBox(height: 32),
                    _buildReconstructionSummary(context, provider),
                    const SizedBox(height: 32),

                    if (provider.hasInferredEdges) ...[
                      _buildInferredEdgesPanel(context, provider),
                      const SizedBox(height: 32),
                    ],

                    if (provider.hasReconstructedGraph) ...[
                      Text(
                        'Graph Reconstruction Comparison',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This compares the anonymized graph against the attacker-side reconstruction inferred from high-risk structural leakage.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildReconstructionComparison(context, provider),
                      const SizedBox(height: 32),
                    ],

                    Text(
                      'Attack Results',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Higher risk means more structural uniqueness and greater re-identification exposure.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),

                    ..._results.map(
                      (result) => AttackResultsCard(result: result),
                    ),

                    const SizedBox(height: 24),
                    _buildInterpretationPanel(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildGraphSummary(AppProvider provider) {
    final graph = provider.anonymizedGraph!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.hub, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Analyzing anonymized graph with '
                '${graph.actualNodeCount} nodes and ${graph.edgeCount} edges.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttackOption(String attack) {
    final selected = _selectedAttacks.contains(attack);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: CheckboxListTile(
        value: selected,
        onChanged: (_) => _toggleAttack(attack),
        title: Text(attack),
        subtitle: Text(_attackDescription(attack)),
      ),
    );
  }

  Widget _buildAttackDashboard(BuildContext context) {
    final highestRiskAttack = _results.reduce(
      (a, b) => a.riskScore >= b.riskScore ? a : b,
    );

    final averageRisk = _results.isEmpty
        ? 0.0
        : _results
                .map((result) => result.riskScore)
                .reduce((a, b) => a + b) /
            _results.length;

    final totalVulnerableNodes = _results.fold<int>(
      0,
      (sum, result) => sum + result.vulnerableNodeCount,
    );

    final severity = _riskSeverity(averageRisk);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attack Comparison Dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Summary of how selected attacks performed against the anonymized graph.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _dashboardTile(
                  'Average Risk',
                  '${(averageRisk * 100).toStringAsFixed(2)}%',
                  severity,
                ),
                _dashboardTile(
                  'Highest-Risk Attack',
                  highestRiskAttack.attackName,
                  'Most Exposing',
                ),
                _dashboardTile(
                  'Highest Risk Score',
                  '${(highestRiskAttack.riskScore * 100).toStringAsFixed(2)}%',
                  'Peak Leakage',
                ),
                _dashboardTile(
                  'Total Vulnerable Hits',
                  '$totalVulnerableNodes',
                  'Across Attacks',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildComparisonTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildReconstructionSummary(
    BuildContext context,
    AppProvider provider,
  ) {
    final reconstructed = provider.reconstructedGraph;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attack-Reconstructed Graph Preview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The framework builds a partial reconstruction from exposed high-risk nodes and their leaked structural neighborhoods.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 20),
            if (reconstructed == null)
              const Text('No reconstructed graph generated.')
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _dashboardTile(
                    'Recovered Nodes',
                    '${reconstructed.actualNodeCount}',
                    'Nodes present in reconstruction',
                  ),
                  _dashboardTile(
                    'Recovered Edges',
                    '${reconstructed.edgeCount}',
                    'Edges inferred from leakage',
                  ),
                  _dashboardTile(
                    'Structural Recovery',
                    '${(provider.structuralRecoveryScore * 100).toStringAsFixed(2)}%',
                    'Relative to anonymized graph',
                  ),
                  _dashboardTile(
                    'Node Recovery',
                    '${(provider.nodeRecoveryScore * 100).toStringAsFixed(2)}%',
                    'Relative to anonymized graph',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInferredEdgesPanel(
    BuildContext context,
    AppProvider provider,
  ) {
    final topEdges = provider.inferredEdges.take(8).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Inferred Relationships',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'These are relationships the attacker-side reconstruction inferred from shared structural exposure and neighborhood overlap.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 18),
            ...topEdges.map(_buildInferredEdgeTile),
          ],
        ),
      ),
    );
  }

  Widget _buildInferredEdgeTile(InferredEdge edge) {
    final confidence = (edge.confidence * 100).toStringAsFixed(1);
    final overlap = (edge.neighborhoodOverlap * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: Colors.orangeAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Node ${edge.source} ↔ Node ${edge.target}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '$confidence% confidence',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Neighborhood overlap: $overlap%',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...edge.reasoning.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Colors.white70)),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReconstructionComparison(
    BuildContext context,
    AppProvider provider,
  ) {
    final anonymized = provider.anonymizedGraph!;
    final reconstructed = provider.reconstructedGraph!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 850;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildGraphPanel(
                  context,
                  'Anonymized Graph',
                  anonymized,
                  AppTheme.randomWalkColor,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildGraphPanel(
                  context,
                  'Attack-Reconstructed Graph',
                  reconstructed,
                  Colors.orangeAccent,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildGraphPanel(
              context,
              'Anonymized Graph',
              anonymized,
              AppTheme.randomWalkColor,
            ),
            const SizedBox(height: 24),
            _buildGraphPanel(
              context,
              'Attack-Reconstructed Graph',
              reconstructed,
              Colors.orangeAccent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGraphPanel(
    BuildContext context,
    String title,
    dynamic graph,
    Color nodeColor,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: nodeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: GraphVisualizer(
                graph: graph,
                nodeColor: nodeColor,
              ),
            ),
            const Divider(),
            GraphStatsCard(graph: graph, compact: true),
          ],
        ),
      ),
    );
  }

  Widget _dashboardTile(String title, String value, String subtitle) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.displayColor.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Column(
      children: [
        _comparisonRow(
          'Attack',
          'Risk',
          'Unique',
          'Vulnerable',
          isHeader: true,
        ),
        const Divider(),
        ..._results.map(
          (result) => _comparisonRow(
            result.attackName,
            '${(result.riskScore * 100).toStringAsFixed(1)}%',
            '${(result.uniquenessScore * 100).toStringAsFixed(1)}%',
            result.vulnerableNodeCount.toString(),
          ),
        ),
      ],
    );
  }

  Widget _comparisonRow(
    String attack,
    String risk,
    String unique,
    String vulnerable, {
    bool isHeader = false,
  }) {
    final style = TextStyle(
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      color: isHeader ? Colors.white : AppTheme.textSecondary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(attack, style: style)),
          Expanded(child: Text(risk, style: style)),
          Expanded(child: Text(unique, style: style)),
          Expanded(child: Text(vulnerable, style: style)),
        ],
      ),
    );
  }

  String _riskSeverity(double score) {
    if (score >= 0.75) return 'Severe Exposure';
    if (score >= 0.50) return 'High Exposure';
    if (score >= 0.25) return 'Moderate Exposure';
    return 'Low Exposure';
  }

  String _attackDescription(String attack) {
    switch (attack) {
      case DeanonymizationEngine.degreeUniquenessAttack:
        return 'Identifies nodes that stand out because of rare or unique degree values.';
      case DeanonymizationEngine.neighborhoodSignatureAttack:
        return 'Uses neighbor-degree patterns to detect structurally identifiable nodes.';
      case DeanonymizationEngine.kCoreExposureAttack:
        return 'Measures whether high-core nodes remain exposed after anonymization.';
      case DeanonymizationEngine.clusteringExposureAttack:
        return 'Checks whether local triangle structure creates identifiable fingerprints.';
      case DeanonymizationEngine.compositeAttack:
        return 'Combines degree, neighborhood, k-core, clustering, and fingerprint risk.';
      default:
        return 'Uses full structural fingerprints to estimate black-box re-identification risk.';
    }
  }

  Widget _buildInterpretationPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'How to Interpret This',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'A high score does not mean the original identity is fully recovered. '
              'It means the anonymized graph still contains rare structural patterns '
              'that could help an attacker narrow down or re-identify nodes.',
            ),
            SizedBox(height: 10),
            Text(
              'The reconstructed graph is not the true original graph. It is a partial '
              'attacker-side reconstruction built from exposed high-risk structure.',
            ),
          ],
        ),
      ),
    );
  }
}