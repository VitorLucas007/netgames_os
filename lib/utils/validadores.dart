// Funções auxiliares de validação e limpeza de dados.
// Ficam fora dos ViewModels para poderem ser reutilizadas e testadas sozinhas.

/// Remove tudo que não for número. Ex: "123.456.789-09" vira "12345678909"
String apenasNumeros(String texto) => texto.replaceAll(RegExp(r'\D'), '');

/// Valida um CPF usando os dois dígitos verificadores
bool cpfValido(String cpf) {
  final numeros = apenasNumeros(cpf);
  if (numeros.length != 11) return false;

  // Sequências como 111.111.111-11 passam na conta, mas são inválidas
  if (RegExp(r'^(\d)\1{10}$').hasMatch(numeros)) return false;

  final digitos = numeros.split('').map((c) => int.parse(c)).toList();

  // Calcula um dígito verificador usando os primeiros [tamanho] dígitos
  int calcularDigito(int tamanho) {
    var soma = 0;
    for (var i = 0; i < tamanho; i++) {
      soma += digitos[i] * (tamanho + 1 - i);
    }
    final resto = (soma * 10) % 11;
    return resto == 10 ? 0 : resto;
  }

  return calcularDigito(9) == digitos[9] && calcularDigito(10) == digitos[10];
}

/// Verifica se o texto tem formato básico de e-mail (ex: nome@dominio.com)
bool emailValido(String email) =>
    RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(email.trim());