import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:par_impar_game/api_handler.dart';
import 'package:par_impar_game/game_logic_manager.dart';
import 'package:par_impar_game/styled_button.dart';
import 'package:provider/provider.dart';

class PlayView extends StatefulWidget {
  const PlayView({super.key});

  @override
  State<PlayView> createState() => _PlayViewState();
}

class _PlayViewState extends State<PlayView> {
  final _wagerAmountCtrl = TextEditingController();
  final _chosenNumberCtrl = TextEditingController();
  int? _parImparSelection;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final manager = Provider.of<GameLogicManager>(context, listen: false);
      manager.refreshActiveUserScore();
      manager.loadOpponents();
    });
  }

  void _submitWager(GameLogicManager manager) async {
    if (_wagerAmountCtrl.text.isEmpty ||
        _chosenNumberCtrl.text.isEmpty ||
        _parImparSelection == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos da aposta.')),
      );
      return;
    }
    final amount = int.tryParse(_wagerAmountCtrl.text);
    final number = int.tryParse(_chosenNumberCtrl.text);

    if (amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor da aposta inválido.')),
      );
      return;
    }
    if (number == null || number < 1 || number > 5) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número deve ser entre 1 e 5.')),
      );
      return;
    }

    bool success = await manager.makeWager(amount, number, _parImparSelection!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            manager.wagerConfirmation ??
                (success ? "Aposta OK" : "Falha na aposta"),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _initiateMatch(GameLogicManager manager) async {
    if (manager.chosenOpponent == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um oponente para desafiar.')),
      );
      return;
    }
    if (manager.wagerConfirmation == null ||
        !manager.wagerConfirmation!.contains("registrada")) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa registrar uma aposta válida primeiro.'),
        ),
      );
      return;
    }

    await manager.playMatch();
    if (mounted && manager.matchOutcomeMessage != null) {
      _wagerAmountCtrl.clear();
      _chosenNumberCtrl.clear();
      setState(() {
        _parImparSelection = null;
      });
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Resultado da Partida'),
          content: Text(manager.matchOutcomeMessage!),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(ctx).pop();
                manager.clearMatchOutcome();
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<GameLogicManager>(context);

    if (manager.activeUser == null && manager.isProcessing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Par ou Ímpar Pro'),
          backgroundColor: Colors.indigoAccent,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<GameLogicManager>(
      builder: (context, managerInstance, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              managerInstance.activeUser != null
                  ? 'Jogo: ${managerInstance.activeUser!.alias}'
                  : 'Par ou Ímpar Pro',
            ),
            backgroundColor: Colors.indigoAccent,
            actions: [
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: managerInstance.isProcessing
                    ? null
                    : () {
                        managerInstance.refreshActiveUserScore();
                        managerInstance.loadOpponents();
                      },
              ),
            ],
          ),
          body:
              managerInstance.isProcessing && managerInstance.activeUser == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    managerInstance.refreshActiveUserScore();
                    managerInstance.loadOpponents();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 3,
                          color: Colors.indigo[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'Seus Pontos: ${managerInstance.activeUser?.score ?? "---"}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildWagerSection(managerInstance),
                        const SizedBox(height: 20),
                        _buildOpponentList(managerInstance),
                        const SizedBox(height: 20),
                        StyledButton(
                          label: 'Desafiar Oponente!',
                          onPressed:
                              managerInstance.isProcessing ||
                                  managerInstance.chosenOpponent == null ||
                                  managerInstance.wagerConfirmation == null ||
                                  !managerInstance.wagerConfirmation!.contains(
                                    "registrada",
                                  )
                              ? null
                              : () => _initiateMatch(managerInstance),
                          backgroundColor: Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildWagerSection(GameLogicManager manager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sua Jogada:',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.indigo),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _wagerAmountCtrl,
          decoration: InputDecoration(
            labelText: 'Valor Apostado',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.monetization_on_outlined),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _chosenNumberCtrl,
          decoration: InputDecoration(
            labelText: 'Seu Número (1-5)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.filter_5_outlined),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: 'Par ou Ímpar?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.help_outline),
          ),
          value: _parImparSelection,
          items: const [
            DropdownMenuItem(value: 1, child: Text('Ímpar')),
            DropdownMenuItem(value: 2, child: Text('Par')),
          ],
          onChanged: (value) {
            setState(() {
              _parImparSelection = value;
            });
          },
        ),
        const SizedBox(height: 15),
        Center(
          child: StyledButton(
            label: 'Confirmar Aposta',
            onPressed: manager.isProcessing
                ? null
                : () => _submitWager(manager),
            backgroundColor: Colors.orangeAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildOpponentList(GameLogicManager manager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escolha um Contendor:',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.indigo),
        ),
        const SizedBox(height: 10),
        manager.opponentList.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Nenhum oponente encontrado ou carregando...',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              )
            : Container(
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.indigo.shade100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: manager.opponentList.length,
                  itemBuilder: (ctx, index) {
                    final ApiPlayer opponent = manager.opponentList[index];
                    final bool isSelected =
                        manager.chosenOpponent?.alias == opponent.alias;
                    return Card(
                      elevation: isSelected ? 4 : 1,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: isSelected ? Colors.indigo.shade100 : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? Colors.indigo
                              : Colors.grey.shade300,
                          child: Text(
                            opponent.alias.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                          ),
                        ),
                        title: Text(
                          opponent.alias,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text('Pontuação: ${opponent.score}'),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.indigo,
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () => manager.selectOpponent(opponent),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}
