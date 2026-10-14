import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ordem_servico.dart';
import '../models/visao_cliente.dart';
import 'ordem_servico_repository.dart';

/// Implementação com Cloud Firestore.
///
/// Guarda cada OS em DUAS coleções:
///  - `ordens/{id}`: a OS completa (CPF, senha, contato). Só o técnico logado acessa.
///  - `acompanhamentos/{codigoAcompanhamento}`: cópia pública só com o que o cliente
///    pode ver (a classe VisaoCliente). O id do documento é o código secreto do link.
///
/// Assim o cliente lê apenas o documento do próprio código, sem nunca tocar nos dados
/// sensíveis. A expiração do link também é conferida nas regras (veja firestore.rules).
class OrdemServicoRepositoryFirebase implements OrdemServicoRepository {
  final FirebaseFirestore _db;

  OrdemServicoRepositoryFirebase({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordens => _db.collection('ordens');
  CollectionReference<Map<String, dynamic>> get _acompanhamentos =>
      _db.collection('acompanhamentos');

  @override
  Future<List<OrdemServico>> listarTodas() async {
    final snap = await _ordens.get();
    return snap.docs.map((d) => OrdemServico.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<OrdemServico?> buscarPorId(String id) async {
    final doc = await _ordens.doc(id).get();
    final dados = doc.data();
    return dados == null ? null : OrdemServico.fromMap(doc.id, dados);
  }

  @override
  Future<List<OrdemServico>> buscarPorNumeroSerie(String numeroSerie) async {
    final alvo = numeroSerie.trim().toUpperCase();
    final snap = await _ordens.get();
    return snap.docs
        .map((d) => OrdemServico.fromMap(d.id, d.data()))
        .where((o) => o.equipamento.numeroSerie.trim().toUpperCase() == alvo)
        .toList();
  }

  @override
  Future<VisaoCliente?> buscarAcompanhamento(String codigoAcompanhamento) async {
    final doc = await _acompanhamentos.doc(codigoAcompanhamento).get();
    final dados = doc.data();
    if (dados == null) return null;

    // Confere a expiração também aqui (as regras já bloqueiam, isto é só garantia)
    final expiraEm = (dados['expiraEm'] as Timestamp?)?.toDate();
    if (expiraEm != null && DateTime.now().isAfter(expiraEm)) return null;

    return VisaoCliente.fromMap(dados);
  }

  @override
  Future<OrdemServico> salvar(OrdemServico ordem) async {
    final id = ordem.id ?? _ordens.doc().id;
    final salva = ordem.copyWith(id: id);

    // Link expira N dias depois que a OS é encerrada; enquanto aberta, não expira
    DateTime? expiraEm;
    if (salva.status.isFinal) {
      final fim = salva.historico.isNotEmpty ? salva.historico.last.data : salva.dataAbertura;
      expiraEm = fim.add(const Duration(days: OrdemServico.diasValidadeLinkAposFim));
    }

    // Batch: as duas gravações acontecem juntas ou nenhuma acontece
    final lote = _db.batch();
    lote.set(_ordens.doc(id), salva.toMap());
    lote.set(_acompanhamentos.doc(salva.codigoAcompanhamento), {
      ...VisaoCliente.de(salva).toMap(),
      'expiraEm': expiraEm == null ? null : Timestamp.fromDate(expiraEm),
    });
    await lote.commit();
    return salva;
  }
}
