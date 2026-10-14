import '../models/cliente.dart';
import '../utils/validadores.dart';

/// VIEWMODEL do cadastro de cliente (RF01).
/// Guarda o que o usuário digita, valida os campos e gera o Model Cliente.
class ClienteViewModel {
  // Campos de texto. A View atualiza estes valores a cada tecla digitada.
  // Não chamamos notifyListeners aqui porque o próprio TextField já mostra o texto.
  String nome = '';
  String whatsapp = '';
  String cpf = '';
  String email = '';

  // Validadores: retornam null se estiver ok, ou a mensagem de erro.
  // A View usa estes métodos no parâmetro validator: de cada campo.
  String? validarNome(String? valor) =>
      (valor == null || valor.trim().length < 3) ? 'Informe o nome completo' : null;

  String? validarWhatsapp(String? valor) {
    final numeros = apenasNumeros(valor ?? '');
    // DDD (2 dígitos) + número (8 ou 9 dígitos)
    return (numeros.length == 10 || numeros.length == 11)
        ? null
        : 'Informe o WhatsApp com DDD';
  }

  String? validarCpf(String? valor) =>
      cpfValido(valor ?? '') ? null : 'CPF inválido';

  String? validarEmail(String? valor) =>
      emailValido(valor ?? '') ? null : 'E-mail inválido';

  /// Gera o Model Cliente somente se todos os campos forem válidos.
  /// Se algum estiver errado, devolve null.
  Cliente? toModel() {
    if (validarNome(nome) != null ||
        validarWhatsapp(whatsapp) != null ||
        validarCpf(cpf) != null ||
        validarEmail(email) != null) {
      return null;
    }
    return Cliente(
      nome: nome.trim(),
      whatsapp: apenasNumeros(whatsapp),
      cpf: apenasNumeros(cpf),
      email: email.trim(),
    );
  }
}