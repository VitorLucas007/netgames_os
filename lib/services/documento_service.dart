import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/enums.dart';
import '../models/ordem_servico.dart';
import '../utils/formatadores.dart';

/// SERVIÇO de documentos (RF10 e RF11).
/// Não é ViewModel nem View: só gera o PDF e entrega o arquivo ao compartilhamento.
/// Fica separado para poder ser trocado ou testado sem mexer nas telas.
class DocumentoService {
  /// Nome que aparece no cabeçalho dos documentos. Troque pelo nome real.
  static const nomeEmpresa = 'SUA ASSISTÊNCIA TÉCNICA';

  /// Prazo de garantia em dias. Confirme o prazo com o seu negócio.
  static const diasGarantia = 90;

  /// Gera o PDF da OS e salva em uma pasta temporária do app.
  Future<File> gerarPdf(OrdemServico ordem, TipoDocumento tipo) async {
    final documento = pw.Document(
      title: '${tipo.titulo} ${ordem.codigo}',
      author: nomeEmpresa,
    );

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        // Cabeçalho repetido em todas as páginas
        header: (context) => _cabecalho(tipo),
        // Rodapé com número da página
        footer: (context) => pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        build: (context) => _corpo(ordem, tipo),
      ),
    );

    final bytes = await documento.save();
    final pasta = await getTemporaryDirectory();
    final arquivo = File('${pasta.path}/${ordem.codigo}_${tipo.name}.pdf');
    return arquivo.writeAsBytes(bytes, flush: true);
  }

  /// Abre o compartilhamento do Android com o PDF anexado.
  /// O técnico escolhe o WhatsApp e o contato. Nada é enviado sem essa escolha.
  Future<void> compartilhar(File arquivo, {required String legenda}) async {
    await Share.shareXFiles(
      [XFile(arquivo.path, mimeType: 'application/pdf', name: arquivo.uri.pathSegments.last)],
      text: legenda,
    );
  }

  // ---------- Layout do PDF ----------

  pw.Widget _cabecalho(TipoDocumento tipo) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(nomeEmpresa, style: _estilo(12, negrito: true)),
              pw.Text(tipo.titulo, style: _estilo(9, cor: PdfColors.grey700)),
            ],
          ),
          pw.Divider(color: PdfColors.grey400),
        ],
      );

  List<pw.Widget> _corpo(OrdemServico o, TipoDocumento tipo) {
    final c = o.cliente;
    final e = o.equipamento;

    return [
      pw.SizedBox(height: 8),
      pw.Text(tipo.titulo, style: _estilo(16, negrito: true)),
      pw.SizedBox(height: 8),
      _linha('Código da OS', o.codigo),
      _linha('Data de abertura', formatarData(o.dataAbertura)),
      _linha('Status atual', o.status.rotulo),

      _secao('Cliente'),
      _linha('Nome', c.nome),
      _linha('WhatsApp', c.whatsapp),
      _linha('CPF', mascararCpf(c.cpf)),
      _linha('E-mail', c.email),

      // A senha de acesso NÃO entra no documento, por segurança
      _secao('Aparelho'),
      _linha('Tipo', e.tipo.rotulo),
      _linha('Marca / modelo', '${e.marca} ${e.modelo}'),
      _linha('Número de série', e.numeroSerie),
      _linha('Acessórios', e.acessorios.isEmpty ? 'Nenhum' : e.acessorios),
      _linha('Condição física',
          e.condicaoFisica.isEmpty ? 'Sem avarias informadas' : e.condicaoFisica),
      _linha('Defeito relatado', o.defeitoRelatado),

      // Conteúdo específico de cada documento
      ...(tipo == TipoDocumento.termoRecebimento
          ? _blocoEntrada()
          : _blocoSaida(o)),

      pw.SizedBox(height: 40),
      _assinaturas(),
    ];
  }

  /// Texto do Termo de Recebimento (entrada)
  List<pw.Widget> _blocoEntrada() => [
        _secao('Termo de recebimento'),
        pw.Text(
          'Declaro que o equipamento descrito acima foi recebido para análise e conserto, '
          'nas condições informadas nesta data. A assistência não se responsabiliza por dados '
          'armazenados no aparelho, recomendando-se ao cliente manter cópia de segurança. '
          'A senha de acesso não consta deste documento por motivo de segurança.',
          style: _estilo(10),
        ),
      ];

  /// Conteúdo do Recibo e Termo de Garantia (saída)
  List<pw.Widget> _blocoSaida(OrdemServico o) => [
        _secao('Serviço executado'),
        pw.Text(
          o.laudoTecnico.isEmpty ? 'Não informado.' : o.laudoTecnico,
          style: _estilo(10),
        ),

        _secao('Valores'),
        pw.Table.fromTextArray(
          headers: ['Item', 'Qtd', 'Valor unit.', 'Total'],
          data: [
            for (final p in o.pecas)
              [p.nome, '${p.quantidade}', formatarMoeda(p.valorUnitario), formatarMoeda(p.total)],
            ['Mão de obra', '1', formatarMoeda(o.valorMaoDeObra), formatarMoeda(o.valorMaoDeObra)],
          ],
          headerStyle: _estilo(9, negrito: true),
          cellStyle: _estilo(9),
          headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: pw.EdgeInsets.all(5),
        ),
        pw.SizedBox(height: 6),
        if (o.desconto.existe)
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Desconto (${o.desconto.rotulo}): -${formatarMoeda(o.valorDesconto)}',
              style: _estilo(10),
            ),
          ),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Total: ${formatarMoeda(o.valorTotal)}', style: _estilo(11, negrito: true)),
        ),
        _linha('Decisão do cliente', _rotuloDecisao(o.decisaoOrcamento)),

        _secao('Garantia'),
        pw.Text(
          'Garantia de $diasGarantia dias, contados da data de entrega, sobre o serviço executado '
          'e as peças substituídas. A garantia cobre somente o defeito reparado e não cobre danos '
          'causados por mau uso, quedas, contato com líquidos ou intervenção de terceiros.',
          style: _estilo(10),
        ),
      ];

  pw.Widget _assinaturas() => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _campoAssinatura('Assinatura do cliente'),
          _campoAssinatura('Técnico responsável'),
        ],
      );

  pw.Widget _campoAssinatura(String rotulo) => pw.Column(
        children: [
          pw.Container(width: 200, height: 1, color: PdfColors.black),
          pw.SizedBox(height: 4),
          pw.Text(rotulo, style: _estilo(9)),
        ],
      );

  pw.Widget _secao(String titulo) => pw.Padding(
        padding: pw.EdgeInsets.only(top: 12, bottom: 4),
        child: pw.Text(titulo.toUpperCase(), style: _estilo(10, negrito: true, cor: PdfColors.blueGrey800)),
      );

  pw.Widget _linha(String rotulo, String valor) => pw.Padding(
        padding: pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(width: 140, child: pw.Text(rotulo, style: _estilo(10, negrito: true))),
            pw.Expanded(child: pw.Text(valor, style: _estilo(10))),
          ],
        ),
      );

  pw.TextStyle _estilo(double tamanho, {bool negrito = false, PdfColor? cor}) => pw.TextStyle(
        fontSize: tamanho,
        fontWeight: negrito ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: cor,
      );

  String _rotuloDecisao(DecisaoOrcamento d) => switch (d) {
        DecisaoOrcamento.pendente => 'Pendente',
        DecisaoOrcamento.aprovado => 'Aprovado',
        DecisaoOrcamento.recusado => 'Recusado',
      };
}