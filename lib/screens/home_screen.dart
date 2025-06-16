import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../widgets/pokemon_card.dart';

enum SortOption { nameAsc, nameDesc }

class HomeScreen extends StatefulWidget {
  final void Function(String) onToggleFavorite;
  final Set<String> favorites;
  const HomeScreen({
    super.key,
    required this.onToggleFavorite,
    required this.favorites,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List pokemons = [];
  bool loading = true;
  String error = '';
  String search = '';
  String? selectedType;
  List<String> types = [];
  SortOption _sortOption = SortOption.nameAsc;
  Map<String, dynamic> pokemonDetailsCache = {};
  List<dynamic> filteredPokemons = [];
  Map<String, Color> typeColors = {
    'fire': Colors.red.shade200,
    'water': Colors.blue.shade200,
    'grass': Colors.green.shade200,
    'electric': Colors.yellow.shade200,
    'poison': Colors.purple.shade200,
    'ground': Colors.brown.shade200,
    'flying': Colors.cyan.shade200,
    'bug': Colors.lightGreen.shade200,
    'rock': Colors.grey.shade400,
    'ghost': Colors.deepPurple.shade200,
    'dragon': Colors.indigo.shade200,
    'steel': Colors.blueGrey.shade200,
    'dark': Colors.grey.shade900,
    'fairy': Colors.pink.shade200,
    'ice': Colors.lightBlue.shade200,
    'psychic': Colors.pinkAccent.shade200,
    'normal': Colors.grey.shade300,
    'fighting': Colors.orange.shade200,
  };
  Map<String, dynamic>? randomPokemon;
  bool showOnlyFavorites = false;

  @override
  void initState() {
    super.initState();
    fetchPokemons();
    fetchTypes();
  }

  Future<void> fetchPokemons() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final res = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=100'),
      );
      final data = json.decode(res.body);
      setState(() {
        pokemons = data['results'];
        loading = false;
        _applyFilters();
        _fetchRandomPokemon();
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load data.';
        loading = false;
      });
    }
  }

  Future<void> fetchTypes() async {
    try {
      final res = await http.get(Uri.parse('https://pokeapi.co/api/v2/type'));
      final data = json.decode(res.body);
      List<String> fetchedTypes = (data['results'] as List<dynamic>)
          .map<String>((type) => type['name'] as String)
          .toList();
      setState(() {
        types = fetchedTypes;
      });
    } catch (e) {
      print('Failed to load types: $e');
    }
  }

  Future<void> _fetchRandomPokemon() async {
    if (pokemons.isNotEmpty) {
      final random = Random();
      final pokemon = pokemons[random.nextInt(pokemons.length)];
      final details = await fetchPokemonDetails(pokemon['url']);
      setState(() {
        randomPokemon = details;
      });
    }
  }

  Future<void> _applyFilters() async {
    List<dynamic> tempFilteredPokemons = [];

    for (var p in pokemons) {
      bool nameMatches = p['name'].toString().toLowerCase().contains(
        search.toLowerCase(),
      );
      bool typeMatches = selectedType == null;

      if (selectedType != null) {
        if (pokemonDetailsCache.containsKey(p['url'])) {
          final pokemonDetails = pokemonDetailsCache[p['url']];
          if (pokemonDetails != null && pokemonDetails['types'] != null) {
            typeMatches = (pokemonDetails['types'] as List).any(
              (type) => type['type']['name'] == selectedType,
            );
          } else {
            typeMatches = false;
          }
        } else {
          final pokemonDetails = await fetchPokemonDetails(p['url']);
          if (pokemonDetails != null) {
            pokemonDetailsCache[p['url']] = pokemonDetails;
            if (pokemonDetails['types'] != null) {
              typeMatches = (pokemonDetails['types'] as List).any(
                (type) => type['type']['name'] == selectedType,
              );
            } else {
              typeMatches = false;
            }
          } else {
            typeMatches = false;
          }
        }
      }

      if (nameMatches && typeMatches) {
        tempFilteredPokemons.add(p);
      }
    }

    // Sort the filtered list
    tempFilteredPokemons.sort((a, b) {
      switch (_sortOption) {
        case SortOption.nameAsc:
          return a['name'].compareTo(b['name']);
        case SortOption.nameDesc:
          return b['name'].compareTo(a['name']);
      }
    });

    setState(() {
      filteredPokemons = tempFilteredPokemons;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (randomPokemon != null)
            Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      'Pokémon do dia: ${randomPokemon!['name'].toString().toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Image.network(
                      randomPokemon!['sprites']['front_default'] ??
                          'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg',
                      height: 100,
                      width: 100,
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              onChanged: (v) {
                setState(() {
                  search = v;
                  _applyFilters();
                });
              },
              decoration: const InputDecoration(
                hintText: 'Pesquisar Pokémon',
                filled: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Filtre por tipo',
                border: OutlineInputBorder(),
              ),
              value: selectedType,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos tipos')),
                ...types.map<DropdownMenuItem<String>>(
                  (type) =>
                      DropdownMenuItem<String>(value: type, child: Text(type)),
                ),
              ],
              onChanged: (String? value) {
                setState(() {
                  selectedType = value;
                  _applyFilters();
                });
              },
            ),
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (SortOption result) {
              setState(() {
                _sortOption = result;
                _applyFilters();
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(
                value: SortOption.nameAsc,
                child: Text('Ordenar por nome (A-Z)'),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.nameDesc,
                child: Text('Ordenar por nome (Z-A)'),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exibindo ${pokemons.length} pokémons',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
                  color: showOnlyFavorites ? Colors.red : null,
                ),
                tooltip: showOnlyFavorites
                    ? 'Mostrar todos'
                    : 'Mostrar apenas favoritos',
                onPressed: () {
                  setState(() {
                    showOnlyFavorites = !showOnlyFavorites;
                    _applyFilters();
                  });
                },
              ),
            ],
          ),
          if (loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (error.isNotEmpty)
            Expanded(child: Center(child: Text(error)))
          else if (filteredPokemons.isEmpty)
            const Expanded(child: Center(child: Text('No results')))
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600
                      ? 4
                      : 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: MediaQuery.of(context).size.width > 600
                      ? 0.8
                      : 0.7,
                ),
                itemCount: filteredPokemons.length,
                itemBuilder: (_, i) {
                  final p = filteredPokemons[i];
                  final name = p['name'];
                  final String imageUrl =
                      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${p['url'].split('/')[6]}.png';
                  final isFav = widget.favorites.contains(name);

                  Color? backgroundColor;
                  if (pokemonDetailsCache.containsKey(p['url'])) {
                    final pokemonDetails = pokemonDetailsCache[p['url']];
                    if (pokemonDetails != null &&
                        pokemonDetails['types'] != null) {
                      String? firstType =
                          (pokemonDetails['types'] as List).isNotEmpty
                          ? pokemonDetails['types'][0]['type']['name']
                          : null;
                      backgroundColor = typeColors[firstType];
                    }
                  }
                  backgroundColor ??= Colors.grey.shade800;

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: pokemonDetailsCache.containsKey(p['url'])
                        ? Future.value(pokemonDetailsCache[p['url']])
                        : fetchPokemonDetails(p['url']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData) {
                          pokemonDetailsCache[p['url']] = snapshot.data;
                          List types = snapshot.data!['types'];
                          String? firstType = types.isNotEmpty
                              ? types[0]['type']['name']
                              : null;
                          backgroundColor =
                              typeColors[firstType] ?? Colors.grey.shade800;
                        }
                        return PokemonCard(
                          pokemonName: name,
                          imageUrl: imageUrl,
                          isFavorite: isFav,
                          backgroundColor: backgroundColor!,
                          onTap: () async {
                            Map<String, dynamic>? detail =
                                pokemonDetailsCache[p['url']];
                            if (detail == null) {
                              final res = await http.get(Uri.parse(p['url']));
                              detail = json.decode(res.body);
                            }
                            Navigator.pushNamed(
                              context,
                              '/detail',
                              arguments: detail,
                            );
                          },
                          onToggleFavorite: () => widget.onToggleFavorite(name),
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> fetchPokemonDetails(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        print('Failed to fetch Pokemon details: ${res.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching Pokemon details: $e');
      return null;
    }
  }
}
