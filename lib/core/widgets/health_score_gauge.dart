import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../config/theme.dart';

/// Circular health score gauge widget
class HealthScoreGauge extends StatelessWidget {
  final double score; // 0 to 100
  final double size;
  final double strokeWidth;
  final bool showLabel;
  
  const HealthScoreGauge({
    super.key,
    required this.score,
    this.size = 120,
    this.strokeWidth = 12,
    this.showLabel = true,
  });
  
  Color _getScoreColor() {
    if (score >= 75) {
      return AppColors.healthyGreen;
    } else if (score >= 50) {
      return AppColors.dueSoonOrange;
    } else {
      return AppColors.overdueRed;
    }
  }
  
  String _getScoreLabel() {
    if (score >= 75) {
      return 'Healthy';
    } else if (score >= 50) {
      return 'Fair';
    } else {
      return 'Critical';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              CustomPaint(
                size: Size(size, size),
                painter: _CirclePainter(
                  color: color.withOpacity(0.1),
                  strokeWidth: strokeWidth,
                  progress: 1.0,
                ),
              ),
              // Progress circle
              CustomPaint(
                size: Size(size, size),
                painter: _CirclePainter(
                  color: color,
                  strokeWidth: strokeWidth,
                  progress: score / 100,
                ),
              ),
              // Score text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score.toInt().toString(),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'Score',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              _getScoreLabel(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double progress;
  
  _CirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
