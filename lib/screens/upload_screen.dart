import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../widgets/benchmark_dataset_selector.dart';
import 'algorithm_screen.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  Future<void> _pickMtxFile(BuildContext context) async {
    final provider = context.read<AppProvider>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mtx', 'txt', 'edges'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final fileName = file.name;

    if (file.bytes != null) {
      final content = utf8.decode(file.bytes!);
      await provider.loadMtxContent(content, fileName);
    } else if (file.path != null) {
      await provider.loadMtxFile(file.path!, fileName);
    }
  }

  void _continueToAlgorithms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AlgorithmScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('SecGraph DeAnony'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHero(context),
                    const SizedBox(height: 28),
                    _buildUploadCard(context, provider),
                    const SizedBox(height: 24),
                    const BenchmarkDatasetSelector(),
                    if (provider.errorMessage != null) ...[
                      const SizedBox(height: 20),
                      _buildErrorCard(provider),
                    ],
                    if (provider.hasGraph) ...[
                      const SizedBox(height: 24),
                      _buildGraphLoadedCard(context, provider),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.hub,
          size: 72,
          color: AppTheme.displayColor,
        ),
        const SizedBox(height: 18),
        Text(
          'Graph Anonymization & Privacy Evaluation',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Upload a graph or load a real benchmark dataset to anonymize network structure, test de-anonymization attacks, reconstruct exposed topology, and evaluate privacy leakage.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildUploadCard(
    BuildContext context,
    AppProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            const Icon(
              Icons.upload_file,
              size: 48,
              color: AppTheme.displayColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Upload Graph File',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Supported formats: .mtx, .edges, .txt edge-list files.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed:
                  provider.isProcessing ? null : () => _pickMtxFile(context),
              icon: const Icon(Icons.folder_open),
              label: Text(
                provider.isProcessing ? 'Loading...' : 'Choose Graph File',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphLoadedCard(
    BuildContext context,
    AppProvider provider,
  ) {
    final graph = provider.originalGraph!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Graph Loaded Successfully',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _statTile('File', graph.fileName),
                _statTile('Nodes', graph.actualNodeCount.toString()),
                _statTile('Edges', graph.edgeCount.toString()),
                _statTile('Density', graph.density.toStringAsFixed(4)),
                _statTile(
                  'Avg Degree',
                  graph.averageDegree.toStringAsFixed(2),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _continueToAlgorithms(context),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue to Anonymization'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
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
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider.errorMessage ?? 'Unknown error',
              style: const TextStyle(color: AppTheme.danger),
            ),
          ),
          IconButton(
            onPressed: provider.clearError,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}