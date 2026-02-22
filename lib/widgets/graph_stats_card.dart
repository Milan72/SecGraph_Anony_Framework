import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/graph_model.dart';

class GraphStatsCard extends StatelessWidget {
  final GraphModel graph;
  final bool compact;

  const GraphStatsCard({
    super.key,
    required this.graph,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insert_drive_file, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        graph.fileName ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Loaded successfully',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.success,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.success,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ready',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.success,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStat(context, 'Nodes', graph.actualNodeCount.toString(),
                    Icons.circle_outlined),
                _buildStat(context, 'Edges', graph.edgeCount.toString(),
                    Icons.linear_scale),
                _buildStat(context, 'Density', graph.density.toStringAsFixed(4),
                    Icons.blur_on),
                _buildStat(context, 'Avg Degree',
                    graph.averageDegree.toStringAsFixed(2), Icons.hub),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCompactStat(context, 'Nodes', graph.actualNodeCount.toString()),
        _buildCompactStat(context, 'Edges', graph.edgeCount.toString()),
        _buildCompactStat(context, 'Density', graph.density.toStringAsFixed(3)),
      ],
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }
}
