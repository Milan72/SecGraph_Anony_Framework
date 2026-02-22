import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/algorithm_model.dart';

class AlgorithmCard extends StatefulWidget {
  final AlgorithmModel algorithm;
  final bool isSelected;
  final VoidCallback onTap;

  const AlgorithmCard({
    super.key,
    required this.algorithm,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<AlgorithmCard> createState() => _AlgorithmCardState();
}

class _AlgorithmCardState extends State<AlgorithmCard> {
  bool _isHovered = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.primary.withOpacity(0.1)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.primary
                  : _isHovered
                      ? AppTheme.textSecondary
                      : AppTheme.border,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected || _isHovered
                ? [
                    BoxShadow(
                      color: widget.isSelected
                          ? AppTheme.primary.withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.algorithm.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.algorithm.icon,
                        color: widget.algorithm.color,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    if (widget.isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppTheme.background,
                          size: 16,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  widget.algorithm.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Description
                Text(
                  widget.algorithm.shortDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Privacy/Utility Meters
                _buildMeter(
                  context,
                  'Privacy',
                  widget.algorithm.privacyValue,
                  AppTheme.danger,
                ),
                const SizedBox(height: 8),
                _buildMeter(
                  context,
                  'Utility',
                  widget.algorithm.utilityValue,
                  AppTheme.success,
                ),

                const SizedBox(height: 8),

                // Learn More
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Row(
                    children: [
                      Text(
                        'Learn more',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primary,
                            ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                ),

                if (_isExpanded) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.algorithm.useCase,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeter(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _getLevelText(value),
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getLevelText(double value) {
    if (value >= 0.9) return 'Perfect';
    if (value >= 0.7) return 'High';
    if (value >= 0.4) return 'Medium';
    return 'Low';
  }
}
