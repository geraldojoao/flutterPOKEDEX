import 'package:flutter/material.dart';

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Pokedex App')),
        body: Center(child: Text('Welcome to Pokedex!')),
      ),
    );
  }
}
