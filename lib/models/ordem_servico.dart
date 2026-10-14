import 'cliente.dart';
import 'equipamentos.dart';
import 'desconto.dart';
import 'enums.dart';


/// MODEL da Ordem de Serviço (RF04 a RF07).
/// A OS guarda uma CÓPIA do cliente e do equipamento no momento da abertura.
/// Assim, se o cadastro mudar depois, a OS continua com os dados originais.
class OrdemServico {
  /// Id do documento no banco. Nulo enquanto a OS não foi salva.
  final String? id;

  /// Código legível para o cliente, ex: "OS-2026-12345"
  final String codigo;

  /// Código secreto do link de acompanhamento do cliente
  final String codigoAcompanhamento;

  /// Código de acesso secreto da OS
  final String codigoAcesso;

  final Cliente cliente;
  final Equipamento equipamento;

  /// Reclamação/defeito relatado pelo cliente (RF04)
  final String defeitoRelatado;

  /// Status atual (seção 4)
  final StatusOrdem status;

  final DateTime dataAbertura;

  /// Linha do tempo: cada mudança de status fica registrada aqui (RF08)
  final List<RegistroStatus> historico;

  /// Laudo técnico escrito pelo técnico (RF06)
  final String laudoTecnico;

  /// Peças usadas ou necessárias (RF06)
  final List<Peca> pecas;

  /// Valor da mão de obra em reais (RF06)
  final double valorMaoDeObra;

  /// O que o cliente decidiu sobre o orçamento (RF07)
  final DecisaoOrcamento decisaoOrcamento;

  /// Desconto dado pelo dono da loja sobre o orçamento
  final Desconto desconto;

  /// Fotos de entrada e de saída (RF05)
  final List<FotoOS> fotos;

  const OrdemServico({
    this.id,
    required this.codigo,
    required this.codigoAcompanhamento,
    required this.codigoAcesso,
    required this.cliente,
    required this.equipamento,
    required this.defeitoRelatado,
    required this.status,
    required this.dataAbertura,
    required this.historico,
    required this.laudoTecnico,
    required this.pecas,
    required this.valorMaoDeObra,
    required this.decisaoOrcamento,
    required this.fotos,
    this.desconto = Desconto.nenhum,
  });

  /// Total das peças (soma de quantidade x valor unitário)
  double get valorPecas => pecas.fold(0.0, (soma, p) => soma + p.total);

  /// Mão de obra + peças, antes do desconto
  double get subtotal => valorMaoDeObra + valorPecas;

  /// Quanto o desconto tira do subtotal, em reais
  double get valorDesconto => desconto.aplicadoSobre(subtotal);

  /// Valor total do orçamento já com desconto
  double get valorTotal => subtotal - valorDesconto;

  /// Quantos dias o link do cliente continua válido depois que a OS termina.
  static const diasValidadeLinkAposFim = 30;

  /// O link de acompanhamento vale enquanto a OS está aberta e por
  /// [diasValidadeLinkAposFim] dias depois de entregue/devolvida.
  bool get linkAtivo {
    if (!status.isFinal) return true;
    final dataFim = historico.isNotEmpty ? historico.last.data : dataAbertura;
    return DateTime.now().difference(dataFim).inDays < diasValidadeLinkAposFim;
  }

  /// Cria uma cópia da OS trocando apenas os campos informados.
  /// Os models são imutáveis (final), então toda mudança gera uma nova instância.
  OrdemServico copyWith({
    String? id,
    StatusOrdem? status,
    List<RegistroStatus>? historico,
    String? laudoTecnico,
    List<Peca>? pecas,
    double? valorMaoDeObra,
    DecisaoOrcamento? decisaoOrcamento,
    List<FotoOS>? fotos,
    Desconto? desconto,
  }) {
    return OrdemServico(
      id: id ?? this.id,
      codigo: codigo,
      codigoAcompanhamento: codigoAcompanhamento,
      codigoAcesso: codigoAcesso,
      cliente: cliente,
      equipamento: equipamento,
      defeitoRelatado: defeitoRelatado,
      status: status ?? this.status,
      dataAbertura: dataAbertura,
      historico: historico ?? this.historico,
      laudoTecnico: laudoTecnico ?? this.laudoTecnico,
      pecas: pecas ?? this.pecas,
      valorMaoDeObra: valorMaoDeObra ?? this.valorMaoDeObra,
      decisaoOrcamento: decisaoOrcamento ?? this.decisaoOrcamento,
      fotos: fotos ?? this.fotos,
      desconto: desconto ?? this.desconto,
    );
  }

