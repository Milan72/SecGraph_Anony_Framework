import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/algorithm_model.dart';
import '../models/metric_model.dart';
import '../providers/app_provider.dart';
import '../widgets/algorithm_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/graph_stats_card.dart';
import 'results_screen.dart';

class AlgorithmScreen extends StatelessWidget {
  const AlgorithmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Algorithms & Metrics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<AppProvider>().reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Graph Info Card
                if (provider.originalGraph != null)
                  GraphStatsCard(graph: provider.originalGraph!),

                const SizedBox(height: 32),

                // K Value Slider
                _buildKValueSection(context, provider),

                const SizedBox(height: 32),

                // Anonymization Algorithms
                Text(
                  'Anonymization Algorithms',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select one or more algorithms to apply',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                _buildAlgorithmGrid(context, provider),

                const SizedBox(height: 32),

                // Utility Metrics
                Text(
                  'Utility Metrics',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select metrics to evaluate after anonymization',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                _buildMetricGrid(context, provider),

                const SizedBox(height: 48),

                // Run Button
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: provider.selectedAlgorithms.isEmpty
                          ? null
                          : () => _runAnonymization(context, provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.selectedAlgorithms.isEmpty
                            ? AppTheme.border
                            : AppTheme.primary,
                      ),
                      child: provider.isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppTheme.background,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow),
                                SizedBox(width: 8),
                                Text(
                                  'Run Anonymization',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Selection summary
                if (provider.selectedAlgorithms.isNotEmpty)
                  Center(
                    child: Text(
                      '${provider.selectedAlgorithms.length} algorithm(s) selected • '
                      '${provider.selectedMetrics.length} metric(s) selected • '
                      'k = ${provider.kValue}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKValueSection(BuildContext context, AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: AppTheme.primary),
                const SizedBox(width: 12),
                Text(
                  'K Parameter',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary),
                  ),
                  child: Text(
                    'k = ${provider.kValue}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Controls the intensity of anonymization (iterations, walk length, etc.)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Slider(
                value: provider.kValue.toDouble(),
                min: AppConstants.minKValue.toDouble(),
                max: AppConstants.maxKValue.toDouble(),
                divisions: AppConstants.maxKValue - AppConstants.minKValue,
                label: provider.kValue.toString(),
                onChanged: (value) {
                  provider.setKValue(value.round());
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Low (${AppConstants.minKValue})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'High (${AppConstants.maxKValue})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlgorithmGrid(BuildContext context, AppProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: AlgorithmModel.allAlgorithms.length,
          itemBuilder: (context, index) {
            final algorithm = AlgorithmModel.allAlgorithms[index];
            final isSelected =
                provider.selectedAlgorithms.contains(algorithm.type);

            return AlgorithmCard(
              algorithm: algorithm,
              isSelected: isSelected,
              onTap: () => provider.toggleAlgorithm(algorithm.type),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricGrid(BuildContext context, AppProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: MetricModel.allMetrics.length,
          itemBuilder: (context, index) {
            final metric = MetricModel.allMetrics[index];
            final isSelected = provider.selectedMetrics.contains(metric.type);

            return MetricCard(
              metric: metric,
              isSelected: isSelected,
              onTap: () => provider.toggleMetric(metric.type),
            );
          },
        );
      },
    );
  }

  Future<void> _runAnonymization(
      BuildContext context, AppProvider provider) async {
    await provider.runAnonymization();

    if (provider.hasAnonymizedGraph && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResultsScreen()),
      );
    }
  }
}
