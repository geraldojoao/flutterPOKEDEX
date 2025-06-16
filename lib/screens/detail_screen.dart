import 'package:flutter/material.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> pokemon;
  final bool isFavorite;
  final void Function(String) onToggleFavorite;

  const DetailScreen({
    super.key,
    required this.pokemon,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pokemon['name'].toUpperCase())),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.pokemon['sprites']?['front_default'] != null)
              Hero(
                tag: 'pokemon_image_${widget.pokemon['name']}',
                child: Image.network(
                  widget.pokemon['sprites']['front_default']!,
                  height: 120,
                ),
              ),
            Text('ID: ${widget.pokemon['id']}'),
            Text('Height: ${widget.pokemon['height']}'),
            Text('Weight: ${widget.pokemon['weight']}'),
            Text(
              'Types: ${(widget.pokemon['types'] as List<dynamic>).map<String>((t) => t['type']['name'] as String).join(', ')}',
            ),
            StatsBars(pokemon: widget.pokemon),
            IconButton(
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
              onPressed: () {
                widget.onToggleFavorite(widget.pokemon['name']);
                setState(() {
                  _isFavorite = !_isFavorite;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

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
