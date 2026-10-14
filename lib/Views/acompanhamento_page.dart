import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/visual_mappers.dart';
import '../models/enums.dart';
import '../models/ordem_servico.dart';
import '../models/visao_cliente.dart';
import '../Repositories/ordem_servico_repository.dart';
import '../widgets/componentes.dart';

/// Tela que o CLIENTE vê ao abrir o link de acompanhamento.
/// Só recebe a VisaoCliente (sem senha, CPF, contato ou notas internas).
/// Não tem nenhum botão de ação: o cliente apenas acompanha.
class AcompanhamentoPage extends StatefulWidget {
  final String codigoAcesso;
  final OrdemServicoRepository repositorio;

  const AcompanhamentoPage({
    super.key,
    required this.codigoAcesso,
    required this.repositorio,
  });

  @override
  State<AcompanhamentoPage> createState() => _AcompanhamentoPageState();
}

class _AcompanhamentoPageState extends State<AcompanhamentoPage> {
  late Future<VisaoCliente?> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  /// Busca a visão pelo código. Devolve null se o link não existe ou expirou.
  Future<VisaoCliente?> _carregar() =>
      widget.repositorio.buscarAcompanhamento(widget.codigoAcesso);

  Future<void> _atualizar() async {
    setState(() => _futuro = _carregar());
    await _futuro;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acompanhamento do serviço')),
      body: FutureBuilder<VisaoCliente?>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const EstadoVazio(
              icone: Icons.error_outline,
              mensagem: 'Não foi possível carregar o acompanhamento.\nTente novamente.',
            );
          }
          final visao = snapshot.data;
          if (visao == null) {
            return const EstadoVazio(
              icone: Icons.link_off,
              mensagem: 'Link inválido ou expirado.\nEntre em contato com a assistência.',
            );
          }
          return RefreshIndicator(
            onRefresh: _atualizar,
            child: _conteudo(context, visao),
          );
        },
      ),
    );
  }

  Widget _conteudo(BuildContext context, VisaoCliente v) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        _cabecalho(context, v),
        AppSpacing.vBase,

        // Linha do tempo (RF08)
        SecaoCard(
          icone: Icons.timeline,
          titulo: 'Linha do tempo',
          child: LinhaDoTempo(registros: v.historico),
        ),
        AppSpacing.vBase,

        // Dados básicos do aparelho (sem senha)
        SecaoCard(
          icone: iconeTipo(v.tipoEquipamento),
          titulo: 'Aparelho',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinhaInfo(
                icone: Icons.label_outline,
                texto: '${v.tipoEquipamento.rotulo} • ${v.marcaModelo}',
              ),
              LinhaInfo(icone: Icons.tag, texto: 'Série: ${v.numeroSerie}'),
              LinhaInfo(
                icone: Icons.report_problem_outlined,
                texto: 'Defeito relatado: ${v.defeitoRelatado}',
              ),
            ],
          ),
        ),
        AppSpacing.vBase,

        // Orçamento (RF06 e RF07)
        SecaoCard(
          icone: Icons.receipt_long_outlined,
          titulo: 'Orçamento',
          child: _orcamento(context, v),
        ),

        // Laudo e fotos aparecem só quando já existem
        if (v.laudoTecnico.isNotEmpty) ...[
          AppSpacing.vBase,
          SecaoCard(
            icone: Icons.description_outlined,
            titulo: 'Laudo técnico',
            child: Text(v.laudoTecnico, style: context.textTheme.bodyMedium),
          ),
        ],
        if (v.fotos.isNotEmpty) ...[
          AppSpacing.vBase,
          SecaoCard(
            icone: Icons.photo_camera_outlined,
            titulo: 'Fotos',
            child: _fotos(context, v.fotos),
          ),
        ],
        AppSpacing.vLg,
      ],
    );
  }

  /// Topo: saudação, código da OS e status em destaque
  Widget _cabecalho(BuildContext context, VisaoCliente v) {
    final estilo = estiloStatus(v.status, context.colors);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: estilo.fundo,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Olá, ${v.nomeCliente}', style: context.textTheme.titleMedium),
          AppSpacing.vSm,
          Text(
            'OS ${v.codigo}',
            style: context.textTheme.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          AppSpacing.vMd,
          StatusChip(status: v.status, grande: true),
          AppSpacing.vSm,
          Text(
            'Aberta em ${formatarData(v.dataAbertura)}',
            style: context.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _orcamento(BuildContext context, VisaoCliente v) {
    final t = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (v.pecas.isNotEmpty) ...[
          for (final p in v.pecas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text('${p.quantidade}x ${p.nome}', style: t.bodyMedium)),
                  Text(formatarMoeda(p.total), style: t.bodyMedium),
                ],
              ),
            ),
          const Divider(),
        ],
        _linhaValor(context, 'Mão de obra', v.valorMaoDeObra),
        _linhaValor(context, 'Peças', v.valorPecas),
        if (v.desconto.existe)
          _linhaValor(context, 'Desconto (${v.desconto.rotulo})', -v.valorDesconto),
        const Divider(),
        _linhaValor(context, 'Total', v.valorTotal, destaque: true),
        AppSpacing.vSm,
        Text(
          'Decisão: ${_rotuloDecisao(v.decisao)}',
          style: t.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _linhaValor(BuildContext context, String rotulo, double valor,
      {bool destaque = false}) {
    final estilo = destaque
        ? context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : context.textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rotulo, style: estilo),
          Text(formatarMoeda(valor), style: estilo),
        ],
      ),
    );
  }

  /// Fotos de entrada e saída. Como o caminho é local, a foto só aparece no mesmo aparelho.
  /// Com o Firebase Storage, cada foto passa a ter um endereço temporário.
  Widget _fotos(BuildContext context, List<FotoOS> fotos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final f in fotos)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.file(
                      File(f.caminho),
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, error, stack) => Container(
                        width: 110,
                        height: 110,
                        color: ctx.colors.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(Icons.image_not_supported_outlined, color: ctx.colors.outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    f.tipo == TipoFoto.entrada ? 'Entrada' : 'Saída',
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
        AppSpacing.vSm,
        Text(
          'Nesta versão de testes, as fotos aparecem apenas no aparelho onde foram tiradas.',
          style: context.textTheme.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ],
    );
  }

  String _rotuloDecisao(DecisaoOrcamento d) => switch (d) {
        DecisaoOrcamento.pendente => 'Pendente',
        DecisaoOrcamento.aprovado => 'Aprovado',
        DecisaoOrcamento.recusado => 'Recusado',
      };
}