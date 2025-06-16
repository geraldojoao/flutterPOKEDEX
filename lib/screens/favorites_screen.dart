import 'package:flutter/material.dart';

final List<Map<String, dynamic>> listaDePokemons = [
  {
    'id': 63,
    'name': 'abra',
    'types': ['psychic'],
    'height': 9,
    'weight': 195,
    'stats': {'hp': 25, 'attack': 20, 'defense': 15},
  },
  {
    'id': 65,
    'name': 'alakazam',
    'types': ['psychic'],
    'height': 15,
    'weight': 480,
    'stats': {'hp': 55, 'attack': 50, 'defense': 45},
  },
  {
    'id': 69,
    'name': 'bellsprout',
    'types': ['grass', 'poison'],
    'height': 7,
    'weight': 40,
    'stats': {'hp': 50, 'attack': 75, 'defense': 35},
  },
  {
    'id': 35,
    'name': 'clefairy',
    'types': ['fairy'],
    'height': 6,
    'weight': 75,
    'stats': {'hp': 70, 'attack': 45, 'defense': 48},
  },
  {
    'id': 85,
    'name': 'dodrio',
    'types': ['normal', 'flying'],
    'height': 18,
    'weight': 852,
    'stats': {'hp': 60, 'attack': 110, 'defense': 70},
  },
];

final Map<int, String> pokemonNames = {
  for (var pokemon in listaDePokemons)
    pokemon['id'] as int: pokemon['name'] as String,
};

class FavoritesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> favorites;

  const FavoritesScreen({super.key, required this.favorites});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late List<Map<String, dynamic>> _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = List<Map<String, dynamic>>.from(widget.favorites);
  }

  void _removeFavorite(int id) {
    setState(() {
      _favorites.removeWhere((pokemon) => pokemon['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: _favorites.isEmpty
          ? const Center(child: Text('Nenhum favorito adicionado ainda.'))
          : ListView.builder(
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final pokemon = _favorites[index];
                final id = pokemon['id'];
                final name = pokemon['name'];
                final imageUrl =
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';

                return Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/detail',
                        arguments: pokemon,
                      );
                    },
                    leading: Image.network(
                      imageUrl,
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error),
                    ),
                    title: Text('$name #$id'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeFavorite(id),
                      tooltip: 'Remover dos favoritos',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
