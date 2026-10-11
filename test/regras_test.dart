import 'package:flutter_test/flutter_test.dart';
import 'package:meu_frete/dados/modelos.dart';
import 'package:meu_frete/nucleo/formato.dart';
import 'package:meu_frete/regras/dados_relatorio.dart';
import 'package:meu_frete/regras/media_diesel.dart';
import 'package:meu_frete/regras/periodo.dart';
import 'package:meu_frete/regras/resumo.dart';

int d(int ano, int mes, int dia) => DateTime(ano, mes, dia).millisecondsSinceEpoch;

void main() {
  group('Frete', () {
    test('frete real, contratado, comissao e quebra', () {
      final f = Frete(
        origem: 'A',
        destino: 'B',
        dataCarga: d(2026, 10, 1),
        pesoKg: 37000,
        valorTonelada: 185,
        adiantamento: 4800,
        saldo: 1950,
        percentualComissao: 13,
        comissaoSobreBruto: false,
        pesoDescargaKg: 36880,
        descontoQuebra: 26,
      );
      expect(f.freteReal, 6750);
      expect(f.valorContratado, closeTo(6845, 0.001));
      expect(f.baseComissao, 6750);
      expect(f.minhaParte, closeTo(877.5, 0.001));
      expect(f.quebraKg, 120);
      expect(f.valorQuebraIntegral, closeTo(22.2, 0.001));
      expect(f.freteSemQuebra, 6776);
      expect(f.aguardandoSaldo, isFalse);
    });

    test('comissao sobre o bruto usa o peso da descarga quando tem', () {
      final f = Frete(
        origem: 'A',
        destino: 'B',
        dataCarga: 0,
        pesoKg: 30000,
        valorTonelada: 100,
        adiantamento: 2000,
        saldo: 500,
        percentualComissao: 10,
        comissaoSobreBruto: true,
        pesoDescargaKg: 29000,
      );
      expect(f.baseComissao, closeTo(2900, 0.001));
      expect(f.minhaParte, closeTo(290, 0.001));
    });

    test('sem descarga nao tem quebra', () {
      final f = Frete(origem: 'A', destino: 'B', dataCarga: 0, pesoKg: 30000);
      expect(f.quebraKg, isNull);
      expect(f.valorQuebraIntegral, 0);
    });

    test('mapa ida e volta', () {
      final f = Frete(id: 7, origem: 'A', destino: 'B', empresa: 'X', dataCarga: 5, pesoKg: 1, comissaoSobreBruto: false);
      final g = Frete.deMapa(f.paraMapa());
      expect(g.id, 7);
      expect(g.empresa, 'X');
      expect(g.comissaoSobreBruto, isFalse);
    });
  });

  group('Media do diesel', () {
    final salvas = [
      Abastecimento(id: 1, data: 0, km: 1000, pontoDePartida: true),
      Abastecimento(id: 2, data: 1, km: 1500, litros: 200, tanqueCheio: false),
      Abastecimento(id: 3, data: 2, km: 2000, litros: 150),
    ];

    test('soma os litros desde o ultimo tanque cheio', () {
      final m = mediaDaLinha(salvas, salvas[2]);
      expect(m.kmRodados, 1000);
      expect(m.litrosContados, 350);
      expect(m.media, closeTo(1000 / 350, 1e-9));
      expect(m.abastecidasContadas, 2);
      expect(m.kmReferencia, 1000);
    });

    test('tanque nao completado nao tem media', () {
      final m = mediaDaLinha(salvas, salvas[1]);
      expect(m.media, isNull);
      expect(m.motivo, contains('não foi completado'));
    });

    test('primeira cheia nao tem media', () {
      final m = calcularMedia(const [], km: 500, litros: 100, tanqueCheio: true);
      expect(m.media, isNull);
      expect(m.motivo, contains('primeira'));
    });

    test('nova abastecida conta a partir da ultima cheia', () {
      final m = calcularMedia(salvas, km: 2600, litros: 240, tanqueCheio: true);
      expect(m.kmRodados, 600);
      expect(m.media, closeTo(2.5, 1e-9));
    });

    test('media do periodo e km total sobre litros totais', () {
      final mp = mediaDoPeriodo(salvas, salvas);
      expect(mp.km, 1000);
      expect(mp.litros, 350);
    });
  });

  group('Resumo', () {
    final fretes = [
      Frete(origem: 'A', destino: 'B', dataCarga: 0, pesoKg: 10000, valorTonelada: 100, adiantamento: 600, saldo: 300, percentualComissao: 10, comissaoSobreBruto: false, pedagio: 50),
      Frete(origem: 'B', destino: 'C', dataCarga: 0, pesoKg: 10000, valorTonelada: 200, adiantamento: 0, saldo: 0, percentualComissao: 10, comissaoSobreBruto: false),
    ];

    test('regra padrao: valor cheio, gastos da empresa, vale desconta', () {
      final r = calcularResumo(fretes: fretes, abastecimentos: [400], gastos: [100], vales: [50]);
      expect(r.totalFretes, 900);
      expect(r.comissao, closeTo(90, 1e-9));
      expect(r.liquido, closeTo(40, 1e-9));
      expect(r.totalGastoGeral, 500);
      expect(r.fretesEmAberto, 1);
      expect(r.contratadoEmAberto, 2000);
      expect(r.totalContratado, 1000);
      expect(r.totalDescontoDoFrete, 100);
      expect(r.comissaoDoCaminhao, closeTo(90, 1e-9));
      expect(r.sobraDoCaminhao, closeTo(900 - 400 - 100 - 90, 1e-9));
      expect(r.totalPedagio, 50);
    });

    test('gastos do bolso descontam', () {
      final r = calcularResumo(
        fretes: fretes,
        abastecimentos: [400],
        gastos: [100],
        vales: [50],
        regras: const Regras(gastosDescontamDoLiquido: true),
      );
      expect(r.liquido, closeTo(90 - 500 - 50, 1e-9));
    });

    test('so a minha parte: comissao e o proprio frete', () {
      final r = calcularResumo(
        fretes: fretes,
        abastecimentos: const [],
        gastos: const [],
        vales: [50],
        regras: const Regras(freteRealEhValorCheio: false, valeDescontaDoLiquido: false),
      );
      expect(r.comissao, 900);
      expect(r.liquido, 900);
      expect(r.percentualMedio, 0);
    });
  });

  group('Periodos', () {
    final agora = DateTime(2026, 10, 11, 15, 0);

    test('este mes', () {
      final p = calcularPeriodo(TipoPeriodo.mesAtual, agora: agora)!;
      expect(dataTexto(p.inicio), '01/10/2026');
      expect(dataTexto(p.fim), '31/10/2026');
    });

    test('mes passado', () {
      final p = calcularPeriodo(TipoPeriodo.mesPassado, agora: agora)!;
      expect(dataTexto(p.inicio), '01/09/2026');
      expect(dataTexto(p.fim), '30/09/2026');
    });

    test('mes passado em janeiro volta para dezembro', () {
      final p = calcularPeriodo(TipoPeriodo.mesPassado, agora: DateTime(2027, 1, 5))!;
      expect(dataTexto(p.inicio), '01/12/2026');
      expect(dataTexto(p.fim), '31/12/2026');
    });

    test('ultimos 7 dias inclui hoje', () {
      final p = calcularPeriodo(TipoPeriodo.seteDias, agora: agora)!;
      expect(dataTexto(p.inicio), '05/10/2026');
      expect(dataTexto(p.fim), '11/10/2026');
    });

    test('datas escolhidas fora de ordem nao valem', () {
      expect(
        calcularPeriodo(TipoPeriodo.escolher, inicio: DateTime(2026, 10, 10), fim: DateTime(2026, 10, 1)),
        isNull,
      );
    });

    test('janela da viagem', () {
      final cargas = [d(2026, 10, 2), d(2026, 10, 6), d(2026, 10, 10)];
      final meio = janelaDaViagem(d(2026, 10, 6), cargas, agora: agora);
      expect(dataTexto(meio.inicio), '07/10/2026');
      expect(dataTexto(meio.fim), '10/10/2026');
      final primeira = janelaDaViagem(d(2026, 10, 2), cargas, agora: agora);
      expect(dataTexto(primeira.inicio), '02/10/2026');
      expect(dataTexto(primeira.fim), '06/10/2026');
      final ultima = janelaDaViagem(d(2026, 10, 10), cargas, agora: agora);
      expect(dataTexto(ultima.fim), '11/10/2026');
    });

    test('acerto da viagem sempre inclui o proprio frete', () {
      final fretes = [
        Frete(id: 1, origem: 'A', destino: 'B', dataCarga: d(2026, 10, 2), adiantamento: 1000),
        Frete(id: 2, origem: 'B', destino: 'C', dataCarga: d(2026, 10, 6), adiantamento: 2000, saldo: 500),
      ];
      final gastos = [
        Gasto(id: 1, data: d(2026, 10, 6), valor: 10, categoria: 'x'),
        Gasto(id: 2, data: d(2026, 10, 8), valor: 20, categoria: 'y'),
      ];
      final dr = montarDadosDaViagem(
        frete: fretes[1],
        fretes: fretes,
        abastecimentos: const [],
        vales: const [],
        gastos: gastos,
        ajustes: const [],
        regras: const Regras(),
        agora: agora,
      );
      expect(dr.fretes.single.id, 2);
      expect(dr.resultado.totalFretes, 2500);
      expect(dr.gastos.map((g) => g.id), [2]);
      expect(dr.viagem, 'B para C');
    });
  });
}
