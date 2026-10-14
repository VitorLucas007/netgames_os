import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/visual_mappers.dart';
import '../models/desconto.dart';
import '../models/enums.dart';
import '../models/ordem_servico.dart';
import '../Repositories/ordem_servico_repository.dart';
import '../ViewModels/ordem_servico_viewmodel.dart';
import '../widgets/componentes.dart';
import 'acompanhamento_page.dart';

/// Tela de detalhe da OS: status em destaque, ações, linha do tempo,
/// orçamento, fotos e envio por WhatsApp.
class OrdemDetalhePage extends StatefulWidget {
  final OrdemServico ordem;
  final OrdemServicoRepository repositorio;

  const OrdemDetalhePage({super.key, required this.ordem, required this.repositorio});

  @override
  State<OrdemDetalhePage> createState() => _OrdemDetalhePageState();
}

class _OrdemDetalhePageState extends State<OrdemDetalhePage> {
  late final OrdemServicoViewModel _vm;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _vm = OrdemServicoViewModel(widget.repositorio, widget.ordem);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _tirarFoto(TipoFoto tipo) async {
    final foto = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (foto != null) await _vm.adicionarFoto(foto.path, tipo);
  }

  /// Diálogo para editar laudo, mão de obra e peças
  Future<void> _editarLaudo() async {
    final laudoCtrl = TextEditingController(text: _vm.ordem.laudoTecnico);
    final maoCtrl = TextEditingController(
      text: _vm.ordem.valorMaoDeObra > 0 ? _vm.ordem.valorMaoDeObra.toStringAsFixed(2) : '',
    );
    final pecas = List<Peca>.from(_vm.ordem.pecas);
    var tipoDesconto = _vm.ordem.desconto.tipo;
    final descontoCtrl = TextEditingController(
      text: _vm.ordem.desconto.existe
          ? _vm.ordem.desconto.quantidade.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );

    final salvou = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Laudo e orçamento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: laudoCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Laudo técnico'),
                ),
                AppSpacing.vMd,
                TextField(
                  controller: maoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Mão de obra (R\$)'),
                ),
                AppSpacing.vBase,
                Text('Peças', style: Theme.of(ctx).textTheme.titleSmall),
                AppSpacing.vSm,
                for (final p in pecas)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text('${p.quantidade}x ${p.nome}')),
                        Text(formatarMoeda(p.total)),
                      ],
                    ),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar peça'),
                  onPressed: () async {
                    final peca = await _novaPeca(ctx);
                    if (peca != null) setStateDialog(() => pecas.add(peca));
                  },
                ),
                AppSpacing.vBase,
                Text('Desconto', style: Theme.of(ctx).textTheme.titleSmall),
                AppSpacing.vSm,
                SegmentedButton<TipoDesconto>(
                  segments: const [
                    ButtonSegment(value: TipoDesconto.valor, label: Text('R\$')),
                    ButtonSegment(value: TipoDesconto.percentual, label: Text('%')),
                  ],
                  selected: {tipoDesconto},
                  onSelectionChanged: (s) => setStateDialog(() => tipoDesconto = s.first),
                ),
                AppSpacing.vSm,
                TextField(
                  controller: descontoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: tipoDesconto == TipoDesconto.percentual
                        ? 'Desconto (%)'
                        : 'Desconto (R\$)',
                    helperText: 'Deixe em branco para não dar desconto',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (salvou == true) {
      await _vm.salvarLaudo(
        laudo: laudoCtrl.text,
        pecas: pecas,
        maoDeObra: double.tryParse(maoCtrl.text.replaceAll(',', '.')) ?? 0,
        desconto: Desconto(
          tipo: tipoDesconto,
          // Valor negativo não faz sentido; percentual acima de 100 vira 100
          quantidade: (double.tryParse(descontoCtrl.text.replaceAll(',', '.')) ?? 0)
              .clamp(0, tipoDesconto == TipoDesconto.percentual ? 100 : double.infinity)
              .toDouble(),
        ),
      );
    }
  }

  /// Diálogo para cadastrar uma peça. Devolve a peça ou null.
  Future<Peca?> _novaPeca(BuildContext ctx) {
    final nomeCtrl = TextEditingController();
    final qtdCtrl = TextEditingController(text: '1');
    final valorCtrl = TextEditingController();

    return showDialog<Peca>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Nova peça'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome da peça'),
            ),
            AppSpacing.vMd,
            TextField(
              controller: qtdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade'),
            ),
            AppSpacing.vMd,
            TextField(
              controller: valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor unitário (R\$)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final nome = nomeCtrl.text.trim();
              Navigator.pop(
                c,
                nome.isEmpty
                    ? null
                    : Peca(
                        nome: nome,
                        quantidade: int.tryParse(qtdCtrl.text) ?? 1,
                        valorUnitario:
                            double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0,
                      ),
              );
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  /// Ações de status. Mostra só o que o fluxo permite no momento.
  Widget _acoesDeStatus(OrdemServico o) {
    if (o.status.isFinal) {
      return Text(
        'Esta OS foi finalizada.',
        style: context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
      );
    }

    // Aguardando orçamento: a ação principal é a decisão do cliente (RF07)
    if (o.status == StatusOrdem.aguardandoAprovacao) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _vm.salvando
                  ? null
                  : () => _vm.registrarDecisao(DecisaoOrcamento.aprovado),
              icon: const Icon(Icons.check),
              label: const Text('Aprovado'),
            ),
          ),
          AppSpacing.hMd,
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _vm.salvando
                  ? null
                  : () => _vm.registrarDecisao(DecisaoOrcamento.recusado),
              icon: const Icon(Icons.close),
              label: const Text('Recusado'),
            ),
          ),
        ],
      );
    }

    // Demais casos: botões só para os próximos status permitidos
    return Column(
      children: [
        for (final s in _vm.proximosStatus)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _vm.salvando ? null : () => _vm.avancarStatus(s),
                icon: const Icon(Icons.arrow_forward),
                label: Text(s.rotulo),
              ),
            ),
          ),
      ],
    );
  }

  /// Linha "rótulo ........ valor" do orçamento
  Widget _linhaValor(String rotulo, double valor, {bool destaque = false}) {
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

  /// Decisão do cliente com ícone e cor
  Widget _decisao(DecisaoOrcamento d) {
    final c = context.colors;
    final (texto, icone, cor) = switch (d) {
      DecisaoOrcamento.pendente => ('Pendente', Icons.hourglass_empty, c.outline),
      DecisaoOrcamento.aprovado => ('Aprovado', Icons.check_circle_outline, c.primary),
      DecisaoOrcamento.recusado => ('Recusado', Icons.cancel_outlined, c.error),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 18, color: cor),
        AppSpacing.hSm,
        Text(texto, style: TextStyle(color: cor, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vm.ordem.codigo),
        actions: [
          IconButton(
            tooltip: 'Ver como o cliente',
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AcompanhamentoPage(
                  codigoAcesso: _vm.ordem.codigoAcesso,
                  repositorio: widget.repositorio,
                ),
              ),
            ),
          ),
        ],
      ),

      // Envio dos PDFs pelo WhatsApp (RF10 e RF11)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ListenableBuilder(
            listenable: _vm,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_vm.reciboDisponivel)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'O recibo fica disponível quando a OS estiver pronta para retirada.',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _vm.gerandoDocumento
                            ? null
                            : () => _vm.enviarDocumentoWhatsApp(TipoDocumento.termoRecebimento),
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Enviar termo'),
                      ),
                    ),
                    AppSpacing.hMd,
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: (_vm.gerandoDocumento || !_vm.reciboDisponivel)
                            ? null
                            : () => _vm.enviarDocumentoWhatsApp(TipoDocumento.reciboGarantia),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Enviar recibo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final o = _vm.ordem;
          final c = context.colors;
          final estilo = estiloStatus(o.status, c);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_vm.salvando || _vm.gerandoDocumento) const LinearProgressIndicator(minHeight: 2),
              if (_vm.erro != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(_vm.erro!, style: TextStyle(color: c.error)),
                ),

              // ---- Status em destaque ----
              Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: estilo.fundo,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    Icon(estilo.icone, size: 40, color: estilo.cor),
                    AppSpacing.hMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status atual',
                            style: context.textTheme.labelMedium?.copyWith(color: c.onSurfaceVariant),
                          ),
                          Text(
                            o.status.rotulo,
                            style: context.textTheme.titleLarge?.copyWith(
                              color: estilo.cor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Aberta em ${formatarData(o.dataAbertura)}',
                            style: context.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vBase,

              // ---- Dados do aparelho (RF08) ----
              SecaoCard(
                icone: iconeTipo(o.equipamento.tipo),
                titulo: 'Aparelho',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinhaInfo(
                      icone: Icons.label_outline,
                      texto:
                          '${o.equipamento.tipo.rotulo} • ${o.equipamento.marca} ${o.equipamento.modelo}',
                    ),
                    LinhaInfo(icone: Icons.tag, texto: 'Série: ${o.equipamento.numeroSerie}'),
                    LinhaInfo(icone: Icons.report_problem_outlined, texto: 'Defeito: ${o.defeitoRelatado}'),
                    LinhaInfo(icone: Icons.person_outline, texto: 'Cliente: ${o.cliente.nome}'),
                  ],
                ),
              ),
              AppSpacing.vBase,

              // ---- Próxima etapa ----
              SecaoCard(
                icone: Icons.touch_app_outlined,
                titulo: 'Próxima etapa',
                child: _acoesDeStatus(o),
              ),
              AppSpacing.vBase,

              // ---- Linha do tempo (RF08) ----
              SecaoCard(
                icone: Icons.timeline,
                titulo: 'Linha do tempo',
                child: LinhaDoTempo(registros: o.historico),
              ),
              AppSpacing.vBase,

              // ---- Orçamento (RF06 e RF07) ----
              SecaoCard(
                icone: Icons.receipt_long_outlined,
                titulo: 'Orçamento',
                acao: IconButton(
                  onPressed: _vm.salvando ? null : _editarLaudo,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar laudo e orçamento',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _linhaValor('Mão de obra', o.valorMaoDeObra),
                    _linhaValor('Peças', o.valorPecas),
                    if (o.desconto.existe)
                      _linhaValor('Desconto (${o.desconto.rotulo})', -o.valorDesconto),
                    const Divider(),
                    _linhaValor('Total', o.valorTotal, destaque: true),
                    AppSpacing.vSm,
                    Row(
                      children: [
                        Text('Decisão do cliente:', style: context.textTheme.bodyMedium),
                        AppSpacing.hSm,
                        _decisao(o.decisaoOrcamento),
                      ],
                    ),
                    if (o.laudoTecnico.isNotEmpty) ...[
                      AppSpacing.vBase,
                      Text('Laudo técnico', style: context.textTheme.titleSmall),
                      AppSpacing.vSm,
                      Text(o.laudoTecnico, style: context.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              AppSpacing.vBase,

              // ---- Acompanhamento do cliente (RF08) ----
              SecaoCard(
                icone: Icons.link,
                titulo: 'Acompanhamento do cliente',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          o.linkAtivo ? Icons.check_circle_outline : Icons.lock_outline,
                          size: 18,
                          color: o.linkAtivo ? c.primary : c.error,
                        ),
                        AppSpacing.hSm,
                        Text(
                          o.linkAtivo ? 'Link ativo até a entrega' : 'Link encerrado (OS finalizada)',
                          style: context.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    AppSpacing.vSm,
                    Text(
                      'O cliente vê: status, linha do tempo, orçamento, laudo e fotos.',
                      style: context.textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
                    ),
                    if (o.linkAtivo) ...[
                      AppSpacing.vMd,
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: _vm.linkAcompanhamento));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Link copiado')),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copiar link'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.vBase,

              // ---- Fotos (RF05) ----
              SecaoCard(
                icone: Icons.photo_camera_outlined,
                titulo: 'Fotos',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (o.fotos.isEmpty)
                      Text(
                        'Nenhuma foto ainda.',
                        style: context.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final f in o.fotos)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: Stack(
                                children: [
                                  Image.file(File(f.caminho), width: 96, height: 96, fit: BoxFit.cover),
                                  Positioned(
                                    left: 6,
                                    bottom: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        f.tipo == TipoFoto.entrada ? 'Entrada' : 'Saída',
                                        style: const TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    AppSpacing.vMd,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _vm.salvando ? null : () => _tirarFoto(TipoFoto.entrada),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Foto de entrada'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _vm.salvando ? null : () => _tirarFoto(TipoFoto.saida),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Foto de saída'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.vLg,
            ],
          );
        },
      ),
    );
  }
}