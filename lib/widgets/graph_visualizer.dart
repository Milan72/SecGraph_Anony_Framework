import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/graph_model.dart';

class GraphVisualizer extends StatefulWidget {
  final GraphModel graph;
  final Color nodeColor;

  const GraphVisualizer({
    super.key,
    required this.graph,
    required this.nodeColor,
  });

  @override
  State<GraphVisualizer> createState() => _GraphVisualizerState();
}

class _GraphVisualizerState extends State<GraphVisualizer> {
  Map<int, Offset> _nodePositions = {};
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _calculateLayout();
  }

  @override
  void didUpdateWidget(GraphVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph != widget.graph) {
      _calculateLayout();
    }
  }

  void _calculateLayout() {
    // Force-directed layout (simplified)
    final nodes = widget.graph.nodes.toList();
    final random = Random(42); // Deterministic seed

    // Initialize random positions
    _nodePositions = {};
    for (final node in nodes) {
      _nodePositions[node] = Offset(
        random.nextDouble() * 400 + 50,
        random.nextDouble() * 400 + 50,
      );
    }

    // Run force-directed iterations
    const iterations = 50;
    const k = 100.0; // Optimal distance
    const coolingFactor = 0.95;
    var temperature = 100.0;

    for (var iter = 0; iter < iterations; iter++) {
      final forces = <int, Offset>{};

      // Initialize forces
      for (final node in nodes) {
        forces[node] = Offset.zero;
      }

      // Repulsive forces between all pairs
      for (var i = 0; i < nodes.length; i++) {
        for (var j = i + 1; j < nodes.length; j++) {
          final u = nodes[i];
          final v = nodes[j];
          final delta = _nodePositions[u]! - _nodePositions[v]!;
          final distance = max(delta.distance, 1.0);
          final repulsion = (k * k / distance);
          final force = delta / distance * repulsion;

          forces[u] = forces[u]! + force;
          forces[v] = forces[v]! - force;
        }
      }

      // Attractive forces along edges
      for (final edge in widget.graph.edges) {
        final u = edge.source;
        final v = edge.target;
        if (!_nodePositions.containsKey(u) || !_nodePositions.containsKey(v)) {
          continue;
        }
        final delta = _nodePositions[u]! - _nodePositions[v]!;
        final distance = max(delta.distance, 1.0);
        final attraction = distance * distance / k;
        final force = delta / distance * attraction;

        forces[u] = forces[u]! - force;
        forces[v] = forces[v]! + force;
      }

      // Apply forces with temperature
      for (final node in nodes) {
        final force = forces[node]!;
        final displacement = force.distance;
        if (displacement > 0) {
          final limitedForce = force / displacement * min(displacement, temperature);
          _nodePositions[node] = _nodePositions[node]! + limitedForce;
        }

        // Keep within bounds
        _nodePositions[node] = Offset(
          _nodePositions[node]!.dx.clamp(20, 480),
          _nodePositions[node]!.dy.clamp(20, 480),
        );
      }

      temperature *= coolingFactor;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: 0.5,
        maxScale: 3.0,
        boundaryMargin: const EdgeInsets.all(100),
        child: CustomPaint(
          painter: GraphPainter(
            graph: widget.graph,
            nodePositions: _nodePositions,
            nodeColor: widget.nodeColor,
          ),
          size: const Size(500, 500),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }
}

class GraphPainter extends CustomPainter {
  final GraphModel graph;
  final Map<int, Offset> nodePositions;
  final Color nodeColor;

  GraphPainter({
    required this.graph,
    required this.nodePositions,
    required this.nodeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = AppTheme.textSecondary.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = nodeColor
      ..style = PaintingStyle.fill;

    final nodeBorderPaint = Paint()
      ..color = AppTheme.textPrimary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw edges
    for (final edge in graph.edges) {
      final p1 = nodePositions[edge.source];
      final p2 = nodePositions[edge.target];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, edgePaint);
      }
    }

    // Draw nodes
    const nodeRadius = 15.0;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (final entry in nodePositions.entries) {
      final node = entry.key;
      final pos = entry.value;

      // Draw node circle
      canvas.drawCircle(pos, nodeRadius, nodePaint);
      canvas.drawCircle(pos, nodeRadius, nodeBorderPaint);

      // Draw node label
      textPainter.text = TextSpan(
        text: node.toString(),
        style: const TextStyle(
          color: AppTheme.background,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        pos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.graph != graph ||
        oldDelegate.nodePositions != nodePositions ||
        oldDelegate.nodeColor != nodeColor;
  }
}
