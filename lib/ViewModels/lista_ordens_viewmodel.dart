import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/ordem_servico.dart';
import '../Repositories/ordem_servico_repository.dart';

/// VIEWMODEL da tela inicial, com a lista de OS e o filtro por status.
class ListaOrdensViewModel extends ChangeNotifier {
  final OrdemServicoRepository _repositorio;

  ListaOrdensViewModel(this._repositorio);

  List<OrdemServico> _ordens = [];
  StatusOrdem? _filtroStatus; // null = mostrar todas
  bool _carregando = false;

  bool get carregando => _carregando;
  StatusOrdem? get filtroStatus => _filtroStatus;

  /// Lista exibida na tela, já aplicando o filtro escolhido
  List<OrdemServico> get ordensFiltradas => _filtroStatus == null
      ? _ordens
      : _ordens.where((o) => o.status == _filtroStatus).toList();

  /// Busca as OS no repositório, da mais recente para a mais antiga
  Future<void> carregar() async {
    _carregando = true;
    notifyListeners();
    try {
      final lista = await _repositorio.listarTodas();
      _ordens = [...lista]..sort((a, b) => b.dataAbertura.compareTo(a.dataAbertura));
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  void filtrarPorStatus(StatusOrdem? status) {
    _filtroStatus = status;
    notifyListeners();
  }
}