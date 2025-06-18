import 'package:flutter/material.dart';
import 'progress_bar.dart';

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
          double percentage = baseStat / 100.0; // Normaliza para 0-1

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
        return Colors.green;
      case 'attack':
        return Colors.red;
      case 'defense':
        return Colors.blue;
      case 'special-attack':
        return Colors.orange;
      case 'special-defense':
        return Colors.purple;
      case 'speed':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }
}
