import 'package:flutter/material.dart';
import 'package:flutter_application_5/app/pokedex_app.dart';
import 'package:flutter_application_5/providers/theme_provider.dart';
import 'package:provider/provider.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (context) => ThemeProvider(),
    child: PokedexApp(),
  ),
);
