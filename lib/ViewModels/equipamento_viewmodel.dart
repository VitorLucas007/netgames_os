import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/equipamentos.dart';
import '../models/ordem_servico.dart';
import '../Repositories/ordem_servico_repository.dart';

/// VIEWMODEL do cadastro de equipamento (RF02) e do histórico (RF03).
/// Usa ChangeNotifier para avisar a View quando algo muda (ex: tipo selecionado
/// ou resultado do histórico encontrado).
class EquipamentoViewModel extends ChangeNotifier {
  final OrdemServicoRepository _repositorio;

  EquipamentoViewModel(this._repositorio);

  // Campos do formulário
  TipoEquipamento? tipo;
  String marca = '';
  String modelo = '';
  String numeroSerie = '';
  String acessorios = '';
  String condicaoFisica = '';
  String senhaAcesso = '';

  // Resultado da busca de histórico (RF03)
  List<OrdemServico> historicoAnterior = [];
  bool verificandoHistorico = false;

  /// True se este número de série já esteve na assistência
  bool get jaPassouPelaAssistencia => historicoAnterior.isNotEmpty;

  /// Chamado pela View quando o usuário escolhe o tipo no dropdown.
  /// Dropdown precisa de notifyListeners para redesenhar o valor escolhido.
  void selecionarTipo(TipoEquipamento novoTipo) {
    tipo = novoTipo;
    notifyListeners();
  }

  /// RF03: procura OS anteriores com o mesmo número de série
  Future<void> verificarHistorico() async {
    final serial = numeroSerie.trim();
    if (serial.isEmpty) return;

    verificandoHistorico = true;
    notifyListeners();
    try {
      historicoAnterior = await _repositorio.buscarPorNumeroSerie(serial);
    } finally {
      // finally garante que o "carregando" seja desligado mesmo com erro
      verificandoHistorico = false;
      notifyListeners();
    }
  }

  /// Gera o Model Equipamento somente se os campos obrigatórios estiverem preenchidos.
  /// Número de série é obrigatório por segurança (RF02).
  Equipamento? toModel() {
    final tipoSelecionado = tipo;
    if (tipoSelecionado == null ||
        marca.trim().isEmpty ||
        modelo.trim().isEmpty ||
        numeroSerie.trim().isEmpty) {
      return null;
    }
    return Equipamento(
      tipo: tipoSelecionado,
      marca: marca.trim(),
      modelo: modelo.trim(),
      numeroSerie: numeroSerie.trim(),
      acessorios: acessorios.trim(),
      condicaoFisica: condicaoFisica.trim(),
      senhaAcesso: senhaAcesso,
    );
  }
}