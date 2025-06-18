import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (context) => ThemeProvider(),
    builder: (context, child) => PokedexApp(),
  ),
);

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme');
    if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (themeMode == ThemeMode.light) {
      await prefs.setString('theme', 'light');
    } else if (themeMode == ThemeMode.dark) {
      await prefs.setString('theme', 'dark');
    } else {
      await prefs.remove('theme');
    }
  }
}

class PokedexApp extends StatefulWidget {
  const PokedexApp({super.key});

  @override
  State<PokedexApp> createState() => _PokedexAppState();
}

class _PokedexAppState extends State<PokedexApp> with TickerProviderStateMixin {
  Set<String> favorites = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFavorites();
    Provider.of<ThemeProvider>(context, listen: false).loadThemePreference();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = prefs.getStringList('favorites')?.toSet() ?? {};
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Pokédex',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          home: SplashScreen(
            onInitializationComplete: () => Scaffold(
              appBar: AppBar(
                title: const Text('Pokédex'),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        _tabController.animateTo(
                          3,
                        ); // Navigate to the Settings tab
                      },
                      child: const CircleAvatar(
                        backgroundImage: NetworkImage(
                          'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg',
                        ),
                      ),
                    ),
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.home), text: 'Home'),
                    Tab(icon: Icon(Icons.favorite), text: 'Favoritos'),
                    Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
                    Tab(icon: Icon(Icons.settings), text: 'Configuraçoes'),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  HomeScreen(
                    onToggleFavorite: _toggleFavorite,
                    favorites: favorites,
                  ),
                  FavoritesScreen(favorites: favorites),
                  StatsScreen(),
                  SettingsScreen(),
                ],
              ),
            ),
          ),
          routes: {
            '/detail': (ctx) {
              final pokemon =
                  ModalRoute.of(ctx)!.settings.arguments
                      as Map<String, dynamic>;
              return DetailScreen(
                pokemon: pokemon,
                isFavorite: favorites.contains(pokemon['name']),
                onToggleFavorite: _toggleFavorite,
              );
            },
            '/about': (context) => AboutScreen(),
          },
        );
      },
    );
  }

  void _toggleFavorite(String name) {
    setState(() {
      if (favorites.contains(name)) {
        favorites.remove(name);
      } else {
        favorites.add(name);
      }
      _saveFavorites();
    });
  }
}

class SplashScreen extends StatefulWidget {
  final Widget Function() onInitializationComplete;

  const SplashScreen({super.key, required this.onInitializationComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return widget.onInitializationComplete();
    } else {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CircularProgressIndicator()],
          ),
        ),
      );
    }
  }
}

enum SortOption { nameAsc, nameDesc, idAsc, idDesc }

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
        default:
          return 0;
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

class PokemonCard extends StatelessWidget {
  final String pokemonName;
  final String imageUrl;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final Color backgroundColor;

  const PokemonCard({
    super.key,
    required this.pokemonName,
    required this.imageUrl,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: isFavorite ? Colors.red.shade200 : backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Hero(
                    tag: 'pokemon_image_$pokemonName',
                    child: Image.network(imageUrl, fit: BoxFit.contain),
                  ),
                ),
                Text(
                  pokemonName.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  onPressed: onToggleFavorite,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

class FavoritesScreen extends StatelessWidget {
  final Set<String> favorites;

  const FavoritesScreen({super.key, required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: favorites.isEmpty
          ? const Center(child: Text('Nenhum favorito adicionado ainda.'))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final name = favorites.elementAt(index);
                return Card(child: ListTile(title: Text(name)));
              },
            ),
    );
  }
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<dynamic> pokemons = [];
  bool loading = true;
  String error = '';
  Map<String, dynamic> pokemonDetailsCache = {};

  @override
  void initState() {
    super.initState();
    fetchPokemons();
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
      final List<dynamic> results = data['results'];

      List<Future<Map<String, dynamic>?>> detailFutures = results
          .map((pokemon) => fetchPokemonDetails(pokemon['url']))
          .toList();
      List<Map<String, dynamic>?> detailResults = await Future.wait(
        detailFutures,
      );

      List<dynamic> validPokemons = [];
      for (int i = 0; i < results.length; i++) {
        if (detailResults[i] != null) {
          validPokemons.add(detailResults[i]);
          pokemonDetailsCache[results[i]['url']] = detailResults[i];
        }
      }

      setState(() {
        pokemons = validPokemons;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load data.';
        loading = false;
      });
    }
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

  double getAverageWeight() {
    if (pokemons.isEmpty) return 0;
    double totalWeight = 0;
    for (var pokemon in pokemons) {
      totalWeight += (pokemon['weight'] as num).toDouble();
    }
    return totalWeight / pokemons.length;
  }

  double getAverageHeight() {
    if (pokemons.isEmpty) return 0;
    double totalHeight = 0;
    for (var pokemon in pokemons) {
      totalHeight += (pokemon['height'] as num).toDouble();
    }
    return totalHeight / pokemons.length;
  }

  Map<String, int> getTypeCounts() {
    Map<String, int> typeCounts = {};
    for (var pokemon in pokemons) {
      List<dynamic> types = pokemon['types'];
      for (var type in types) {
        String typeName = type['type']['name'];
        typeCounts[typeName] = (typeCounts[typeName] ?? 0) + 1;
      }
    }
    return typeCounts;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (error.isNotEmpty) {
      return Center(child: Text(error));
    } else {
      double avgWeight = getAverageWeight();
      double avgHeight = getAverageHeight();
      Map<String, int> typeCounts = getTypeCounts();

      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peso médio: ${avgWeight.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Altura média: ${avgHeight.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Distribuição de tipos:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: typeCounts.length,
                  itemBuilder: (context, index) {
                    String typeName = typeCounts.keys.elementAt(index);
                    int count = typeCounts[typeName]!;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColorForType(typeName),
                      ),
                      title: Text('$typeName: $count'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'fire':
        return Colors.red.shade200;
      case 'water':
        return Colors.blue.shade200;
      case 'grass':
        return Colors.green.shade200;
      case 'electric':
        return Colors.yellow.shade200;
      case 'poison':
        return Colors.purple.shade200;
      case 'ground':
        return Colors.brown.shade200;
      case 'flying':
        return Colors.cyan.shade200;
      case 'bug':
        return Colors.lightGreen.shade200;
      case 'rock':
        return Colors.grey.shade400;
      case 'ghost':
        return Colors.deepPurple.shade200;
      case 'dragon':
        return Colors.indigo.shade200;
      case 'steel':
        return Colors.blueGrey.shade200;
      case 'dark':
        return Colors.grey.shade900;
      case 'fairy':
        return Colors.pink.shade200;
      case 'ice':
        return Colors.lightBlue.shade200;
      case 'psychic':
        return Colors.pinkAccent.shade200;
      case 'normal':
        return Colors.grey.shade300;
      case 'fighting':
        return Colors.orange.shade200;
      default:
        return Colors.grey;
    }
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('configs'),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/about');
              },
              child: const Text('About'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Tema: '),
                DropdownButton<ThemeMode>(
                  value: themeProvider.themeMode,
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('Sistema'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Pokedex',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text('Versão: 1.0.0'),
            const Text('Desenvolvedor: João Geraldo'),
            InkWell(
              child: const Text(
                'GitHub Repositorio',
                style: TextStyle(color: Colors.blue),
              ),
              onTap: () async {
                const url = 'https://github.com/geraldojoao/PokeDex';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  throw 'Could not launch $url';
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Este é um aplicativo Pokedex simples,feito Por João Geraldo.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
