import 'package:flutter/material.dart';

enum MetricType {
  betweennessCentrality,
  closenessCentrality,
  kCore,
  kShell,
}

class MetricModel {
  final MetricType type;
  final String name;
  final String description;
  final String interpretation;
  final IconData icon;
  final Color color;

  const MetricModel({
    required this.type,
    required this.name,
    required this.description,
    required this.interpretation,
    required this.icon,
    required this.color,
  });

  static List<MetricModel> get allMetrics => [
        const MetricModel(
          type: MetricType.betweennessCentrality,
          name: 'Betweenness Centrality',
          description:
              'Measures how many shortest paths pass through each node.',
          interpretation:
              'Higher utility = better preservation of node importance',
          icon: Icons.hub,
          color: Color(0xFF6366F1),
        ),
        const MetricModel(
          type: MetricType.closenessCentrality,
          name: 'Closeness Centrality',
          description: 'Measures average distance from a node to all others.',
          interpretation: 'Higher utility = nodes stay close to network center',
          icon: Icons.center_focus_strong,
          color: Color(0xFFEC4899),
        ),
        const MetricModel(
          type: MetricType.kCore,
          name: 'K-Core',
          description: 'Dense subgraph where all nodes have degree ≥ k.',
          interpretation: 'Higher utility = core structure preserved',
          icon: Icons.hexagon,
          color: Color(0xFFF59E0B),
        ),
        const MetricModel(
          type: MetricType.kShell,
          name: 'K-Shell',
          description:
              'Nodes at specific density layer (in k-core but not (k+1)-core).',
          interpretation: 'Higher utility = layer hierarchy preserved',
          icon: Icons.layers,
          color: Color(0xFF10B981),
        ),
      ];
}
