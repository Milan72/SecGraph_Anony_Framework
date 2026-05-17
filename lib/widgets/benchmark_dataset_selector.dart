import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../utils/benchmark_dataset_registry.dart';

class BenchmarkDatasetSelector extends StatelessWidget {
  const BenchmarkDatasetSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Load Real Benchmark Dataset',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Use real Network Repository graph datasets to test anonymization, de-anonymization, reconstruction, and benchmark evaluation.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            ...BenchmarkDatasetRegistry.datasets.map(
              (dataset) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.displayColor.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.dataset, color: AppTheme.displayColor),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dataset.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dataset.description,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${dataset.estimatedNodes} nodes • ${dataset.estimatedEdges} edges • ${dataset.source}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: provider.isProcessing
                          ? null
                          : () => provider.loadBenchmarkDataset(dataset),
                      child: const Text('Load'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}