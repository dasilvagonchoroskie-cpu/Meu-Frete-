@Tags(['capturas'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_frete/app.dart';
import 'package:meu_frete/dados/armazenamento.dart';
import 'package:meu_frete/dados/configuracao.dart';
import 'package:meu_frete/dados/dados.dart';
import 'package:meu_frete/regras/periodo.dart';
import 'package:meu_frete/relatorio/gerador_pdf.dart';
import 'package:meu_frete/telas/boas_vindas/tela_boas_vindas.dart';
import 'package:meu_frete/telas/casca.dart';
import 'package:meu_frete/telas/fretes/detalhe_frete.dart';
import 'package:meu_frete/telas/fretes/form_frete.dart';
import 'package:meu_frete/telas/relatorio/tela_relatorio.dart';
import 'package:meu_frete/telas/configuracoes/tela_configuracoes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apoio.dart';

/// Gera as imagens da Play Store (1080 x 1920) e PDFs de exemplo.
/// Roda com: flutter test --tags capturas --update-goldens
void main() {
  setUpAll(carregarFontes);

  Future<Dados> capturar(
    WidgetTester tester,
    String nome,
    Widget Function(Dados) tela, {
    String tema = 'claro',
    bool configurado = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'configuracao_inicial_feita': configurado, 'tema': tema});
    final config = await Configuracao.carregar();
    final dados = Dados(ArmazenamentoMemoria(inicial: amostra()));
    await dados.carregar();
    await tester.pumpWidget(MeuFreteApp(config: config, dados: dados, inicio: tela(dados)));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('capturas/$nome.png'));
    return dados;
  }

  testWidgets('01 resumo', (t) => capturar(t, '01_resumo', (_) => const Casca()));
  testWidgets('02 fretes', (t) => capturar(t, '02_fretes', (_) => const Casca(abaInicial: 1)));
  testWidgets('03 frete detalhe', (t) => capturar(t, '03_frete_detalhe', (d) => DetalheFrete(idFrete: 2)));
  testWidgets('04 frete formulario', (t) => capturar(t, '04_frete_formulario', (d) => FormFrete(editando: d.freteComId(2))));
  testWidgets('05 diesel', (t) => capturar(t, '05_diesel', (_) => const Casca(abaInicial: 2)));
  testWidgets('06 gastos', (t) => capturar(t, '06_gastos', (_) => const Casca(abaInicial: 3)));
  testWidgets('07 relatorio', (t) => capturar(t, '07_relatorio', (_) => const TelaRelatorio()));
  testWidgets('08 resumo noite', (t) => capturar(t, '08_resumo_noite', (_) => const Casca(), tema: 'escuro'));
  testWidgets('09 boas vindas', (t) => capturar(t, '09_boas_vindas', (_) => const TelaBoasVindas(), configurado: false));
  testWidgets('10 configuracoes', (t) => capturar(t, '10_configuracoes', (_) => const TelaConfiguracoes()));

  testWidgets('pdfs de exemplo', (tester) async {
    SharedPreferences.setMockInitialValues({'configuracao_inicial_feita': true});
    final config = await Configuracao.carregar();
    final dados = Dados(ArmazenamentoMemoria(inicial: amostra()));
    await dados.carregar();
    await tester.runAsync(() async {
      final fontes = await FontesPdf.carregar();
      final periodo = calcularPeriodo(TipoPeriodo.mesAtual)!;
      final mes = await gerarPdf(dados.dadosDoPeriodo(periodo, config.regras), fontes);
      final viagem = await gerarPdf(dados.dadosDaViagem(dados.freteComId(2)!, config.regras), fontes);
      Directory('test/capturas').createSync(recursive: true);
      File('test/capturas/relatorio_do_mes.pdf').writeAsBytesSync(mes);
      File('test/capturas/acerto_da_viagem.pdf').writeAsBytesSync(viagem);
    });
  });
}
