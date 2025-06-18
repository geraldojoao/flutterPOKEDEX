import 'package:flutter/material.dart';
import '../utils/type_colors.dart';
import '../services/pokemon_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<dynamic> pokemons = [];
  bool loading = true;
  String error = '';

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
      final results = await PokemonService.fetchPokemons(limit: 100);
      setState(() {
        pokemons = results;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Falha ao carregar dados.';
        loading = false;
      });
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
                        backgroundColor: typeColors[typeName] ?? Colors.grey,
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
}
