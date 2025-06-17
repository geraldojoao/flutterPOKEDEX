import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PokemonCard extends StatefulWidget {
  final String pokemonName;
  final String imageUrl;
  final String speciesUrl;
  final bool isFavorite;
  final Color backgroundColor;
  final VoidCallback onTap;
  final VoidCallback onFavTap;

  const PokemonCard({
    Key? key,
    required this.pokemonName,
    required this.imageUrl,
    required this.speciesUrl,
    this.isFavorite = false,
    this.backgroundColor = Colors.white,
    required this.onTap,
    required this.onFavTap,
  }) : super(key: key);

  @override
  _PokemonCardState createState() => _PokemonCardState();
}

class _PokemonCardState extends State<PokemonCard> {
  List<Map<String, String>> evolutions = [];

  @override
  void initState() {
    super.initState();
    fetchEvolutions();
  }

  Future<void> fetchEvolutions() async {
    try {
      final speciesResponse = await http.get(Uri.parse(widget.speciesUrl));
      if (speciesResponse.statusCode == 200) {
        final speciesData = json.decode(speciesResponse.body);
        final evolutionChainUrl = speciesData['evolution_chain']['url'];
        final evoResponse = await http.get(Uri.parse(evolutionChainUrl));
        if (evoResponse.statusCode == 200) {
          final evoData = json.decode(evoResponse.body);
          List<Map<String, String>> evoList = [];
          var chain = evoData['chain'];
          void addEvo(var evo) {
            evoList.add({
              'name': evo['species']['name'],
              'image':
                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${_extractIdFromUrl(evo['species']['url'])}.png',
            });
            if (evo['evolves_to'] != null && evo['evolves_to'].isNotEmpty) {
              for (var next in evo['evolves_to']) {
                addEvo(next);
              }
            }
          }

          addEvo(chain);
          setState(() {
            evolutions = evoList;
          });
        }
      }
    } catch (e) {
      // Handle error or ignore
    }
  }

  String _extractIdFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    return segments[segments.length - 2];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Hero(
                    tag: 'pokemon_image_${widget.pokemonName}',
                    child: Image.network(widget.imageUrl, fit: BoxFit.contain),
                  ),
                ),
                Text(
                  widget.pokemonName.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Evoluções
                if (evolutions.isNotEmpty)
                  Column(
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
                                Text(evo['name']!),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(
      duration: 300.ms,
      curve: Curves.easeInOut,
      begin: const Offset(1, 1),
      end: const Offset(1, 1),
    );
  }
}
