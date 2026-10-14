import 'dart:math';

/// Alfabeto sem caracteres parecidos (0/O, 1/I/L), para o cliente não se confundir ao digitar.
/// Tem 32 caracteres, o que facilita sortear de forma uniforme com nextInt.
const _alfabeto = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// Gera o código secreto que vai no link de acompanhamento.
/// Random.secure é um gerador criptográfico, então o código não pode ser previsto.
/// 20 caracteres deste alfabeto dão cerca de 100 bits de entropia.
String gerarCodigoAcesso({int tamanho = 20}) {
  final sorteio = Random.secure();
  return List.generate(
    tamanho,
    (_) => _alfabeto[sorteio.nextInt(_alfabeto.length)],
  ).join();
}