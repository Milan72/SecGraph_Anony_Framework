import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/app_provider.dart';
import 'algorithm_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isDragging = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mtx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final content = String.fromCharCodes(file.bytes!);
        
        if (mounted) {
          await context.read<AppProvider>().loadMtxContent(
            content,
            file.name,
          );
          
          if (mounted && context.read<AppProvider>().hasGraph) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlgorithmScreen()),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Title
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.hub,
                    size: 64,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appSubtitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Upload Zone
                MouseRegion(
                  onEnter: (_) => setState(() => _isDragging = true),
                  onExit: (_) => setState(() => _isDragging = false),
                  child: GestureDetector(
                    onTap: _pickFile,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 500,
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? AppTheme.primary.withOpacity(0.1)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isDragging ? AppTheme.primary : AppTheme.border,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 64,
                            color: _isDragging
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Upload .MTX Graph File',
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: _isDragging
                                          ? AppTheme.primary
                                          : AppTheme.textPrimary,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click to browse or drag and drop',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Supported: Matrix Market (.mtx)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Sample file hint
                TextButton.icon(
                  onPressed: () {
                    _loadSampleGraph();
                  },
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Try with sample graph'),
                ),

                // Error display
                Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    if (provider.errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.danger),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppTheme.danger),
                              const SizedBox(width: 8),
                              Text(
                                provider.errorMessage!,
                                style: const TextStyle(color: AppTheme.danger),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Loading indicator
                Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    if (provider.isProcessing) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _loadSampleGraph() {
    // Sample Karate Club style graph
    const sampleMtx = '''%%MatrixMarket matrix coordinate pattern symmetric
% Sample social network graph
34 34 78
1 2
1 3
1 4
1 5
1 6
1 7
1 8
1 9
1 11
1 12
1 13
1 14
1 18
1 20
1 22
1 32
2 3
2 4
2 8
2 14
2 18
2 20
2 22
2 31
3 4
3 8
3 9
3 10
3 14
3 28
3 29
3 33
4 8
4 13
4 14
5 7
5 11
6 7
6 11
6 17
7 17
9 31
9 33
9 34
10 34
14 34
15 33
15 34
16 33
16 34
19 33
19 34
20 34
21 33
21 34
23 33
23 34
24 26
24 28
24 30
24 33
24 34
25 26
25 28
25 32
26 32
27 30
27 34
28 34
29 32
29 34
30 33
30 34
31 33
31 34
32 33
32 34
33 34
''';

    context.read<AppProvider>().loadMtxContent(sampleMtx, 'sample_graph.mtx');
    
    if (context.read<AppProvider>().hasGraph) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AlgorithmScreen()),
      );
    }
  }
}
