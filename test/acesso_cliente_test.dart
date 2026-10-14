import 'package:flutter_test/flutter_test.dart';

import 'package:netgames_os_app/core/rota_acompanhamento.dart';
import 'package:netgames_os_app/models/cliente.dart';
import 'package:netgames_os_app/models/enums.dart';
import 'package:netgames_os_app/models/equipamentos.dart';
import 'package:netgames_os_app/models/ordem_servico.dart';
import 'package:netgames_os_app/models/visao_cliente.dart';
import 'package:netgames_os_app/Repositories/ordem_servico_repository.dart';
import 'package:netgames_os_app/utils/codigo_acesso.dart';

/// Cria uma OS de exemplo. Os testes mudam só o que interessa.
OrdemServico criarOs({
  StatusOrdem status = StatusOrdem.recebido,
  String codigoAcesso = 'ABC123',
  int diasDesdeUltimoStatus = 0,
}) {
  final ultimaMudanca = DateTime.now().subtract(Duration(days: diasDesdeUltimoStatus));
  return OrdemServico(
    codigo: 'OS-2026-00001',
    codigoAcompanhamento: codigoAcesso,
    codigoAcesso: codigoAcesso,
    cliente: const Cliente(
      nome: 'Maria Teste',
      whatsapp: '86999998888',
      cpf: '12345678909',
      email: 'maria@teste.com',
    ),
    equipamento: const Equipamento(
      tipo: TipoEquipamento.notebook,
      marca: 'Dell',
      modelo: 'Inspiron',
      numeroSerie: 'SN123',
      acessorios: 'Fonte',
      condicaoFisica: 'Riscos na tampa',
      senhaAcesso: '1234',
    ),
    defeitoRelatado: 'Não liga',
    status: status,
    dataAbertura: ultimaMudanca,
    historico: [RegistroStatus(status: status, data: ultimaMudanca)],
    laudoTecnico: '',
    pecas: const [],
    valorMaoDeObra: 0,
    decisaoOrcamento: DecisaoOrcamento.pendente,
    fotos: const [],
  );
}

void main() {
  group('Código de acesso', () {
    test('tem 20 caracteres, todos do alfabeto permitido', () {
      final codigo = gerarCodigoAcesso();
      expect(codigo.length, 20);
      // Sem 0, 1, I e O, para evitar confusão ao digitar
      expect(RegExp(r'^[A-HJ-NP-Z2-9]+$').hasMatch(codigo), isTrue);
    });

    test('dois códigos gerados são diferentes', () {
      expect(gerarCodigoAcesso(), isNot(equals(gerarCodigoAcesso())));
    });
  });

  group('Expiração do link', () {
    test('link fica ativo enquanto a OS não foi encerrada', () {
      expect(criarOs(status: StatusOrdem.emManutencao).linkAtivo, isTrue);
      expect(criarOs(status: StatusOrdem.prontoRetirada).linkAtivo, isTrue);
    });

    test('link expira 30 dias depois de Entregue ou Devolvido sem Conserto', () {
      expect(criarOs(status: StatusOrdem.entregue, diasDesdeUltimoStatus: 31).linkAtivo, isFalse);
      expect(
        criarOs(status: StatusOrdem.devolvidoSemConserto, diasDesdeUltimoStatus: 31).linkAtivo,
        isFalse,
      );
    });

    test('link continua ativo dentro dos 30 dias após o encerramento', () {
      expect(criarOs(status: StatusOrdem.entregue, diasDesdeUltimoStatus: 5).linkAtivo, isTrue);
    });
  });

  group('Acesso do cliente pelo repositório', () {
    test('cliente recebe a visão quando o código é válido e o link está ativo', () async {
      final repo = OrdemServicoRepositoryMemoria();
      await repo.salvar(criarOs(codigoAcesso: 'XYZ789'));

      final visao = await repo.buscarAcompanhamento('XYZ789');
      expect(visao, isNotNull);
      expect(visao!.nomeCliente, 'Maria Teste');
    });

    test('código inexistente não devolve nada', () async {
      final repo = OrdemServicoRepositoryMemoria();
      await repo.salvar(criarOs(codigoAcesso: 'XYZ789'));

      expect(await repo.buscarAcompanhamento('CODIGO-ERRADO'), isNull);
    });

    test('link expirado não devolve nada, mesmo com código correto', () async {
      final repo = OrdemServicoRepositoryMemoria();
      await repo.salvar(criarOs(status: StatusOrdem.entregue, codigoAcesso: 'XYZ789', diasDesdeUltimoStatus: 31));

      expect(await repo.buscarAcompanhamento('XYZ789'), isNull);
    });

    test('a visão do cliente não expõe senha, CPF nem contato', () async {
      final repo = OrdemServicoRepositoryMemoria();
      await repo.salvar(criarOs(codigoAcesso: 'XYZ789'));
      final visao = await repo.buscarAcompanhamento('XYZ789') as VisaoCliente;

      // A classe VisaoCliente não tem esses campos. Conferimos o texto gerado também.
      final texto = visao.toString() + visao.marcaModelo + visao.numeroSerie;
      expect(texto.contains('1234'), isFalse);
      expect(texto.contains('12345678909'), isFalse);
      expect(texto.contains('86999998888'), isFalse);
    });
  });

  group('Leitura do link', () {
    test('extrai o código de /acompanhar/CODIGO', () {
      expect(codigoAcessoDaUrl(Uri.parse('https://x.web.app/acompanhar/ABC123')), 'ABC123');
    });

    test('extrai o código quando o link usa hash (Flutter Web)', () {
      expect(codigoAcessoDaUrl(Uri.parse('https://x.web.app/#/acompanhar/ABC123')), 'ABC123');
    });

    test('URL comum não é tratada como link de acompanhamento', () {
      expect(codigoAcessoDaUrl(Uri.parse('https://x.web.app/')), isNull);
    });
  });
}