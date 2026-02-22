import 'package:flutter/material.dart';

enum AlgorithmType {
  naive,
  randomAddDelete,
  randomSwitch,
  randomWalk,
}

enum PrivacyLevel { low, medium, high }
enum UtilityLevel { low, medium, high, perfect }

class AlgorithmModel {
  final AlgorithmType type;
  final String name;
  final String shortDescription;
  final String fullDescription;
  final List<String> steps;
  final PrivacyLevel privacy;
  final UtilityLevel utility;
  final String useCase;
  final IconData icon;
  final Color color;
  final bool usesKParameter;

  const AlgorithmModel({
    required this.type,
    required this.name,
    required this.shortDescription,
    required this.fullDescription,
    required this.steps,
    required this.privacy,
    required this.utility,
    required this.useCase,
    required this.icon,
    required this.color,
    this.usesKParameter = true,
  });

  double get privacyValue {
    switch (privacy) {
      case PrivacyLevel.low:
        return 0.2;
      case PrivacyLevel.medium:
        return 0.6;
      case PrivacyLevel.high:
        return 1.0;
    }
  }

  double get utilityValue {
    switch (utility) {
      case UtilityLevel.low:
        return 0.2;
      case UtilityLevel.medium:
        return 0.5;
      case UtilityLevel.high:
        return 0.8;
      case UtilityLevel.perfect:
        return 1.0;
    }
  }

  static List<AlgorithmModel> get allAlgorithms => [
        const AlgorithmModel(
          type: AlgorithmType.naive,
          name: 'Naive Anonymization',
          shortDescription: 'Remove node identities by relabeling',
          fullDescription:
              'Removes node identities by relabeling with generic IDs (0, 1, 2...). '
              'Preserves 100% of graph structure but provides minimal privacy as '
              'structural fingerprints remain.',
          steps: [
            'Load original graph',
            'Create mapping: original_node → generic_id',
            'Relabel all nodes with new IDs',
            'Output anonymized graph',
          ],
          privacy: PrivacyLevel.low,
          utility: UtilityLevel.perfect,
          useCase: 'Baseline for comparison',
          icon: Icons.label_off,
          color: Color(0xFFFFFFE0),
          usesKParameter: false,
        ),
        const AlgorithmModel(
          type: AlgorithmType.randomAddDelete,
          name: 'Random Add/Delete',
          shortDescription: 'Randomly add and delete edges',
          fullDescription:
              'Aggressively modifies graph structure by randomly adding non-existing '
              'edges and deleting existing ones. Each iteration adds 1 random edge '
              'and removes 1 random edge.',
          steps: [
            'Find all possible non-existing edges',
            'Add one random non-existing edge',
            'Delete one random existing edge',
            'Repeat k times',
          ],
          privacy: PrivacyLevel.high,
          utility: UtilityLevel.low,
          useCase: 'Maximum anonymity when utility is less important',
          icon: Icons.add_circle_outline,
          color: Color(0xFFADD8E6),
        ),
        const AlgorithmModel(
          type: AlgorithmType.randomSwitch,
          name: 'Random Switch',
          shortDescription: 'Swap edge endpoints preserving degrees',
          fullDescription:
              'Swaps edge endpoints k times while preserving degree distribution. '
              'Picks two random edges (a,b) and (c,d), removes them, and adds '
              '(a,d) and (b,c) instead.',
          steps: [
            'Pick two random edges (a,b) and (c,d)',
            'Validate: 4 distinct nodes, new edges don\'t exist',
            'Remove (a,b) and (c,d)',
            'Add (a,d) and (b,c)',
            'Repeat k times',
          ],
          privacy: PrivacyLevel.medium,
          utility: UtilityLevel.high,
          useCase: 'Balance privacy and utility, preserve degree distribution',
          icon: Icons.swap_horiz,
          color: Color(0xFF87CEEB),
        ),
        const AlgorithmModel(
          type: AlgorithmType.randomWalk,
          name: 'Random Walk',
          shortDescription: 'Replace edges via random walk endpoint',
          fullDescription:
              'Replaces each edge with a probabilistically similar edge via random '
              'walk. For each edge (u, v), starts a random walk from v, walks k '
              'steps, and replaces the edge with (u, endpoint).',
          steps: [
            'For each edge (u, v):',
            '  Start random walk from v',
            '  Walk k steps randomly',
            '  Reach endpoint x',
            '  Replace (u, v) with (u, x)',
          ],
          privacy: PrivacyLevel.medium,
          utility: UtilityLevel.medium,
          useCase: 'Preserve global structure while disrupting local patterns',
          icon: Icons.directions_walk,
          color: Color(0xFFF08080),
        ),
      ];
}
