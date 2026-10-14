import 'desconto.dart';
import 'enums.dart';
import 'ordem_servico.dart';

/// VISÃO DO CLIENTE: somente os dados que a página de acompanhamento pode mostrar.
///
/// Por que uma classe separada? Assim a página do cliente nunca recebe
/// senha, CPF, WhatsApp ou e-mail por engano. Ela só recebe o que existe aqui.
/// Por isso, o código do link é usado para buscar esta visão, e não a OS inteira.
class VisaoCliente {
  final String codigo;
  final DateTime dataAbertura;
  final StatusOrdem status;
  final DecisaoOrcamento decisao;

  /// Nome do cliente, para confirmar que a OS é dele
  final String nomeCliente;

  // Dados básicos do aparelho. Senha de acesso NÃO entra aqui.
  final TipoEquipamento tipoEquipamento;
  final String marcaModelo;
  final String numeroSerie;
  final String defeitoRelatado;

  /// Linha do tempo (RF08)
  final List<RegistroStatus> historico;

  /// Laudo técnico (público para o cliente)
  final String laudoTecnico;

  /// Orçamento (RF06)
  final double valorMaoDeObra;
  final List<Peca> pecas;

  /// Fotos de entrada e saída (RF05)
  final List<FotoOS> fotos;

  /// Desconto dado pela loja (já aplicado em [valorTotal])
  final Desconto desconto;

  const VisaoCliente({
    required this.codigo,
    required this.dataAbertura,
    required this.status,
    required this.decisao,
    required this.nomeCliente,
    required this.tipoEquipamento,
    required this.marcaModelo,
    required this.numeroSerie,
    required this.defeitoRelatado,
    required this.historico,
    required this.laudoTecnico,
    required this.valorMaoDeObra,
    required this.pecas,
    required this.fotos,
    this.desconto = Desconto.nenhum,
  });

  double get valorPecas => pecas.fold(0.0, (soma, p) => soma + p.total);
  double get subtotal => valorMaoDeObra + valorPecas;
  double get valorDesconto => desconto.aplicadoSobre(subtotal);
  double get valorTotal => subtotal - valorDesconto;

  /// Formato gravado na coleção pública de acompanhamento (só campos seguros).
  Map<String, dynamic> toMap() => {
        'codigo': codigo,
        'dataAbertura': dataAbertura.toIso8601String(),
        'status': status.name,
        'decisao': decisao.name,
        'nomeCliente': nomeCliente,
        'tipoEquipamento': tipoEquipamento.name,
        'marcaModelo': marcaModelo,
        'numeroSerie': numeroSerie,
        'defeitoRelatado': defeitoRelatado,
        'historico': historico.map((r) => r.toMap()).toList(),
        'laudoTecnico': laudoTecnico,
        'valorMaoDeObra': valorMaoDeObra,
        'pecas': pecas.map((p) => p.toMap()).toList(),
        'fotos': fotos.map((f) => f.toMap()).toList(),
        'desconto': desconto.toMap(),
      };

  factory VisaoCliente.fromMap(Map<String, dynamic> map) => VisaoCliente(
        codigo: map['codigo'] as String,
        dataAbertura: DateTime.parse(map['dataAbertura'] as String),
        status: StatusOrdem.values.byName(map['status'] as String),
        decisao: DecisaoOrcamento.values.byName(map['decisao'] as String),
        nomeCliente: map['nomeCliente'] as String,
        tipoEquipamento: TipoEquipamento.values.byName(map['tipoEquipamento'] as String),
        marcaModelo: map['marcaModelo'] as String,
        numeroSerie: map['numeroSerie'] as String,
        defeitoRelatado: map['defeitoRelatado'] as String,
        historico: (map['historico'] as List)
            .map((e) => RegistroStatus.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        laudoTecnico: map['laudoTecnico'] as String,
        valorMaoDeObra: (map['valorMaoDeObra'] as num).toDouble(),
        pecas: (map['pecas'] as List)
            .map((e) => Peca.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        fotos: (map['fotos'] as List)
            .map((e) => FotoOS.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        desconto: Desconto.fromMap(_mapa(map['desconto'])),
      );

  /// Converte a OS completa na visão pública. Campos sensíveis são descartados aqui.
  factory VisaoCliente.de(OrdemServico o) => VisaoCliente(
        codigo: o.codigo,
        dataAbertura: o.dataAbertura,
        status: o.status,
        decisao: o.decisaoOrcamento,
        nomeCliente: o.cliente.nome,
        tipoEquipamento: o.equipamento.tipo,
        marcaModelo: '${o.equipamento.marca} ${o.equipamento.modelo}',
        numeroSerie: o.equipamento.numeroSerie,
        defeitoRelatado: o.defeitoRelatado,
        historico: o.historico,
        laudoTecnico: o.laudoTecnico,
        valorMaoDeObra: o.valorMaoDeObra,
        pecas: o.pecas,
        fotos: o.fotos,
        desconto: o.desconto,
      );
}
Map<String, dynamic>? _mapa(Object? valor) =>
    valor == null ? null : Map<String, dynamic>.from(valor as Map);
