import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_frete/dados/armazenamento.dart';
import 'package:meu_frete/dados/modelos.dart';
import 'package:meu_frete/nucleo/formato.dart';

/// Carrega as letras do app (Barlow e os icones) para as imagens sairem reais.
Future<void> carregarFontes() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifesto = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final f in manifesto) {
    final familia = (f as Map<String, dynamic>)['family'] as String;
    final carregador = FontLoader(familia.replaceFirst(RegExp(r'^packages/[^/]+/'), ''));
    for (final fonte in f['fonts'] as List<dynamic>) {
      carregador.addFont(rootBundle.load((fonte as Map<String, dynamic>)['asset'] as String));
    }
    await carregador.load();
  }
}

int dia(int d, {int mesesAtras = 0}) {
  final agora = DateTime.now();
  return inicioDoDia(DateTime(agora.year, agora.month - mesesAtras, d));
}

/// Dados de exemplo parecidos com os de um motorista de verdade.
Map<String, List<Map<String, Object?>>> amostra() {
  final fretes = [
    Frete(
      id: 1,
      origem: 'Jataí (GO)',
      destino: 'Paranaguá (PR)',
      empresa: 'Transportes Cerrado',
      dataCarga: dia(20, mesesAtras: 1),
      pesoKg: 37000,
      valorTonelada: 210,
      adiantamento: 5400,
      saldo: 2250,
      pedagio: 690,
      percentualComissao: 13,
      comissaoSobreBruto: false,
    ),
    Frete(
      id: 2,
      origem: 'Rio Verde (GO)',
      destino: 'Santos (SP)',
      empresa: 'Transportes Cerrado',
      dataCarga: dia(2),
      pesoKg: 37000,
      valorTonelada: 185,
      adiantamento: 4800,
      saldo: 1950,
      pedagio: 612,
      percentualComissao: 13,
      comissaoSobreBruto: false,
      pesoDescargaKg: 36880,
      descontoQuebra: 26,
    ),
    Frete(
      id: 3,
      origem: 'Santos (SP)',
      destino: 'Uberlândia (MG)',
      empresa: 'Rodo Sul Logística',
      dataCarga: dia(6),
      pesoKg: 33040,
      valorTonelada: 120,
      adiantamento: 2800,
      saldo: 1100,
      pedagio: 380,
      percentualComissao: 13,
      comissaoSobreBruto: false,
    ),
    Frete(
      id: 4,
      origem: 'Uberlândia (MG)',
      destino: 'Rio Verde (GO)',
      empresa: 'Agro Trans',
      dataCarga: dia(10),
      pesoKg: 35500,
      valorTonelada: 95,
      adiantamento: 2400,
      saldo: 0,
      percentualComissao: 13,
      comissaoSobreBruto: false,
    ),
  ];
  final abastecimentos = [
    Abastecimento(id: 10, data: dia(1, mesesAtras: 1), cidade: 'Jataí (GO)', km: 412300, pontoDePartida: true),
    Abastecimento(id: 11, data: dia(21, mesesAtras: 1), cidade: 'Jataí (GO)', posto: 'Posto Trevão', litros: 420, valor: 2541, km: 413190),
    Abastecimento(id: 12, data: dia(2), cidade: 'Rio Verde (GO)', posto: 'Posto Rodoeste', litros: 395, valor: 2389.75, km: 414150),
    Abastecimento(id: 13, data: dia(4), cidade: 'Campinas (SP)', posto: 'Graal 67', litros: 180, valor: 1132.2, km: 414760, tanqueCheio: false),
    Abastecimento(id: 14, data: dia(6), cidade: 'Santos (SP)', posto: 'Posto Ilha', litros: 210, valor: 1323, km: 415205),
    Abastecimento(id: 15, data: dia(10), cidade: 'Uberlândia (MG)', posto: 'Posto Chaparral', litros: 360, valor: 2196, km: 416080),
  ];
  final gastos = [
    Gasto(id: 20, data: dia(3), valor: 180, categoria: 'Borracharia'),
    Gasto(id: 21, data: dia(6), valor: 250, categoria: 'Chapa'),
    Gasto(id: 22, data: dia(7), valor: 64.5, categoria: 'Alimentação'),
    Gasto(id: 23, data: dia(9), valor: 320, categoria: 'Manutenção'),
  ];
  final vales = [
    Vale(id: 30, data: dia(5), valor: 300),
    Vale(id: 31, data: dia(9), valor: 500),
  ];
  final ajustes = [
    AjusteKm(id: 40, quando: dia(3, mesesAtras: 1) + 36000000, kmAnterior: 412030, kmNovo: 412300, motivo: 'Aferição do painel'),
  ];
  Map<String, Object?> comId(Map<String, Object?> m, int id) => {...m, 'id': id};
  return {
    tabelaFretes: [for (final f in fretes) comId(f.paraMapa(), f.id)],
    tabelaAbastecimentos: [for (final a in abastecimentos) comId(a.paraMapa(), a.id)],
    tabelaGastos: [for (final g in gastos) comId(g.paraMapa(), g.id)],
    tabelaVales: [for (final v in vales) comId(v.paraMapa(), v.id)],
    tabelaAjustes: [for (final a in ajustes) comId(a.paraMapa(), a.id)],
  };
}
