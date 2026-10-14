import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/visual_mappers.dart';
import '../models/enums.dart';
import '../models/ordem_servico.dart';
import '../Repositories/ordem_servico_repository.dart';
import '../ViewModels/lista_ordens_viewmodel.dart';
import 'nova_ordem_page.dart';
import 'ordem_detalhe_page.dart';
import '../widgets/componentes.dart';

/// Tela inicial: resumo, filtros e lista de OS.
class ListaOrdensPage extends StatefulWidget {
  final OrdemServicoRepository repositorio;

  const ListaOrdensPage({super.key, required this.repositorio});

  @override
  State<ListaOrdensPage> createState() => _ListaOrdensPageState();
}

class _ListaOrdensPageState extends State<ListaOrdensPage> {
  late final ListaOrdensViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ListaOrdensViewModel(widget.repositorio)..carregar();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _abrirNovaOrdem() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NovaOrdemPage(repositorio: widget.repositorio)),
    );
    _vm.carregar();
  }

  Future<void> _abrirDetalhe(OrdemServico ordem) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrdemDetalhePage(ordem: ordem, repositorio: widget.repositorio),
      ),
    );
    _vm.carregar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Ordens de Serviço')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovaOrdem,
        icon: const Icon(Icons.add),
        label: const Text('Nova OS'),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          // Contagens para o resumo do topo
          final todas = _vm.ordensFiltradas;
          final emAndamento = todas.where((o) => !o.status.isFinal).length;
          final aguardandoCliente =
              todas.where((o) => o.status == StatusOrdem.aguardandoAprovacao).length;

          return Column(
            children: [
              // ---- Resumo ----
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _Indicador(
                        valor: '$emAndamento',
                        rotulo: 'Em andamento',
                        icone: Icons.build_circle_outlined,
                        cor: c.primary,
                      ),
                    ),
                    AppSpacing.hMd,
                    Expanded(
                      child: _Indicador(
                        valor: '$aguardandoCliente',
                        rotulo: 'Aguardando cliente',
                        icone: Icons.request_quote_outlined,
                        cor: c.tertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // ---- Filtros por status ----
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: const Text('Todas'),
                        selected: _vm.filtroStatus == null,
                        onSelected: (_) => _vm.filtrarPorStatus(null),
                      ),
                    ),
                    for (final status in StatusOrdem.values)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(status.rotulo),
                          selected: _vm.filtroStatus == status,
                          onSelected: (_) => _vm.filtrarPorStatus(status),
                        ),
                      ),
                  ],
                ),
              ),

              // ---- Lista (puxar para atualizar) ----
              Expanded(
                child: _vm.carregando
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _vm.carregar,
                        child: ListView(
                          // Permite puxar para atualizar mesmo com a lista vazia
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          children: _vm.ordensFiltradas.isEmpty
                              ? [
                                  const SizedBox(
                                    height: 300,
                                    child: EstadoVazio(
                                      icone: Icons.inbox_outlined,
                                      mensagem: 'Nenhuma OS encontrada.\nToque em "Nova OS" para começar.',
                                    ),
                                  ),
                                ]
                              : [
                                  for (final o in _vm.ordensFiltradas)
                                    _CartaoOrdem(ordem: o, onTap: () => _abrirDetalhe(o)),
                                ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Indicador de número (ex: "3 em andamento") usado no resumo do topo.
class _Indicador extends StatelessWidget {
  final String valor;
  final String rotulo;
  final IconData icone;
  final Color cor;

  const _Indicador({
    required this.valor,
    required this.rotulo,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor),
          AppSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor,
                    style: context.textTheme.titleLarge?.copyWith(color: cor, fontWeight: FontWeight.w700)),
                Text(rotulo, style: context.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartão de uma OS na lista: ícone do aparelho, código, nome, status.
class _CartaoOrdem extends StatelessWidget {
  final OrdemServico ordem;
  final VoidCallback onTap;

  const _CartaoOrdem({required this.ordem, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias, // mantém o efeito de toque dentro das bordas
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Ícone do tipo de aparelho
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(iconeTipo(ordem.equipamento.tipo), color: c.onPrimaryContainer),
              ),
              AppSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ordem.codigo, style: context.textTheme.titleMedium),
                    Text(
                      '${ordem.equipamento.marca} ${ordem.equipamento.modelo} • ${ordem.cliente.nome}',
                      style: context.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vSm,
                    StatusChip(status: ordem.status),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}