import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';

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
                Navigator.pushNamed(context, '/Sobre');
              },
              child: const Text('Sobre'),
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
                      child: Text('Claro'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Escuro'),
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
                  throw 'Não foi possível abrir $url';
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
