import 'package:flutter/material.dart';
import 'package:par_impar_game/game_logic_manager.dart';
import 'package:par_impar_game/styled_button.dart';
import 'package:par_impar_game/play_view.dart';
import 'package:provider/provider.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _aliasController = TextEditingController();

  Future<void> _performLogin() async {
    if (_aliasController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira seu apelido.')),
      );
      return;
    }
    final manager = Provider.of<GameLogicManager>(context, listen: false);
    bool success = await manager.loginUser(_aliasController.text.trim());

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PlayView()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao autenticar. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<GameLogicManager>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identificação - Par ou Ímpar Pro'),
        backgroundColor: Colors.indigoAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Bem-vindo!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _aliasController,
                decoration: InputDecoration(
                  labelText: 'Seu Apelido',
                  hintText: 'Ex: JogadorX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 25),
              manager.isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : StyledButton(
                      label: 'Entrar no Jogo',
                      onPressed: _performLogin,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
