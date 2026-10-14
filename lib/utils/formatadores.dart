/// Funções de formatação de texto. Ficam em utils para serem usadas
/// tanto nas telas quanto na geração do PDF.

/// Formata data e hora no padrão brasileiro: 12/10/2026 14:30
String formatarData(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Formata valor em reais: R$ 150,00
String formatarMoeda(double valor) => 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

/// Oculta parte do CPF no documento impresso, por privacidade.
/// 12345678909 vira ***.456.789-**
String mascararCpf(String cpf) {
  if (cpf.length != 11) return cpf;
  return '***.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-**';
}