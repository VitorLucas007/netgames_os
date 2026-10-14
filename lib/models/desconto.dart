/// Como o desconto foi informado pelo dono da loja.
enum TipoDesconto { valor, percentual }

/// DESCONTO do orçamento: o dono escolhe um valor em reais ou uma porcentagem.
class Desconto {
  final TipoDesconto tipo;

  /// Reais (se [tipo] for valor) ou porcentagem de 0 a 100 (se for percentual)
  final double quantidade;

  const Desconto({this.tipo = TipoDesconto.valor, this.quantidade = 0});

  static const nenhum = Desconto();

  bool get existe => quantidade > 0;

  /// Quanto sai do [subtotal], em reais. Nunca passa do subtotal (total não fica negativo).
  double aplicadoSobre(double subtotal) {
    if (!existe || subtotal <= 0) return 0;
    final bruto = tipo == TipoDesconto.percentual
        ? subtotal * (quantidade.clamp(0, 100) / 100)
        : quantidade;
    return bruto > subtotal ? subtotal : bruto;
  }

  /// Texto curto para mostrar na tela, ex: "10%" ou "R$ 20,00"
  String get rotulo => tipo == TipoDesconto.percentual
      ? '${quantidade.toStringAsFixed(quantidade % 1 == 0 ? 0 : 1).replaceAll('.', ',')}%'
      : 'R\$ ${quantidade.toStringAsFixed(2).replaceAll('.', ',')}';

  Map<String, dynamic> toMap() => {'tipo': tipo.name, 'quantidade': quantidade};

  /// Aceita null (OS antigas, salvas antes de existir desconto)
  factory Desconto.fromMap(Map<String, dynamic>? map) => map == null
      ? nenhum
      : Desconto(
          tipo: TipoDesconto.values.byName(map['tipo'] as String),
          quantidade: (map['quantidade'] as num).toDouble(),
        );
}
