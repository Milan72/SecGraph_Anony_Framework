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
  bool _isLayoutComputing = false;
  bool _isTruncated = false;
  final TransformationController _transformController = TransformationController();

  // Cap nodes to avoid O(n²) freeze in the force-directed layout.
  static const int _maxNodes = 150;

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

  Future<void> _calculateLayout() async {
    // Sample nodes if the graph is very large.
    final allNodes = widget.graph.nodes.toList();
    final truncated = allNodes.length > _maxNodes;
    final nodes = truncated ? allNodes.take(_maxNodes).toList() : allNodes;
    final nodeSet = nodes.toSet();

    // Only keep edges between visible nodes.
    final displayEdges = widget.graph.edges
        .where((e) => nodeSet.contains(e.source) && nodeSet.contains(e.target))
        .toList();

    final random = Random(42); // Deterministic seed

    // Initialize random positions in a local map (not _nodePositions)
    // so we don't mutate state while iterating below.
    var positions = <int, Offset>{};
    for (final node in nodes) {
      positions[node] = Offset(
        random.nextDouble() * 400 + 50,
        random.nextDouble() * 400 + 50,
      );
    }

    if (mounted) {
      setState(() {
        _nodePositions = {};
        _isLayoutComputing = true;
        _isTruncated = truncated;
      });
    }

    // Run force-directed iterations, yielding to the event loop every
    // few steps so the UI stays responsive.
    const iterations = 50;
    const k = 100.0; // Optimal distance
    const coolingFactor = 0.95;
    var temperature = 100.0;

    for (var iter = 0; iter < iterations; iter++) {
      final forces = <int, Offset>{for (final n in nodes) n: Offset.zero};

      // Repulsive forces between all pairs  O(n²) — capped by _maxNodes.
      for (var i = 0; i < nodes.length; i++) {
        for (var j = i + 1; j < nodes.length; j++) {
          final u = nodes[i];
          final v = nodes[j];
          final delta = positions[u]! - positions[v]!;
          final distance = max(delta.distance, 1.0);
          final repulsion = k * k / distance;
          final force = delta / distance * repulsion;
          forces[u] = forces[u]! + force;
          forces[v] = forces[v]! - force;
        }
      }

      // Attractive forces along edges.
      for (final edge in displayEdges) {
        final u = edge.source;
        final v = edge.target;
        if (!positions.containsKey(u) || !positions.containsKey(v)) continue;
        final delta = positions[u]! - positions[v]!;
        final distance = max(delta.distance, 1.0);
        final attraction = distance * distance / k;
        final force = delta / distance * attraction;
        forces[u] = forces[u]! - force;
        forces[v] = forces[v]! + force;
      }

      // Apply forces with temperature.
      for (final node in nodes) {
        final force = forces[node]!;
        final displacement = force.distance;
        if (displacement > 0) {
          final limitedForce =
              force / displacement * min(displacement, temperature);
          positions[node] = positions[node]! + limitedForce;
        }
        positions[node] = Offset(
          positions[node]!.dx.clamp(20, 480),
          positions[node]!.dy.clamp(20, 480),
        );
      }

      temperature *= coolingFactor;

      // Yield every 5 iterations so the event loop can process frames.
      if (iter % 5 == 4) {
        await Future.delayed(Duration.zero);
        if (!mounted) return;
      }
    }

    if (mounted) {
      setState(() {
        _nodePositions = positions;
        _isLayoutComputing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          if (_isLayoutComputing)
            const Center(child: CircularProgressIndicator())
          else
            InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(100),
              child: CustomPaint(
                painter: GraphPainter(
                  nodePositions: _nodePositions,
                  nodeColor: widget.nodeColor,
                  edges: widget.graph.edges,
                ),
                size: const Size(500, 500),
              ),
            ),
          if (_isTruncated)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Showing $_maxNodes of ${widget.graph.actualNodeCount} nodes',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ),
            ),
        ],
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
  final List<EdgeModel> edges;
  final Map<int, Offset> nodePositions;
  final Color nodeColor;

  GraphPainter({
    required this.edges,
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

    // Draw edges (only those whose both endpoints have been positioned).
    for (final edge in edges) {
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
    return oldDelegate.edges != edges ||
        oldDelegate.nodePositions != nodePositions ||
        oldDelegate.nodeColor != nodeColor;
  }
}
