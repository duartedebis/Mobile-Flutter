import 'package:flutter/material.dart';
import 'api_handler.dart';

class GameLogicManager extends ChangeNotifier {
  final ApiHandler _apiHandler = ApiHandler();

  ApiPlayer? _activeUser;
  ApiPlayer? get activeUser => _activeUser;

  List<ApiPlayer> _opponentList = [];
  List<ApiPlayer> get opponentList => _opponentList;

  ApiPlayer? _chosenOpponent;
  ApiPlayer? get chosenOpponent => _chosenOpponent;

  String? _matchOutcomeMessage;
  String? get matchOutcomeMessage => _matchOutcomeMessage;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _wagerConfirmation;
  String? get wagerConfirmation => _wagerConfirmation;

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  Future<bool> loginUser(String alias) async {
    _setProcessing(true);
    _activeUser = await _apiHandler.authenticateUser(alias);
    if (_activeUser != null) {
      await loadOpponents();
    }
    _setProcessing(false);
    return _activeUser != null;
  }

  Future<void> loadOpponents() async {
    _setProcessing(true);
    List<ApiPlayer> allPlayers = await _apiHandler.fetchContenders();
    if (_activeUser != null) {
      _opponentList = allPlayers
          .where((p) => p.alias != _activeUser!.alias)
          .toList();
    } else {
      _opponentList = allPlayers;
    }

    if (_chosenOpponent != null) {
      final String previousOpponentAlias = _chosenOpponent!.alias;
      _chosenOpponent = _opponentList.cast<ApiPlayer?>().firstWhere(
        (p) => p?.alias == previousOpponentAlias,
        orElse: () => null,
      );
      if (_chosenOpponent == null && _opponentList.isNotEmpty) {
        _chosenOpponent = _opponentList.first;
      } else if (_opponentList.isEmpty) {
        _chosenOpponent = null;
      }
    }
    _setProcessing(false);
  }

  Future<void> refreshActiveUserScore() async {
    if (_activeUser == null) {
      return;
    }
    _setProcessing(true);
    ApiPlayer? updatedUser = await _apiHandler.fetchUserScore(
      _activeUser!.alias,
    );
    if (updatedUser != null) {
      _activeUser = updatedUser;
    }
    _setProcessing(false);
  }

  void selectOpponent(ApiPlayer opponent) {
    _chosenOpponent = opponent;
    notifyListeners();
  }

  Future<bool> makeWager(int amount, int number, int parImparSelection) async {
    if (_activeUser == null) {
      return false;
    }
    _setProcessing(true);
    _wagerConfirmation = null;
    bool success = await _apiHandler.submitWager(
      _activeUser!.alias,
      amount,
      parImparSelection,
      number,
    );
    _wagerConfirmation = success
        ? "Aposta registrada!"
        : "Falha ao registrar aposta.";
    _setProcessing(false);
    return success;
  }

  Future<void> playMatch() async {
    if (_activeUser == null || _chosenOpponent == null) {
      return;
    }
    if (_wagerConfirmation == null ||
        !_wagerConfirmation!.contains("registrada")) {
      return;
    }

    _setProcessing(true);
    _matchOutcomeMessage = null;

    Map<String, dynamic>? outcome = await _apiHandler.initiateMatch(
      _activeUser!.alias,
      _chosenOpponent!.alias,
    );

    if (outcome != null &&
        outcome.containsKey('vencedor') &&
        outcome.containsKey('perdedor')) {
      final winnerData = outcome['vencedor'];
      final loserData = outcome['perdedor'];
      _matchOutcomeMessage =
          'Vencedor: ${winnerData['username']} (${winnerData['parimpar'] == 2 ? 'Par' : 'Ímpar'} com ${winnerData['numero']})\n'
          'Perdedor: ${loserData['username']} (${loserData['parimpar'] == 2 ? 'Par' : 'Ímpar'} com ${loserData['numero']})';
    } else {
      _matchOutcomeMessage = 'Erro na partida. Verifique as apostas.';
    }

    await refreshActiveUserScore();
    await loadOpponents();
    _wagerConfirmation = null;
    _setProcessing(false);
  }

  void clearMatchOutcome() {
    _matchOutcomeMessage = null;
    notifyListeners();
  }
}
