import 'package:flutter_test/flutter_test.dart';

import 'package:netgames_os_app/models/desconto.dart';

void main() {
  group('Desconto', () {
    test('sem desconto não tira nada', () {
      expect(Desconto.nenhum.aplicadoSobre(100), 0);
      expect(Desconto.nenhum.existe, isFalse);
    });

    test('valor fixo tira o valor informado', () {
      const d = Desconto(tipo: TipoDesconto.valor, quantidade: 20);
      expect(d.aplicadoSobre(100), 20);
    });

    test('percentual calcula sobre o subtotal', () {
      const d = Desconto(tipo: TipoDesconto.percentual, quantidade: 10);
      expect(d.aplicadoSobre(250), 25);
    });

    test('desconto nunca passa do subtotal', () {
      const fixo = Desconto(tipo: TipoDesconto.valor, quantidade: 500);
      const pct = Desconto(tipo: TipoDesconto.percentual, quantidade: 150);
      expect(fixo.aplicadoSobre(100), 100);
      expect(pct.aplicadoSobre(100), 100);
    });

    test('subtotal zero não gera desconto', () {
      const d = Desconto(tipo: TipoDesconto.valor, quantidade: 30);
      expect(d.aplicadoSobre(0), 0);
    });

    test('lê OS antiga sem o campo desconto', () {
      expect(Desconto.fromMap(null).existe, isFalse);
    });

    test('vai e volta pelo Map', () {
      const d = Desconto(tipo: TipoDesconto.percentual, quantidade: 7.5);
      final volta = Desconto.fromMap(d.toMap());
      expect(volta.tipo, TipoDesconto.percentual);
      expect(volta.quantidade, 7.5);
      expect(d.rotulo, '7,5%');
    });
  });
}
