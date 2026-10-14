import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/ordem_servico.dart';
import '../utils/codigo_acompanhamento.dart';
import '../utils/codigo_acesso.dart';
import '../Repositories/ordem_servico_repository.dart';
import 'cliente_viewmodel.dart';
import 'equipamento_viewmodel.dart';

/// VIEWMODEL da tela "Nova OS" (RF04 - Abertura Rápida).
/// Junta os dados de cliente, equipamento e defeito em uma única OS.
class NovaOrdemViewModel extends ChangeNotifier {
  final OrdemServicoRepository _repositorio;

  /// Sub-ViewModels: cada um cuida da sua parte do formulário
  final ClienteViewModel cliente = ClienteViewModel();
  final EquipamentoViewModel equipamento;

  /// Reclamação/defeito relatado pelo cliente
  String defeitoRelatado = '';

  bool _salvando = false;
  String? _erro;

  NovaOrdemViewModel(this._repositorio)
      : equipamento = EquipamentoViewModel(_repositorio);

  bool get salvando => _salvando;
  String? get erro => _erro;

  /// Valida tudo e cria a OS com status inicial "Recebido na Assistência".
  /// Devolve a OS salva, ou null se algo deu errado.
  Future<OrdemServico?> abrirOrdem() async {
    final clienteModel = cliente.toModel();
    final equipamentoModel = equipamento.toModel();

    if (clienteModel == null ||
        equipamentoModel == null ||
        defeitoRelatado.trim().isEmpty) {
      _erro = 'Preencha todos os campos obrigatórios.';
      notifyListeners();
      return null;
    }

    _salvando = true;
    _erro = null;
    notifyListeners();

    try {
      final agora = DateTime.now();
      final nova = OrdemServico(
        codigo: _gerarCodigo(agora),
        // Código secreto do link do cliente, criado uma única vez
        codigoAcompanhamento: gerarCodigoAcompanhamento(),
        codigoAcesso: gerarCodigoAcesso(),
        cliente: clienteModel,
        equipamento: equipamentoModel,
        defeitoRelatado: defeitoRelatado.trim(),
        status: StatusOrdem.recebido,
        dataAbertura: agora,
        // Primeiro item da linha do tempo
        historico: [
          RegistroStatus(
            status: StatusOrdem.recebido,
            data: agora,
            observacao: 'Aparelho recebido na assistência',
          ),
        ],
        laudoTecnico: '',
        pecas: const [],
        valorMaoDeObra: 0,
        decisaoOrcamento: DecisaoOrcamento.pendente,
        fotos: const [],
      );
      return await _repositorio.salvar(nova);
    } catch (e) {
      _erro = 'Erro ao salvar a OS: $e';
      return null;
    } finally {
      _salvando = false;
      notifyListeners();
    }
  }

  /// Código provisório no formato OS-ANO-NNNNN.
  /// Com o Firebase, passaremos a usar um contador sequencial.
  String _gerarCodigo(DateTime data) {
    final sufixo = (data.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    return 'OS-${data.year}-$sufixo';
  }

  @override
  void dispose() {
    equipamento.dispose();
    super.dispose();
  }
}