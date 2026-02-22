import 'package:flutter/material.dart';
import '../models/graph_model.dart';
import '../models/algorithm_model.dart';
import '../models/metric_model.dart';
import '../utils/mtx_parser.dart';
import '../utils/graph_algorithms.dart';

class AppProvider extends ChangeNotifier {
  // State
  GraphModel? _originalGraph;
  GraphModel? _anonymizedGraph;
  final Set<AlgorithmType> _selectedAlgorithms = {};
  final Set<MetricType> _selectedMetrics = {};
  int _kValue = 10;
  bool _isProcessing = false;
  String? _errorMessage;
  Map<MetricType, double> _metricResults = {};

  // Getters
  GraphModel? get originalGraph => _originalGraph;
  GraphModel? get anonymizedGraph => _anonymizedGraph;
  Set<AlgorithmType> get selectedAlgorithms => _selectedAlgorithms;
  Set<MetricType> get selectedMetrics => _selectedMetrics;
  int get kValue => _kValue;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  Map<MetricType, double> get metricResults => _metricResults;
  bool get hasGraph => _originalGraph != null;
  bool get hasAnonymizedGraph => _anonymizedGraph != null;

  // Load MTX file
  Future<void> loadMtxFile(String path, String fileName) async {
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      _originalGraph = await MtxParser.parseFile(path, fileName);
      _anonymizedGraph = null;
      _metricResults = {};

      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'Failed to load file: $e';
      notifyListeners();
    }
  }

  // Parse MTX content directly
  Future<void> loadMtxContent(String content, String fileName) async {
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      _originalGraph = MtxParser.parseContent(content, fileName);
      _anonymizedGraph = null;
      _metricResults = {};

      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'Failed to parse file: $e';
      notifyListeners();
    }
  }

  // Toggle algorithm selection
  void toggleAlgorithm(AlgorithmType algorithm) {
    if (_selectedAlgorithms.contains(algorithm)) {
      _selectedAlgorithms.remove(algorithm);
    } else {
      _selectedAlgorithms.add(algorithm);
    }
    notifyListeners();
  }

  // Toggle metric selection
  void toggleMetric(MetricType metric) {
    if (_selectedMetrics.contains(metric)) {
      _selectedMetrics.remove(metric);
    } else {
      _selectedMetrics.add(metric);
    }
    notifyListeners();
  }

  // Set k value
  void setKValue(int value) {
    _kValue = value;
    notifyListeners();
  }

  // Run anonymization
  Future<void> runAnonymization() async {
    if (_originalGraph == null || _selectedAlgorithms.isEmpty) return;

    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      // Run selected algorithms sequentially
      GraphModel currentGraph = _originalGraph!;

      for (final algorithmType in _selectedAlgorithms) {
        currentGraph = await GraphAlgorithms.runAlgorithm(
          currentGraph,
          algorithmType,
          _kValue,
        );
      }

      _anonymizedGraph = currentGraph;

      // Calculate metrics if selected
      if (_selectedMetrics.isNotEmpty && _anonymizedGraph != null) {
        _metricResults = {};
        for (final metricType in _selectedMetrics) {
          _metricResults[metricType] = GraphAlgorithms.calculateMetric(
            _anonymizedGraph!,
            metricType,
            _kValue,
          );
        }
      }

      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'Anonymization failed: $e';
      notifyListeners();
    }
  }

  // Clear all
  void reset() {
    _originalGraph = null;
    _anonymizedGraph = null;
    _selectedAlgorithms.clear();
    _selectedMetrics.clear();
    _kValue = 10;
    _isProcessing = false;
    _errorMessage = null;
    _metricResults = {};
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
