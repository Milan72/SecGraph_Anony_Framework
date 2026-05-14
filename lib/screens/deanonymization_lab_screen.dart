import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/attack_result_model.dart';
import '../providers/app_provider.dart';
import '../utils/deanonymization/deanonymization_engine.dart';
import '../widgets/attack_results_card.dart';

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

  void _runAttacks(AppProvider provider) {
    if (provider.anonymizedGraph == null || _selectedAttacks.isEmpty) return;

    final results = DeanonymizationEngine.runSelectedAttacks(
      provider.anonymizedGraph!,
      _selectedAttacks.toList(),
    );

    setState(() {
      _results = results;
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
                    'Choose structural attacks to simulate how vulnerable the anonymized graph is to re-identification.',
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
                    onPressed: _selectedAttacks.isEmpty
                        ? null
                        : () => _runAttacks(provider),
                    icon: const Icon(Icons.security),
                    label: const Text('Run Selected Attacks'),
                  ),

                  if (_hasRun) ...[
                    const SizedBox(height: 32),
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
              'This is a black-box evaluation: the system assumes the attacker only sees '
              'the anonymized graph and tries to estimate privacy leakage from structure alone.',
            ),
          ],
        ),
      ),
    );
  }
}