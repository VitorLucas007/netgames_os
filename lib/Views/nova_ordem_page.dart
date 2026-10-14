import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/visual_mappers.dart';
import '../models/enums.dart';
import '../models/ordem_servico.dart';
import '../Repositories/ordem_servico_repository.dart';
import '../ViewModels/nova_ordem_viewmodel.dart';
import '../widgets/componentes.dart';

/// Tela "Nova OS": formulário dividido em seções (cliente, equipamento, defeito).
class NovaOrdemPage extends StatefulWidget {
  final OrdemServicoRepository repositorio;

  const NovaOrdemPage({super.key, required this.repositorio});

  @override
  State<NovaOrdemPage> createState() => _NovaOrdemPageState();
}

class _NovaOrdemPageState extends State<NovaOrdemPage> {
  late final NovaOrdemViewModel _vm;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _vm = NovaOrdemViewModel(widget.repositorio);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final ordem = await _vm.abrirOrdem();
    if (ordem != null && mounted) Navigator.pop(context);
  }

  /// Campo de texto padrão. O estilo vem do tema, então aqui só definimos o comportamento.
  Widget _campo({
    required String rotulo,
    required ValueChanged<String> onChanged,
    String? Function(String?)? validator,
    TextInputType? teclado,
    int maxLines = 1,
    bool senha = false,
    String? ajuda,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        decoration: InputDecoration(labelText: rotulo, helperText: ajuda),
        onChanged: onChanged,
        validator: validator,
        keyboardType: teclado,
        maxLines: senha ? 1 : maxLines,
        obscureText: senha,
      ),
    );
  }

  String? _obrigatorio(String? valor) =>
      (valor == null || valor.trim().isEmpty) ? 'Campo obrigatório' : null;

  /// Aviso de aparelho já cadastrado (RF03).
  /// Usa cor de destaque E ícone, sem depender só da cor.
  Widget _avisoHistorico(List<OrdemServico> anteriores) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history, color: c.onTertiaryContainer),
          AppSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Este aparelho já esteve na assistência',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: c.onTertiaryContainer,
                  ),
                ),
                AppSpacing.vSm,
                for (final o in anteriores)
                  Text(
                    '${o.codigo} • ${o.status.rotulo}\n${o.defeitoRelatado}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: c.onTertiaryContainer,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Ordem de Serviço')),

      // Botão fixo no rodapé: fica sempre visível, mesmo com o teclado aberto
      bottomNavigationBar: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_vm.erro != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      _vm.erro!,
                      style: TextStyle(color: context.colors.error),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _vm.salvando ? null : _salvar,
                    icon: const Icon(Icons.check),
                    label: Text(_vm.salvando ? 'Salvando...' : 'Abrir OS'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: ListenableBuilder(
        listenable: Listenable.merge([_vm, _vm.equipamento]),
        builder: (context, _) {
          final cliente = _vm.cliente;
          final equip = _vm.equipamento;

          return Form(
            key: _formKey,
            // SingleChildScrollView (e não ListView) mantém todos os campos vivos:
            // o ListView descarta os campos fora da tela e o texto digitado some.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Seção 1: Cliente (RF01) ----
                  SecaoCard(
                    icone: Icons.person_outline,
                    titulo: 'Cliente',
                    child: Column(
                      children: [
                        _campo(
                          rotulo: 'Nome completo',
                          onChanged: (v) => cliente.nome = v,
                          validator: cliente.validarNome,
                        ),
                        _campo(
                          rotulo: 'WhatsApp (com DDD)',
                          teclado: TextInputType.phone,
                          onChanged: (v) => cliente.whatsapp = v,
                          validator: cliente.validarWhatsapp,
                        ),
                        _campo(
                          rotulo: 'CPF',
                          teclado: TextInputType.number,
                          onChanged: (v) => cliente.cpf = v,
                          validator: cliente.validarCpf,
                        ),
                        _campo(
                          rotulo: 'E-mail',
                          teclado: TextInputType.emailAddress,
                          onChanged: (v) => cliente.email = v,
                          validator: cliente.validarEmail,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vBase,

                  // ---- Seção 2: Equipamento (RF02 e RF03) ----
                  SecaoCard(
                    icone: Icons.devices_outlined,
                    titulo: 'Equipamento',
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: DropdownButtonFormField<TipoEquipamento>(
                            value: equip.tipo,
                            decoration: const InputDecoration(
                              labelText: 'Tipo',
                            ),
                            items: [
                              for (final t in TipoEquipamento.values)
                                DropdownMenuItem(
                                  value: t,
                                  child: Row(
                                    children: [
                                      Icon(iconeTipo(t), size: 18),
                                      AppSpacing.hSm,
                                      Text(t.rotulo),
                                    ],
                                  ),
                                ),
                            ],
                            onChanged: (t) {
                              if (t != null) equip.selecionarTipo(t);
                            },
                            validator: (t) =>
                                t == null ? 'Selecione o tipo' : null,
                          ),
                        ),
                        _campo(
                          rotulo: 'Marca',
                          onChanged: (v) => equip.marca = v,
                          validator: _obrigatorio,
                        ),
                        _campo(
                          rotulo: 'Modelo',
                          onChanged: (v) => equip.modelo = v,
                          validator: _obrigatorio,
                        ),
                        _campo(
                          rotulo: 'Número de série',
                          onChanged: (v) => equip.numeroSerie = v,
                          validator: _obrigatorio,
                          ajuda:
                              'Obrigatório. Usado para verificar o histórico.',
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: equip.verificandoHistorico
                                ? null
                                : equip.verificarHistorico,
                            icon: const Icon(Icons.history),
                            label: Text(
                              equip.verificandoHistorico
                                  ? 'Verificando...'
                                  : 'Verificar histórico do aparelho',
                            ),
                          ),
                        ),
                        AppSpacing.vBase,
                        if (equip.jaPassouPelaAssistencia)
                          _avisoHistorico(equip.historicoAnterior),
                        _campo(
                          rotulo:
                              'Acessórios deixados (cabos, fontes, jogos...)',
                          maxLines: 2,
                          onChanged: (v) => equip.acessorios = v,
                        ),
                        _campo(
                          rotulo: 'Condição física / avarias pré-existentes',
                          maxLines: 3,
                          onChanged: (v) => equip.condicaoFisica = v,
                        ),
                        _campo(
                          rotulo: 'Senha de acesso (PIN / Windows / Mac)',
                          senha: true,
                          ajuda: 'Será guardada de forma protegida.',
                          onChanged: (v) => equip.senhaAcesso = v,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vBase,

                  // ---- Seção 3: Defeito relatado (RF04) ----
                  SecaoCard(
                    icone: Icons.report_problem_outlined,
                    titulo: 'Defeito relatado',
                    child: _campo(
                      rotulo: 'Reclamação do cliente',
                      maxLines: 3,
                      validator: _obrigatorio,
                      onChanged: (v) => _vm.defeitoRelatado = v,
                    ),
                  ),
                  AppSpacing.vLg,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
