import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/visual_mappers.dart';
import '../../models/enums.dart';
import '../../models/ordem_servico.dart';

/// Formata data e hora no padrão brasileiro: 12/10/2026 14:30
String formatarData(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Formata valor em reais: R$ 150,00
String formatarMoeda(double valor) => 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

/// Etiqueta colorida com ícone e texto do status.
class StatusChip extends StatelessWidget {
  final StatusOrdem status;
  final bool grande;

  const StatusChip({super.key, required this.status, this.grande = false});

  @override
  Widget build(BuildContext context) {
    final estilo = estiloStatus(status, context.colors);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: grande ? 12 : 8,
        vertical: grande ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: estilo.fundo,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(estilo.icone, size: grande ? 18 : 14, color: estilo.cor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status.rotulo,
              style: context.textTheme.labelMedium?.copyWith(
                color: estilo.cor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de seção com ícone, título e conteúdo. Organiza as telas em blocos.
class SecaoCard extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final Widget child;

  /// Ação opcional no canto direito do título (ex: botão de editar)
  final Widget? acao;

  const SecaoCard({
    super.key,
    required this.icone,
    required this.titulo,
    required this.child,
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ícone dentro de um quadrado suave
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: c.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icone, size: 18, color: c.onPrimaryContainer),
                ),
                AppSpacing.hMd,
                Expanded(
                  child: Text(titulo, style: context.textTheme.titleMedium),
                ),
                if (acao != null) acao!,
              ],
            ),
            AppSpacing.vMd,
            child,
          ],
        ),
      ),
    );
  }
}

/// Linha com ícone + texto, usada para mostrar dados do aparelho e do cliente.
class LinhaInfo extends StatelessWidget {
  final IconData icone;
  final String texto;

  const LinhaInfo({super.key, required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: context.colors.onSurfaceVariant),
          AppSpacing.hMd,
          Expanded(child: Text(texto, style: context.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

/// Estado vazio: ícone grande e mensagem quando não há nada para mostrar.
class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String mensagem;

  const EstadoVazio({super.key, required this.icone, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 56, color: context.colors.outline),
          AppSpacing.vBase,
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha do tempo vertical: bolinhas ligadas por uma linha. A última etapa fica destacada.
class LinhaDoTempo extends StatelessWidget {
  final List<RegistroStatus> registros;

  const LinhaDoTempo({super.key, required this.registros});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        for (var i = 0; i < registros.length; i++)
          _item(context, registros[i], ultimo: i == registros.length - 1, c: c),
      ],
    );
  }

  Widget _item(BuildContext context, RegistroStatus r,
      {required bool ultimo, required ColorScheme c}) {
    final estilo = estiloStatus(r.status, c);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coluna da esquerda: bolinha + linha que liga às próximas
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ultimo ? estilo.cor : c.surface,
                    border: Border.all(color: estilo.cor, width: 2),
                  ),
                ),
                if (!ultimo)
                  Expanded(child: Container(width: 2, color: c.outlineVariant)),
              ],
            ),
          ),
          AppSpacing.hMd,
          // Texto do registro
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ultimo ? 0 : AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.status.rotulo, style: context.textTheme.titleSmall),
                  Text(
                    formatarData(r.data),
                    style: context.textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
                  ),
                  if (r.observacao != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(r.observacao!, style: context.textTheme.bodyMedium),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}