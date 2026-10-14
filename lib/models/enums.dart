/// Enums = conjuntos fixos de valores. Usar enum evita erros de digitação
/// (ex: 'emAnalise' escrito de duas formas diferentes).

/// Tipos de equipamento aceitos pela assistência (RF02)
enum TipoEquipamento {
  notebook('Notebook'),
  desktop('Desktop'),
  console('Console'),
  controle('Controle'),
  celular('Celular'),
  tablet('Tablet'),
  outro('Outro');

  const TipoEquipamento(this.rotulo);

  /// Texto amigável exibido na tela
  final String rotulo;
}

/// Status lógicos da Ordem de Serviço (seção 4 dos requisitos).
/// O rótulo é o que o cliente vê no portal de rastreio.
enum StatusOrdem {
  recebido('Recebido na Assistência'),
  emAnalise('Em Análise'),
  aguardandoAprovacao('Aguardando Aprovação'),
  emManutencao('Em Manutenção'),
  aguardandoPeca('Aguardando Peça'),
  prontoRetirada('Pronto para Retirada'),
  entregue('Entregue / Finalizado'),
  devolvidoSemConserto('Devolvido sem Conserto');

  const StatusOrdem(this.rotulo);

  final String rotulo;

  /// Indica se a OS terminou. Depois disso o status não pode mais mudar.
  bool get isFinal => this == entregue || this == devolvidoSemConserto;

  /// REGRA DE NEGÓCIO: quais status podem vir logo depois deste.
  /// Isso garante que a OS siga o fluxo da seção 4 e não pule etapas.
  List<StatusOrdem> get proximosPermitidos => switch (this) {
        recebido => [emAnalise],
        emAnalise => [aguardandoAprovacao, devolvidoSemConserto],
        aguardandoAprovacao => [emManutencao, devolvidoSemConserto],
        emManutencao => [aguardandoPeca, prontoRetirada, devolvidoSemConserto],
        aguardandoPeca => [emManutencao, devolvidoSemConserto],
        prontoRetirada => [entregue],
        entregue || devolvidoSemConserto => [],
      };
}

/// Decisão do cliente sobre o orçamento (RF07 e RF09)
enum DecisaoOrcamento { pendente, aprovado, recusado }

/// Tipo da foto: estado ao receber ou ao finalizar o conserto (RF05)
enum TipoFoto { entrada, saida }

/// Documentos em PDF previstos no RF10
enum TipoDocumento {
  /// Termo de Recebimento: documento de entrada do aparelho
  termoRecebimento('TERMO DE RECEBIMENTO'),

  /// Recibo e Termo de Garantia: documento de saída, após o conserto
  reciboGarantia('RECIBO E TERMO DE GARANTIA');

  const TipoDocumento(this.titulo);

  /// Título impresso no topo do documento
  final String titulo;
}