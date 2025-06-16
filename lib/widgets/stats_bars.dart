import 'package:flutter/material.dart';

class StatsBars extends StatelessWidget {
  final Map<String, dynamic> pokemon;

  const StatsBars({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    List<dynamic> stats = pokemon['stats'];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: stats.map((stat) {
          String statName = stat['stat']['name'];
          int baseStat = stat['base_stat'];
          double percentage = baseStat / 100.0; // Normalize to 0-1 range

          return Column(
            children: [
              Text('$statName: $baseStat'),
              AnimatedLinearProgressIndicator(
                percentage: percentage,
                color: _getColorForStat(statName),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getColorForStat(String statName) {
    switch (statName) {
      case 'hp':
        return Colors.red;
      case 'ataque':
        return Colors.orange;
      case 'defesa':
        return Colors.blue;
      case 'ataque especial':
        return Colors.purple;
      case 'defesa especial':
        return Colors.green;
      case 'velocidade':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }
}

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
