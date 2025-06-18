import 'package:flutter/material.dart';
import '../widgets/stats_bars.dart';

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
            Text('Altura: ${widget.pokemon['height']}'),
            Text('Peso: ${widget.pokemon['weight']}'),
            Text(
              'Tipos: ${(widget.pokemon['types'] as List<dynamic>).map<String>((t) => t['type']['name'] as String).join(', ')}',
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
