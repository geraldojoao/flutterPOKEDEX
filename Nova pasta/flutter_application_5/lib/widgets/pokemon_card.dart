import 'package:flutter/material.dart';

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
