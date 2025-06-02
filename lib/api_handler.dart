import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiPlayer {
  String alias;
  int score;

  ApiPlayer({required this.alias, required this.score});

  factory ApiPlayer.fromJson(Map<String, dynamic> json) {
    return ApiPlayer(alias: json['username'], score: json['pontos'] ?? 0);
  }
}

class ApiHandler {
  static const String _apiBaseUrl = 'https://par-impar.glitch.me';

  Future<ApiPlayer?> authenticateUser(String userAlias) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/novo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': userAlias}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['usuarios'] != null && (data['usuarios'] as List).isNotEmpty) {
          var userData = (data['usuarios'] as List).firstWhere(
            (u) => u['username'] == userAlias,
            orElse: () => data['usuarios'][0],
          );
          return ApiPlayer.fromJson(userData);
        } else if (data['username'] != null) {
          return ApiPlayer.fromJson(data);
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<List<ApiPlayer>> fetchContenders() async {
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/jogadores'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['jogadores'] != null) {
          List<dynamic> playerList = data['jogadores'];
          return playerList.map((json) => ApiPlayer.fromJson(json)).toList();
        }
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<bool> submitWager(
    String userAlias,
    int wagerAmount,
    int choiceType,
    int chosenNumber,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/aposta'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': userAlias,
          'valor': wagerAmount,
          'parimpar': choiceType,
          'numero': chosenNumber,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> initiateMatch(
    String playerOneAlias,
    String playerTwoAlias,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/jogar/$playerOneAlias/$playerTwoAlias'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<ApiPlayer?> fetchUserScore(String userAlias) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/pontos/$userAlias'),
      );
      if (response.statusCode == 200) {
        return ApiPlayer.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
