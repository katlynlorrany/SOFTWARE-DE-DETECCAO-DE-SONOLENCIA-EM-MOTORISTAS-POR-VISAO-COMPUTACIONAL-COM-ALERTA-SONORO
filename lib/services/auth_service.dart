import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  final _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> autenticarFuncionario(String matricula) async {
    try {
      // Verifica se o dispositivo suporta biometria e se há bloqueio de ecrã ativo
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      bool isSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics && !isSupported) {
        return false;
      }

      bool authenticated = await _auth.authenticate(
        localizedReason: 'Autentique-se para aceder ao sistema da empresa',
        options: const AuthenticationOptions(
          biometricOnly: true, // Força o uso exclusivo de biometria/facial
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        // Salva a sessão de forma encriptada no hardware do telemóvel
        await _secureStorage.write(key: 'sessao_ativa', value: matricula);
        return true;
      }
      return false;
    } catch (e) {
      // Tratar erro de biometria se necessário
      return false;
    }
  }

  // verificar se já existe uma sessão ativa
  Future<String?> obterSessaoAtiva() async {
    return await _secureStorage.read(key: 'sessao_ativa');
  }

  // terminar a sessão (Logout)
  Future<void> fazerLogout() async {
    await _secureStorage.delete(key: 'sessao_ativa');
  }
}