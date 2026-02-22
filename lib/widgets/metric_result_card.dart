import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/metric_model.dart';

class MetricResultCard extends StatelessWidget {
  final MetricModel metric;
  final double value;
  final int kValue;

  const MetricResultCard({
    super.key,
    required this.metric,
    required this.value,
    required this.kValue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Circular Progress
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: AppTheme.border,
                      valueColor: AlwaysStoppedAnimation(metric.color),
                    ),
                  ),
                  Text(
                    '${(value * 100).toInt()}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        metric.icon,
                        color: metric.color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        metric.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Utility (k=$kValue): ${value.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric.interpretation,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Status Icon
            Icon(
              value > 0.5 ? Icons.thumb_up : Icons.thumb_down,
              color: value > 0.5 ? AppTheme.success : AppTheme.warning,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
