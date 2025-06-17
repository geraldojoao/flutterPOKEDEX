import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  StatsScreenState createState() => StatsScreenState();
}

class StatsScreenState extends State<StatsScreen> {
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
        error = 'Falha ao carregar dados.';
        loading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> fetchPokemonDetails(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data;
      } else {
        debugPrint('Falha ao buscar detalhes do Pokémon: ${res.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Erro ao buscar detalhes do Pokémon: $e');
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

      final List<Color> chartColors = [
        Colors.red.shade200,
        Colors.blue.shade200,
        Colors.green.shade200,
        Colors.yellow.shade200,
        Colors.purple.shade200,
        Colors.brown.shade200,
        Colors.cyan.shade200,
        Colors.lightGreen.shade200,
        Colors.grey.shade400,
        Colors.deepPurple.shade200,
        Colors.indigo.shade200,
        Colors.blueGrey.shade200,
        Colors.grey.shade900,
        Colors.pink.shade200,
        Colors.lightBlue.shade200,
        Colors.pinkAccent.shade200,
        Colors.grey.shade300,
        Colors.orange.shade200,
        Colors.grey,
      ];

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
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: List.generate(typeCounts.length, (i) {
                        final typeName = typeCounts.keys.elementAt(i);
                        final count = typeCounts[typeName]!;
                        final color = chartColors[i % chartColors.length];
                        return PieChartSectionData(
                          color: color,
                          value: count.toDouble(),
                          title: typeName,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        );
                      }),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: typeCounts.length,
                  itemBuilder: (context, index) {
                    String typeName = typeCounts.keys.elementAt(index);
                    int count = typeCounts[typeName]!;
                    final color = chartColors[index % chartColors.length];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: color),
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
