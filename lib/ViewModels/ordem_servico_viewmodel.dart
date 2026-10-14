import 'package:flutter/foundation.dart';

import '../models/desconto.dart';
import '../models/enums.dart';
import '../models/ordem_servico.dart';
import '../Repositories/ordem_servico_repository.dart';
import '../services/documento_service.dart';

/// VIEWMODEL da tela de detalhe da OS.
/// Cuida de: mudança de status (seção 4), laudo e peças (RF06),
/// fotos (RF05), decisão do orçamento (RF07) e envio de PDFs (RF10 e RF11).
class OrdemServicoViewModel extends ChangeNotifier {
  final OrdemServicoRepository _repositorio;
  final DocumentoService _documentos;
  OrdemServico _ordem;

  bool _salvando = false;
  bool _gerandoDocumento = false;
  String? _erro;

  /// O serviço de documentos pode ser trocado (ex: em testes).
  OrdemServicoViewModel(this._repositorio, this._ordem, {DocumentoService? documentos})
      : _documentos = documentos ?? DocumentoService();

  OrdemServico get ordem => _ordem;
  bool get salvando => _salvando;
  bool get gerandoDocumento => _gerandoDocumento;
  String? get erro => _erro;

  /// Link que o cliente usa para acompanhar a OS (formato lido por codigoAcessoDaUrl).
  /// Na web usa o endereço atual do app; fora dela, o endereço do Firebase Hosting
  /// do projeto.
  String get linkAcompanhamento {
    final base = kIsWeb ? Uri.base.origin : 'https://netgamesos.web.app';
    return '$base/acompanhar/${_ordem.codigoAcompanhamento}';
  }

  /// Status que o técnico pode escolher agora (regra do fluxo)
  List<StatusOrdem> get proximosStatus => _ordem.status.proximosPermitidos;

  /// O recibo só faz sentido depois que o aparelho está pronto ou entregue
  bool get reciboDisponivel =>
      _ordem.status == StatusOrdem.prontoRetirada || _ordem.status == StatusOrdem.entregue;

  /// Grava a OS no repositório e atualiza o estado local.
  Future<void> _persistir(OrdemServico nova) async {
    _salvando = true;
    _erro = null;
    notifyListeners();
    try {
      _ordem = await _repositorio.salvar(nova);
    } catch (e) {
      _erro = 'Não foi possível salvar: $e';
    } finally {
      _salvando = false;
      notifyListeners();
    }
  }

  /// Muda o status respeitando o fluxo. Também registra a mudança na linha do tempo.
  Future<void> avancarStatus(StatusOrdem novoStatus, {String? observacao}) async {
    if (!_ordem.status.proximosPermitidos.contains(novoStatus)) {
      _erro = 'Mudança não permitida: ${_ordem.status.rotulo} → ${novoStatus.rotulo}';
      notifyListeners();
      return;
    }
    await _persistir(_ordem.copyWith(
      status: novoStatus,
      historico: [
        ..._ordem.historico,
        RegistroStatus(status: novoStatus, data: DateTime.now(), observacao: observacao),
      ],
    ));
  }

  /// RF06: salva laudo, peças e valor da mão de obra
  Future<void> salvarLaudo({
    required String laudo,
    required List<Peca> pecas,
    required double maoDeObra,
    Desconto desconto = Desconto.nenhum,
  }) {
    return _persistir(_ordem.copyWith(
      laudoTecnico: laudo.trim(),
      pecas: pecas,
      valorMaoDeObra: maoDeObra,
      desconto: desconto,
    ));
  }

  /// RF05: adiciona uma foto (entrada ou saída)
  Future<void> adicionarFoto(String caminho, TipoFoto tipo) {
    return _persistir(_ordem.copyWith(
      fotos: [
        ..._ordem.fotos,
        FotoOS(caminho: caminho, tipo: tipo, data: DateTime.now()),
      ],
    ));
  }

  /// RF07 / RF09: registra a decisão do cliente e move a OS para o status certo.
  Future<void> registrarDecisao(DecisaoOrcamento decisao) async {
    if (_ordem.status != StatusOrdem.aguardandoAprovacao) {
      _erro = 'A OS não está aguardando aprovação de orçamento.';
      notifyListeners();
      return;
    }

    await _persistir(_ordem.copyWith(decisaoOrcamento: decisao));
    if (_erro != null) return;

    if (decisao == DecisaoOrcamento.aprovado) {
      await avancarStatus(StatusOrdem.emManutencao,
          observacao: 'Orçamento aprovado pelo cliente');
    } else if (decisao == DecisaoOrcamento.recusado) {
      await avancarStatus(StatusOrdem.devolvidoSemConserto,
          observacao: 'Orçamento recusado pelo cliente');
    }
  }

  /// RF10 + RF11: gera o PDF e abre o compartilhamento do celular.
  /// A legenda é curta e não traz dados da OS: quem recebe abre o PDF.
  Future<void> enviarDocumentoWhatsApp(TipoDocumento tipo) async {
    if (tipo == TipoDocumento.reciboGarantia && !reciboDisponivel) {
      _erro = 'O recibo só está disponível quando a OS estiver pronta para retirada.';
      notifyListeners();
      return;
    }

    _gerandoDocumento = true;
    _erro = null;
    notifyListeners();
    try {
      final arquivo = await _documentos.gerarPdf(_ordem, tipo);
      final descricao = tipo == TipoDocumento.termoRecebimento
          ? 'termo de recebimento'
          : 'recibo e termo de garantia';
      await _documentos.compartilhar(
        arquivo,
        legenda: 'Olá, ${_ordem.cliente.nome}! Segue o $descricao da sua OS ${_ordem.codigo}.',
      );
    } catch (e) {
      _erro = 'Não foi possível gerar o documento: $e';
    } finally {
      _gerandoDocumento = false;
      notifyListeners();
    }
  }
}