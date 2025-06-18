import 'dart:convert';
import 'package:http/http.dart' as http;

class PokemonService {
  static const String baseUrl = 'https://pokeapi.co/api/v2';
  static const int defaultLimit = 100;
  static const int defaultOffset = 0;
  static const String defaultType = 'normal';
  static Future<List<dynamic>> fetchPokemons({
    int limit = defaultLimit,
    int offset = defaultOffset,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pokemon?limit=$limit&offset=$offset'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Erro ao buscar pokémons');
    }
  }

  /// Busca detalhes de um pokémon pela URL
  static Future<Map<String, dynamic>> fetchPokemonDetails(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erro ao buscar detalhes do pokémon');
    }
  }

  /// Busca todos os tipos de pokémon
  static Future<List<String>> fetchTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/type'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map<String>((type) => type['name'] as String)
          .toList();
    } else {
      throw Exception('Erro ao buscar tipos');
    }
  }
}
