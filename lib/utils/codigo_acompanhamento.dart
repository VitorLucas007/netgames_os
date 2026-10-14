import 'dart:math';

/// Gera o código secreto que faz parte do link de acompanhamento do cliente.
///
/// Por que não usar o id do banco? Ids são curtos e previsíveis.
/// Este código tem 24 caracteres (~120 bits de aleatoriedade), então não pode ser adivinhado.
/// Usa Random.secure(), gerador criptográfico do Dart.
///
/// O alfabeto omite caracteres parecidos (0/o, 1/l/i) para facilitar a digitação.
const _alfabeto = 'abcdefghjkmnpqrstuvwxyz23456789';

String gerarCodigoAcompanhamento({int tamanho = 24}) {
  final gerador = Random.secure();
  return List.generate(tamanho, (_) => _alfabeto[gerador.nextInt(_alfabeto.length)]).join();
}