import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/about_screen.dart';

class PokedexApp extends StatefulWidget {
  const PokedexApp({super.key});

  @override
  _PokedexAppState createState() => _PokedexAppState();
}

class _PokedexAppState extends State<PokedexApp> {
  List<Map<String, dynamic>> favorites = [];

  void onToggleFavorite(Map<String, dynamic> pokemon) {
    setState(() {
      final index = favorites.indexWhere((p) => p['id'] == pokemon['id']);
      if (index >= 0) {
        favorites.removeAt(index);
      } else {
        favorites.add(pokemon);
      }
    });
  }

  bool isFavorite(Map<String, dynamic> pokemon) {
    return favorites.any((p) => p['id'] == pokemon['id']);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      home: SplashScreen(onInitializationComplete: () {}),
      routes: {
        '/main': (context) => DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Pokédex'),
              bottom: TabBar(
                tabs: const [
                  Tab(icon: Icon(Icons.home), text: 'Home'),
                  Tab(icon: Icon(Icons.favorite), text: 'Favoritos'),
                  Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
                  Tab(icon: Icon(Icons.settings), text: 'Configuraçoes'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                HomeScreen(
                  favorites: favorites.map((p) => p['id'].toString()).toSet(),
                  onToggleFavorite: (id) {
                    final pokemon = favorites.firstWhere(
                      (p) => p['id'].toString() == id,
                      orElse: () => <String, dynamic>{},
                    );
                    if (pokemon.isNotEmpty) {
                      onToggleFavorite(pokemon);
                    }
                  },
                ),
                FavoritesScreen(favorites: favorites),
                StatsScreen(),
                SettingsScreen(),
              ],
            ),
          ),
        ),
        '/detail': (ctx) {
          final pokemon =
              ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
          return DetailScreen(
            pokemon: pokemon,
            isFavorite: isFavorite(pokemon),
            onToggleFavorite: (id) => onToggleFavorite(pokemon),
          );
        },
        '/about': (context) => AboutScreen(),
      },
    );
  }
}
