import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/database_service.dart'; // Importação do banco de dados
import 'detector_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = false;
  String _mensagemErro = '';

  Future<void> _fazerLogin() async {
    setState(() {
      _isLoading = true;
      _mensagemErro = '';
    });

    String email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _mensagemErro = 'Por favor, insira o seu e-mail corporativo.';
        _isLoading = false;
      });
      return;
    }

    try {
      // BUSCA O USER NO BANCO DE DADOS
      final usuario = await DatabaseService.instance.fazerLoginPorEmail(email);

      // Verifica se o e-mail devolveu algum resultado do banco
      if (usuario == null) {
        setState(() {
          _mensagemErro = 'E-mail não encontrado. Verifique ou realize o cadastro.';
          _isLoading = false;
        });
        return;
      }

      // 2. EXTRAI O NOME GRAVADO NO CADASTRO
      String nomeCondutor = usuario['nome'] ?? 'Condutor';

      // 3. VALIDAÇÃO BIOMÉTRICA
      bool autenticado = await _auth.authenticate(
        localizedReason: 'Por favor, autentique-se para iniciar a viagem',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (autenticado) {
        if (!mounted) return;
        // 4. ENCAMINHA PARA A CÂMARA COM O NOME REAL DA BASE DE DADOS
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DetectorScreen(nomeFuncionario: nomeCondutor),
          ),
        );
      } else {
        setState(() {
          _mensagemErro = 'Falha na autenticação biométrica.';
        });
      }
    } catch (e) {
      setState(() {
        _mensagemErro = 'Erro ao processar login: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.greenAccent),
              const SizedBox(height: 20),
              const Text(
                "LOGIN CORPORATIVO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Campo de E-mail
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'E-mail Corporativo',
                  labelStyle: const TextStyle(color: Colors.greenAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.greenAccent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.greenAccent),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Mensagem de Erro
              if (_mensagemErro.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _mensagemErro,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),

              // Botão de Login POR BIOMETRIA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isLoading ? null : _fazerLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fingerprint),
                      SizedBox(width: 10),
                      Text("ENTRAR COM BIOMETRIA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botão de Cadastro
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                  );
                },
                child: const Text(
                  "Novo condutor? Realizar cadastro",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}