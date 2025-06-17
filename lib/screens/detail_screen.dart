import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  List<Map<String, String>> evolutions = [];
  bool loadingEvolutions = true;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    fetchEvolutions();
  }

  Future<void> fetchEvolutions() async {
    try {
      // 1. Busca species para pegar a URL da cadeia de evolução
      final speciesUrl = widget.pokemon['species']['url'];
      final speciesResponse = await http.get(Uri.parse(speciesUrl));
      final speciesData = json.decode(speciesResponse.body);
      final evolutionUrl = speciesData['evolution_chain']['url'];

      // 2. Busca a cadeia de evolução
      final evolutionResponse = await http.get(Uri.parse(evolutionUrl));
      final evolutionData = json.decode(evolutionResponse.body);

      // 3. Extrai as evoluções (até 3 estágios)
      List<Map<String, String>> evoList = [];
      var chain = evolutionData['chain'];
      do {
        final name = chain['species']['name'];
        final url = chain['species']['url'];
        final id = url.split('/')[url.split('/').length - 2];
        final image =
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
        evoList.add({'name': name, 'image': image});
        if (chain['evolves_to'] != null && chain['evolves_to'].isNotEmpty) {
          chain = chain['evolves_to'][0];
        } else {
          chain = null;
        }
      } while (chain != null);

      setState(() {
        evolutions = evoList;
        loadingEvolutions = false;
      });
    } catch (e) {
      setState(() {
        loadingEvolutions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pokemon['name'].toUpperCase())),
      body: Center(
        child: SingleChildScrollView(
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
              // Evoluções
              const SizedBox(height: 16),
              loadingEvolutions
                  ? const CircularProgressIndicator()
                  : evolutions.length > 1
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Evoluções:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: evolutions.map((evo) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Column(
                                children: [
                                  Image.network(evo['image']!, height: 60),
                                  Text(
                                    evo['name']![0].toUpperCase() +
                                        evo['name']!.substring(1),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
              StatsBars(pokemon: widget.pokemon),
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                ),
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
