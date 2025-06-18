import 'package:flutter/material.dart';

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
                final imageUrl =
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${index + 1}.png';
                return Card(
                  child: ListTile(
                    leading: Image.network(
                      imageUrl,
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.catching_pokemon),
                    ),
                    title: Text(name.toUpperCase()),
                  ),
                );
              },
            ),
    );
  }
}
