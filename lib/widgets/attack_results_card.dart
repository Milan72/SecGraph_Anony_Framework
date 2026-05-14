import 'package:flutter/material.dart';

import '../models/attack_result_model.dart';

class AttackResultsCard extends StatelessWidget {
  final AttackResult result;

  const AttackResultsCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final riskPercent =
        (result.riskScore * 100).toStringAsFixed(2);

    final uniquenessPercent =
        (result.uniquenessScore * 100).toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.blueAccent.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.attackName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          _metricTile(
            'Global Privacy Risk',
            '$riskPercent%',
          ),

          _metricTile(
            'Fingerprint Uniqueness',
            '$uniquenessPercent%',
          ),

          _metricTile(
            'Highly Vulnerable Nodes',
            '${result.vulnerableNodeCount}',
          ),

          const SizedBox(height: 18),

          const Text(
            'Top Vulnerable Nodes',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.vulnerableNodes
                .take(20)
                .map(
                  (nodeId) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Node $nodeId',
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}