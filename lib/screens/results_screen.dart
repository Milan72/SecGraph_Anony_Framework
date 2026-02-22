import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/metric_model.dart';
import '../providers/app_provider.dart';
import '../widgets/graph_stats_card.dart';
import '../widgets/graph_visualizer.dart';
import '../widgets/metric_result_card.dart';
import '../utils/mtx_parser.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anonymization Results'),
        actions: [
          TextButton.icon(
            onPressed: () => _downloadResult(context),
            icon: const Icon(Icons.download),
            label: const Text('Export MTX'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {
              context.read<AppProvider>().reset();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Start Over'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.anonymizedGraph == null) {
            return const Center(child: Text('No results available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Success Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.success),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anonymization Complete!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppTheme.success),
                            ),
                            Text(
                              'Applied ${provider.selectedAlgorithms.length} algorithm(s) with k=${provider.kValue}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Graph Comparison
                Text(
                  'Graph Comparison',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildGraphPanel(
                              context,
                              'Original Graph',
                              provider.originalGraph!,
                              AppTheme.displayColor,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildGraphPanel(
                              context,
                              'Anonymized Graph',
                              provider.anonymizedGraph!,
                              AppTheme.randomWalkColor,
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _buildGraphPanel(
                          context,
                          'Original Graph',
                          provider.originalGraph!,
                          AppTheme.displayColor,
                        ),
                        const SizedBox(height: 24),
                        _buildGraphPanel(
                          context,
                          'Anonymized Graph',
                          provider.anonymizedGraph!,
                          AppTheme.randomWalkColor,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Statistics Comparison
                Text(
                  'Statistics Comparison',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                _buildStatsComparison(context, provider),

                // Metrics Results
                if (provider.metricResults.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Utility Metrics',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildMetricResults(context, provider),
                ],

                const SizedBox(height: 48),

                // Action Buttons
                Center(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Settings'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _downloadResult(context),
                        icon: const Icon(Icons.download),
                        label: const Text('Download Anonymized Graph'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
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

  Widget _buildStatsComparison(BuildContext context, AppProvider provider) {
    final original = provider.originalGraph!;
    final anonymized = provider.anonymizedGraph!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatRow(
              context,
              'Nodes',
              original.actualNodeCount.toString(),
              anonymized.actualNodeCount.toString(),
            ),
            const Divider(),
            _buildStatRow(
              context,
              'Edges',
              original.edgeCount.toString(),
              anonymized.edgeCount.toString(),
            ),
            const Divider(),
            _buildStatRow(
              context,
              'Density',
              original.density.toStringAsFixed(4),
              anonymized.density.toStringAsFixed(4),
            ),
            const Divider(),
            _buildStatRow(
              context,
              'Avg Degree',
              original.averageDegree.toStringAsFixed(2),
              anonymized.averageDegree.toStringAsFixed(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String original,
    String anonymized,
  ) {
    final originalVal = double.tryParse(original) ?? 0;
    final anonymizedVal = double.tryParse(anonymized) ?? 0;
    final diff = anonymizedVal - originalVal;
    final diffPercent =
        originalVal != 0 ? ((diff / originalVal) * 100) : 0.0;

    Color diffColor;
    IconData diffIcon;
    if (diff.abs() < 0.001) {
      diffColor = AppTheme.textSecondary;
      diffIcon = Icons.remove;
    } else if (diff > 0) {
      diffColor = AppTheme.success;
      diffIcon = Icons.arrow_upward;
    } else {
      diffColor = AppTheme.danger;
      diffIcon = Icons.arrow_downward;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              original,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const Icon(Icons.arrow_forward, color: AppTheme.textSecondary),
          Expanded(
            child: Text(
              anonymized,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(diffIcon, size: 16, color: diffColor),
                const SizedBox(width: 4),
                Text(
                  '${diffPercent.toStringAsFixed(1)}%',
                  style: TextStyle(color: diffColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricResults(BuildContext context, AppProvider provider) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: provider.metricResults.length > 2 ? 2 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.5,
      ),
      itemCount: provider.metricResults.length,
      itemBuilder: (context, index) {
        final entry = provider.metricResults.entries.elementAt(index);
        final metric = MetricModel.allMetrics.firstWhere(
          (m) => m.type == entry.key,
        );

        return MetricResultCard(
          metric: metric,
          value: entry.value,
          kValue: provider.kValue,
        );
      },
    );
  }

  void _downloadResult(BuildContext context) {
    final provider = context.read<AppProvider>();
    if (provider.anonymizedGraph == null) return;

    final mtxContent = MtxParser.generateMtx(
      provider.anonymizedGraph!,
      comment: 'Anonymized with NetGUC (k=${provider.kValue})',
    );

    // Show the MTX content in a dialog (web doesn't support direct file download easily)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anonymized Graph (MTX Format)'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              mtxContent,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
