import '../models/ordem_servico.dart';
import '../models/visao_cliente.dart';

/// CONTRATO de acesso aos dados de OS.
/// Os ViewModels dependem SOMENTE desta interface.
/// Ao entrar o Firebase, criamos OrdemServicoRepositoryFirebase com a mesma interface.
abstract class OrdemServicoRepository {
  Future<List<OrdemServico>> listarTodas();

  Future<OrdemServico?> buscarPorId(String id);

  /// Todas as OS que já passaram por um equipamento com este número de série (RF03)
  Future<List<OrdemServico>> buscarPorNumeroSerie(String numeroSerie);

  /// Acesso do cliente pelo link de acompanhamento.
  /// Devolve null se o código não existe OU se o link já expirou.
  /// Com o Firebase, esta mesma regra será escrita nas regras de segurança do Firestore.
  Future<VisaoCliente?> buscarAcompanhamento(String codigoAcompanhamento);

  /// Cria a OS (se não tiver id) ou atualiza (se tiver). Devolve a OS com id.
  Future<OrdemServico> salvar(OrdemServico ordem);
}

/// Implementação provisória que guarda tudo na memória do app.
class OrdemServicoRepositoryMemoria implements OrdemServicoRepository {
  final Map<String, OrdemServico> _banco = {};

  @override
  Future<List<OrdemServico>> listarTodas() async => _banco.values.toList();

  @override
  Future<OrdemServico?> buscarPorId(String id) async => _banco[id];

  @override
  Future<List<OrdemServico>> buscarPorNumeroSerie(String numeroSerie) async {
    final alvo = numeroSerie.trim().toUpperCase();
    return _banco.values
        .where((o) => o.equipamento.numeroSerie.trim().toUpperCase() == alvo)
        .toList();
  }

  @override
  Future<VisaoCliente?> buscarAcompanhamento(String codigoAcompanhamento) async {
    for (final ordem in _banco.values) {
      if (ordem.codigoAcompanhamento == codigoAcompanhamento) {
        // Link expirado: a OS existe, mas o cliente não recebe nada
        return ordem.linkAtivo ? VisaoCliente.de(ordem) : null;
      }
    }
    return null;
  }

  @override
  Future<OrdemServico> salvar(OrdemServico ordem) async {
    final id = ordem.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final salva = ordem.copyWith(id: id);
    _banco[id] = salva;
    return salva;
  }
}