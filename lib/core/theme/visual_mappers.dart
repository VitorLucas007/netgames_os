import 'package:flutter/material.dart';

import '../../../models/enums.dart';

/// Aparência de um status: cor, ícone e um fundo suave da mesma cor.
class EstiloStatus {
  final Color cor;
  final IconData icone;

  const EstiloStatus(this.cor, this.icone);

  /// Fundo claro para usar atrás do texto/ícone
  Color get fundo => cor.withValues(alpha: 0.14);
}

/// Decide a cor e o ícone de cada status.
/// Regra de acessibilidade: a cor NUNCA aparece sozinha. Sempre vem com ícone e texto.
EstiloStatus estiloStatus(StatusOrdem status, ColorScheme c) {
  // Verde fixo para "concluído". Tom mais claro no modo escuro para manter contraste.
  final sucesso = c.brightness == Brightness.dark
      ? const Color(0xFF81C784)
      : const Color(0xFF2E7D32);

  return switch (status) {
    StatusOrdem.recebido => EstiloStatus(c.secondary, Icons.inventory_2_outlined),
    StatusOrdem.emAnalise => EstiloStatus(c.primary, Icons.search),
    StatusOrdem.aguardandoAprovacao => EstiloStatus(c.tertiary, Icons.request_quote_outlined),
    StatusOrdem.emManutencao => EstiloStatus(c.primary, Icons.build_outlined),
    StatusOrdem.aguardandoPeca => EstiloStatus(c.tertiary, Icons.hourglass_bottom),
    StatusOrdem.prontoRetirada => EstiloStatus(sucesso, Icons.task_alt),
    StatusOrdem.entregue => EstiloStatus(sucesso, Icons.handshake_outlined),
    StatusOrdem.devolvidoSemConserto => EstiloStatus(c.error, Icons.cancel_outlined),
  };
}

/// Ícone que representa cada tipo de aparelho
IconData iconeTipo(TipoEquipamento tipo) => switch (tipo) {
      TipoEquipamento.notebook => Icons.laptop,
      TipoEquipamento.desktop => Icons.desktop_windows_outlined,
      TipoEquipamento.console => Icons.sports_esports_outlined,
      TipoEquipamento.controle => Icons.gamepad_outlined,
      TipoEquipamento.celular => Icons.smartphone_outlined,
      TipoEquipamento.tablet => Icons.tablet,
      TipoEquipamento.outro => Icons.devices_other,
    };