  /// Converte para Map para salvar no banco.
  /// Obs.: no Firebase, a data pode virar Timestamp em vez de texto.
  Map<String, dynamic> toMap() => {
        'codigo': codigo,
        'codigoAcompanhamento': codigoAcompanhamento,
        'codigoAcesso': codigoAcesso,
        'cliente': cliente.toMap(),
        'equipamento': equipamento.toMap(),
        'defeitoRelatado': defeitoRelatado,
        'status': status.name,
        'dataAbertura': dataAbertura.toIso8601String(),
        'historico': historico.map((r) => r.toMap()).toList(),
        'laudoTecnico': laudoTecnico,
        'pecas': pecas.map((p) => p.toMap()).toList(),
        'valorMaoDeObra': valorMaoDeObra,
        'decisaoOrcamento': decisaoOrcamento.name,
        'fotos': fotos.map((f) => f.toMap()).toList(),
        'desconto': desconto.toMap(),
      };

  /// Cria a OS a partir de um Map lido do banco. O [id] vem do próprio documento.
  factory OrdemServico.fromMap(String id, Map<String, dynamic> map) {
    return OrdemServico(
      id: id,
      codigo: map['codigo'] as String,
      codigoAcompanhamento: map['codigoAcompanhamento'] as String,
      codigoAcesso: map['codigoAcesso'] as String,
      cliente: Cliente.fromMap(map['cliente'] as Map<String, dynamic>),
      equipamento: Equipamento.fromMap(map['equipamento'] as Map<String, dynamic>),
      defeitoRelatado: map['defeitoRelatado'] as String,
      status: StatusOrdem.values.byName(map['status'] as String),
      dataAbertura: DateTime.parse(map['dataAbertura'] as String),
      historico: (map['historico'] as List)
          .map((e) => RegistroStatus.fromMap(e as Map<String, dynamic>))
          .toList(),
      laudoTecnico: map['laudoTecnico'] as String,
      pecas: (map['pecas'] as List)
          .map((e) => Peca.fromMap(e as Map<String, dynamic>))
          .toList(),
      // "as num" aceita tanto int quanto double vindos do banco
      valorMaoDeObra: (map['valorMaoDeObra'] as num).toDouble(),
      decisaoOrcamento:
          DecisaoOrcamento.values.byName(map['decisaoOrcamento'] as String),
      fotos: (map['fotos'] as List)
          .map((e) => FotoOS.fromMap(e as Map<String, dynamic>))
          .toList(),
      desconto: Desconto.fromMap(map['desconto'] as Map<String, dynamic>?),
    );
  }
}

/// Um item da linha do tempo: qual status foi definido, quando e por quê.
class RegistroStatus {
  final StatusOrdem status;
  final DateTime data;

  /// Texto opcional, ex: "Orçamento aprovado pelo cliente"
  final String? observacao;

  const RegistroStatus({
    required this.status,
    required this.data,
    this.observacao,
  });

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'data': data.toIso8601String(),
        'observacao': observacao,
      };

  factory RegistroStatus.fromMap(Map<String, dynamic> map) => RegistroStatus(
        status: StatusOrdem.values.byName(map['status'] as String),
        data: DateTime.parse(map['data'] as String),
        observacao: map['observacao'] as String?,
      );
}

/// Uma peça usada no conserto (RF06).
class Peca {
  final String nome;
  final int quantidade;

  /// Valor de uma unidade, em reais.
  /// Obs.: com dinheiro, em produção é mais seguro guardar em centavos (int)
  /// para evitar erros de arredondamento do double.
  final double valorUnitario;

  const Peca({
    required this.nome,
    required this.quantidade,
    required this.valorUnitario,
  });

  /// Valor total desta peça
  double get total => quantidade * valorUnitario;

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'quantidade': quantidade,
        'valorUnitario': valorUnitario,
      };

  factory Peca.fromMap(Map<String, dynamic> map) => Peca(
        nome: map['nome'] as String,
        quantidade: map['quantidade'] as int,
        valorUnitario: (map['valorUnitario'] as num).toDouble(),
      );
}

/// Foto do equipamento (RF05). Por enquanto guarda o caminho local do arquivo.
/// Com o Firebase, o caminho passará a ser uma URL do Firebase Storage.
class FotoOS {
  final String caminho;
  final TipoFoto tipo;
  final DateTime data;

  const FotoOS({
    required this.caminho,
    required this.tipo,
    required this.data,
  });

  Map<String, dynamic> toMap() => {
        'caminho': caminho,
        'tipo': tipo.name,
        'data': data.toIso8601String(),
      };

  factory FotoOS.fromMap(Map<String, dynamic> map) => FotoOS(
        caminho: map['caminho'] as String,
        tipo: TipoFoto.values.byName(map['tipo'] as String),
        data: DateTime.parse(map['data'] as String),
      );
}