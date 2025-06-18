import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            const Text('Configurações'),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/about');
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
                      themeProvider.setTheme(value);
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
                'GitHub Repositório',
                style: TextStyle(color: Colors.blue),
              ),
              onTap: () async {
                // Use url_launcher aqui se desejar
                // Exemplo de uso:
                // await launchUrl(Uri.parse('https://github.com/geraldojoao/PokeDex'));
              },
            ),
          ],
        ),
      ),
    );
  }
}
