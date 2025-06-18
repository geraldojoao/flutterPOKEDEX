import 'package:flutter/material.dart';

class AnimatedLinearProgressIndicator extends StatelessWidget {
  final double percentage;
  final Color color;

  const AnimatedLinearProgressIndicator({
    super.key,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: percentage),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, _) => LinearProgressIndicator(
        value: value,
        backgroundColor: Colors.grey.shade200,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
