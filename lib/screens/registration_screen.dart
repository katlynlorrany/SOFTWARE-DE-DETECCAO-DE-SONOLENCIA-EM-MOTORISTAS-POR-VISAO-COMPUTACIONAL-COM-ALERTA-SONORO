import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'detector_screen.dart';
import '../services/database_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final LocalAuthentication auth = LocalAuthentication();
  final DatabaseService _dbService = DatabaseService.instance;

  // Campos
  final _cpfController = TextEditingController();
  final _nomeController = TextEditingController();
  final _nascimentoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _empresaController = TextEditingController();

  bool _isLoading = false;

  // formatação cpf

  String _formatarCPF(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length > 11) value = value.substring(0, 11);

    var resultado = '';
    for (int i = 0; i < value.length; i++) {
      if (i == 3 || i == 6) {
        resultado += '.';
      } else if (i == 9) {
        resultado += '-';
      }
      resultado += value[i];
    }
    return resultado;
  }

  // Formata a Data
  String _formatarData(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length > 8) value = value.substring(0, 8);

    var resultado = '';
    for (int i = 0; i < value.length; i++) {
      if (i == 2 || i == 4) {
        resultado += '/';
      }
      resultado += value[i];
    }
    return resultado;
  }

  // Formata o Telefone
  String _formatarTelefone(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length > 11) value = value.substring(0, 11);

    var resultado = '';
    for (int i = 0; i < value.length; i++) {
      if (i == 0) {
        resultado += '(';
      } else if (i == 2) {
        resultado += ') ';
      } else if (value.length == 11 && i == 7) {
        resultado += '-';
      } else if (value.length == 10 && i == 6) {
        resultado += '-';
      }
      resultado += value[i];
    }
    return resultado;
  }

  // VALIDAÇÃO

  bool _validarCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;
    return true;
  }

  bool _validarNomeCompleto(String nome) {
    nome = nome.trim();
    List<String> partes = nome.split(RegExp(r'\s+'));
    if (partes.length < 2) return false;

    List<String> abreviacoesProibidas = ['de', 'da', 'do', 'dos', 'das', 'e'];
    for (String parte in partes) {
      if (parte.length <= 1 && !abreviacoesProibidas.contains(parte.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  bool _validarData(String data) {
    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regex.hasMatch(data)) return false;

    try {
      List<String> partes = data.split('/');
      int dia = int.parse(partes[0]);
      int mes = int.parse(partes[1]);
      int ano = int.parse(partes[2]);

      if (mes < 1 || mes > 12) return false;

      List<int> diasNoMes = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
      if ((ano % 4 == 0 && ano % 100 != 0) || (ano % 400 == 0)) {
        diasNoMes[2] = 29;
      }

      if (dia < 1 || dia > diasNoMes[mes]) return false;
      if (ano < 1900 || ano > DateTime.now().year) return false;

      return true;
    } catch (_) {
      return false;
    }
  }

  // VALIDAÇÃO contato e empresa

  bool _validarEmail(String email) {
    email = email.trim();
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  bool _validarTelefone(String telefone) {
    telefone = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    return telefone.length >= 10 && telefone.length <= 11;
  }

  bool _validarEmpresa(String empresa) {
    return empresa.trim().length >= 2;
  }

  Future<bool> _verificarCPFNoBanco(String cpf) async {
    final db = await _dbService.database;
    final cpfLimpo = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    final resultadoCPF = await db.query(
      'funcionarios',
      where: 'cpf = ?',
      whereArgs: [cpfLimpo],
    );

    if (resultadoCPF.isNotEmpty) {
      _mostrarErro("Este CPF já está cadastrado no sistema.");
      return true;
    }
    return false;
  }

  Future<bool> _verificarEmailNoBanco(String email) async {
    final db = await _dbService.database;

    final resultadoEmail = await db.query(
      'funcionarios',
      where: 'email = ?',
      whereArgs: [email.trim()],
    );

    if (resultadoEmail.isNotEmpty) {
      _mostrarErro("Este e-mail corporativo já está cadastrado no sistema.");
      return true;
    }
    return false;
  }

  void _proximaPagina() async {
    if (_currentPage == 0) {
      if (!_validarCPF(_cpfController.text)) {
        _mostrarErro("CPF inválido. Certifique-se de inserir os 11 dígitos.");
        return;
      }
      if (!_validarNomeCompleto(_nomeController.text)) {
        _mostrarErro("Insira o nome completo sem abreviações (mínimo de nome e sobrenome).");
        return;
      }
      if (!_validarData(_nascimentoController.text)) {
        _mostrarErro("Data de nascimento inválida. Use o formato DD/MM/AAAA.");
        return;
      }

      bool cpfExiste = await _verificarCPFNoBanco(_cpfController.text);
      if (cpfExiste) return;
    }

    if (_currentPage == 1) {
      if (!_validarEmail(_emailController.text)) {
        _mostrarErro("E-mail corporativo inválido. Insira no formato correto (ex: nome@empresa.com).");
        return;
      }
      if (!_validarTelefone(_telefoneController.text)) {
        _mostrarErro("Telefone inválido. Insira o número com DDD (10 ou 11 dígitos).");
        return;
      }
      if (!_validarEmpresa(_empresaController.text)) {
        _mostrarErro("Insira o nome válido da empresa vinculada.");
        return;
      }

      bool emailExiste = await _verificarEmailNoBanco(_emailController.text);
      if (emailExiste) return;
    }

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _paginaAnterior() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _concluirCadastroComBiometria() async {
    setState(() => _isLoading = true);

    try {
      bool cpfExiste = await _verificarCPFNoBanco(_cpfController.text);
      if (cpfExiste) {
        setState(() => _isLoading = false);
        return;
      }

      bool emailExiste = await _verificarEmailNoBanco(_emailController.text);
      if (emailExiste) {
        setState(() => _isLoading = false);
        return;
      }

      bool authenticated = await auth.authenticate(
        localizedReason: 'Confirme sua biometria para validar e concluir o cadastro',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );

      if (!mounted) return;

      if (authenticated) {
        await _dbService.inserirFuncionario({
          'cpf': _cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          'nome': _nomeController.text.trim(),
          'data_nascimento': _nascimentoController.text.trim(),
          'email': _emailController.text.trim(),
          'telefone': _telefoneController.text.trim(),
          'empresa': _empresaController.text.trim(),
        });

        setState(() => _isLoading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DetectorScreen(nomeFuncionario: _nomeController.text.trim()),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autenticação cancelada.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na biometria: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentPage > 0) {
              _paginaAnterior();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text("Etapa ${_currentPage + 1} de 3", style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          // TELA 1: Dados Pessoais com Máscaras Automáticas
          _buildStepContainer(
            title: "Dados Pessoais",
            children: [
              _buildTextField(
                controller: _cpfController,
                hint: "CPF",
                type: TextInputType.number,
                onChanged: (value) {
                  final formatado = _formatarCPF(value);
                  _cpfController.value = TextEditingValue(
                    text: formatado,
                    selection: TextSelection.collapsed(offset: formatado.length),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nomeController,
                hint: "Nome Completo",
                type: TextInputType.name,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nascimentoController,
                hint: "Data de Nascimento (DD/MM/AAAA)",
                type: TextInputType.datetime,
                onChanged: (value) {
                  final formatado = _formatarData(value);
                  _nascimentoController.value = TextEditingValue(
                    text: formatado,
                    selection: TextSelection.collapsed(offset: formatado.length),
                  );
                },
              ),
            ],
            onNext: _proximaPagina,
          ),

          // TELA 2: Contato e Empresa
          _buildStepContainer(
            title: "Contato e Empresa",
            children: [
              _buildTextField(
                controller: _emailController,
                hint: "E-mail Corporativo",
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _telefoneController,
                hint: "Telefone / WhatsApp (Com DDD)",
                type: TextInputType.phone,
                onChanged: (value) {
                  final formatado = _formatarTelefone(value);
                  _telefoneController.value = TextEditingValue(
                    text: formatado,
                    selection: TextSelection.collapsed(offset: formatado.length),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _empresaController,
                hint: "Empresa Vinculada",
                type: TextInputType.text,
              ),
            ],
            onNext: _proximaPagina,
          ),

          // Biometria
          _buildStepContainer(
            title: "Segurança Biométrica",
            children: [
              const Icon(Icons.fingerprint, size: 100, color: Colors.greenAccent),
              const SizedBox(height: 20),
              const Text(
                "Para confirmar sua identidade e validar a segurança do cadastro, utilize a biometria do dispositivo.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _concluirCadastroComBiometria,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("CONFIRMAR COM BIOMETRIA", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            onNext: null,
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer({required String title, required List<Widget> children, required VoidCallback? onNext}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Expanded(
            child: ListView(
              children: children,
            ),
          ),
          if (onNext != null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                child: const Text("AVANÇAR", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required TextInputType type,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: type,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        fillColor: const Color(0xFF1A1A1A),
        filled: true,
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}