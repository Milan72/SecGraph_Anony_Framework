import 'package:flutter/material.dart';

import '../models/algorithm_model.dart';
import '../models/attack_result_model.dart';
import '../models/graph_model.dart';
import '../models/metric_model.dart';
import '../utils/deanonymization/deanonymization_engine.dart';
import '../utils/deanonymization/reconstruction_engine.dart';
import '../utils/graph_algorithms.dart';
import '../utils/mtx_parser.dart';

class AppProvider extends ChangeNotifier {
  // Graph state
  GraphModel? _originalGraph;
  GraphModel? _anonymizedGraph;
  GraphModel? _reconstructedGraph;

  // Selection state
  final Set<AlgorithmType> _selectedAlgorithms = {};
  final Set<MetricType> _selectedMetrics = {};

  // Configuration state
  int _kValue = 10;

  // Processing state
  bool _isProcessing = false;
  String? _errorMessage;

  // Results state
  Map<MetricType, double> _metricResults = {};
  List<AttackResult> _attackResults = [];

  // Reconstruction metrics
  double _structuralRecoveryScore = 0.0;
  double _nodeRecoveryScore = 0.0;

  // Graph getters
  GraphModel? get originalGraph => _originalGraph;
  GraphModel? get anonymizedGraph => _anonymizedGraph;
  GraphModel? get reconstructedGraph => _reconstructedGraph;

  // Selection getters
  Set<AlgorithmType> get selectedAlgorithms => _selectedAlgorithms;
  Set<MetricType> get selectedMetrics => _selectedMetrics;

  // Configuration getters
  int get kValue => _kValue;

  // Processing getters
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  // Results getters
  Map<MetricType, double> get metricResults => _metricResults;
  List<AttackResult> get attackResults => _attackResults;

  // Reconstruction getters
  double get structuralRecoveryScore => _structuralRecoveryScore;
  double get nodeRecoveryScore => _nodeRecoveryScore;

  // Convenience getters
  bool get hasGraph => _originalGraph != null;
  bool get hasAnonymizedGraph => _anonymizedGraph != null;
  bool get hasAttackResults => _attackResults.isNotEmpty;
  bool get hasReconstructedGraph => _reconstructedGraph != null;

  Future<void> loadMtxFile(String path, String fileName) async {
    try {
      _setProcessing(true);

      _originalGraph = await MtxParser.parseFile(path, fileName);
      _clearGeneratedResults();

      _setProcessing(false);
    } catch (e) {
      _setError('Failed to load file: $e');
    }
  }

  Future<void> loadMtxContent(String content, String fileName) async {
    try {
      _setProcessing(true);

      _originalGraph = MtxParser.parseContent(content, fileName);
      _clearGeneratedResults();

      _setProcessing(false);
    } catch (e) {
      _setError('Failed to parse file: $e');
    }
  }

  void toggleAlgorithm(AlgorithmType algorithm) {
    if (_selectedAlgorithms.contains(algorithm)) {
      _selectedAlgorithms.remove(algorithm);
    } else {
      _selectedAlgorithms.add(algorithm);
    }

    notifyListeners();
  }

  void toggleMetric(MetricType metric) {
    if (_selectedMetrics.contains(metric)) {
      _selectedMetrics.remove(metric);
    } else {
      _selectedMetrics.add(metric);
    }

    notifyListeners();
  }

  void setKValue(int value) {
    _kValue = value;
    notifyListeners();
  }

  Future<void> runAnonymization() async {
    if (_originalGraph == null || _selectedAlgorithms.isEmpty) return;

    try {
      _setProcessing(true);

      GraphModel currentGraph = _originalGraph!;

      for (final algorithmType in _selectedAlgorithms) {
        currentGraph = await GraphAlgorithms.runAlgorithm(
          currentGraph,
          algorithmType,
          _kValue,
        );
      }

      _anonymizedGraph = currentGraph;

      _attackResults = DeanonymizationEngine.runBlackBoxAttacks(
        _anonymizedGraph!,
      );

      _buildReconstruction();

      if (_selectedMetrics.isNotEmpty) {
        _metricResults = await GraphAlgorithms.calculateMetricsAsync(
          _anonymizedGraph!,
          _selectedMetrics.toList(),
          _kValue,
        );
      } else {
        _metricResults = {};
      }

      _setProcessing(false);
    } catch (e) {
      _setError('Anonymization failed: $e');
    }
  }

  Future<void> runDeanonymizationAttacks() async {
    if (_anonymizedGraph == null) return;

    try {
      _setProcessing(true);

      _attackResults = DeanonymizationEngine.runBlackBoxAttacks(
        _anonymizedGraph!,
      );

      _buildReconstruction();

      _setProcessing(false);
    } catch (e) {
      _setError('De-anonymization attack failed: $e');
    }
  }

  Future<void> runSelectedDeanonymizationAttacks(
    List<String> selectedAttacks,
  ) async {
    if (_anonymizedGraph == null || selectedAttacks.isEmpty) return;

    try {
      _setProcessing(true);

      _attackResults = DeanonymizationEngine.runSelectedAttacks(
        _anonymizedGraph!,
        selectedAttacks,
      );

      _buildReconstruction();

      _setProcessing(false);
    } catch (e) {
      _setError('Selected de-anonymization attacks failed: $e');
    }
  }

  void reset() {
    _originalGraph = null;
    _anonymizedGraph = null;
    _reconstructedGraph = null;
    _selectedAlgorithms.clear();
    _selectedMetrics.clear();
    _kValue = 10;
    _isProcessing = false;
    _errorMessage = null;
    _metricResults = {};
    _attackResults = [];
    _structuralRecoveryScore = 0.0;
    _nodeRecoveryScore = 0.0;

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _buildReconstruction() {
    if (_anonymizedGraph == null || _attackResults.isEmpty) {
      _reconstructedGraph = null;
      _structuralRecoveryScore = 0.0;
      _nodeRecoveryScore = 0.0;
      return;
    }

    _reconstructedGraph = ReconstructionEngine.buildReconstructedGraph(
      anonymizedGraph: _anonymizedGraph!,
      attackResults: _attackResults,
    );

    _structuralRecoveryScore =
        ReconstructionEngine.calculateStructuralRecoveryScore(
      anonymizedGraph: _anonymizedGraph!,
      reconstructedGraph: _reconstructedGraph!,
    );

    _nodeRecoveryScore = ReconstructionEngine.calculateNodeRecoveryScore(
      anonymizedGraph: _anonymizedGraph!,
      reconstructedGraph: _reconstructedGraph!,
    );
  }

  void _clearGeneratedResults() {
    _anonymizedGraph = null;
    _reconstructedGraph = null;
    _metricResults = {};
    _attackResults = [];
    _structuralRecoveryScore = 0.0;
    _nodeRecoveryScore = 0.0;
  }

  void _setProcessing(bool value) {
    _isProcessing = value;

    if (value) {
      _errorMessage = null;
    }

    notifyListeners();
  }

  void _setError(String message) {
    _isProcessing = false;
    _errorMessage = message;
    notifyListeners();
  }
}
