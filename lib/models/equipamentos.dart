import 'enums.dart';

/// MODEL do Equipamento (RF02 - Cadastro Detalhado).
class Equipamento {
  final TipoEquipamento tipo;
  final String marca;
  final String modelo;

  /// Número de série: identifica o aparelho. É a chave do histórico (RF03).
  final String numeroSerie;

  /// Acessórios deixados junto (cabos, fontes, jogos...)
  final String acessorios;

  /// Condição física e avarias que já existiam ao receber o aparelho
  final String condicaoFisica;

  /// Senha do sistema (PIN, Windows, Mac).
  /// ATENÇÃO: é dado sensível. Antes de ir para produção, deve ser criptografado.
  final String senhaAcesso;

  const Equipamento({
    required this.tipo,
    required this.marca,
    required this.modelo,
    required this.numeroSerie,
    required this.acessorios,
    required this.condicaoFisica,
    required this.senhaAcesso,
  });

  Map<String, dynamic> toMap() => {
        // Enum é salvo pelo nome (ex: "notebook") e lido de volta com byName
        'tipo': tipo.name,
        'marca': marca,
        'modelo': modelo,
        'numeroSerie': numeroSerie,
        'acessorios': acessorios,
        'condicaoFisica': condicaoFisica,
        'senhaAcesso': senhaAcesso,
      };

  factory Equipamento.fromMap(Map<String, dynamic> map) => Equipamento(
        tipo: TipoEquipamento.values.byName(map['tipo'] as String),
        marca: map['marca'] as String,
        modelo: map['modelo'] as String,
        numeroSerie: map['numeroSerie'] as String,
        acessorios: map['acessorios'] as String,
        condicaoFisica: map['condicaoFisica'] as String,
        senhaAcesso: map['senhaAcesso'] as String,
      );
}