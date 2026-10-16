import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_frete/app.dart';
import 'package:meu_frete/dados/armazenamento.dart';
import 'package:meu_frete/dados/configuracao.dart';
import 'package:meu_frete/dados/copia_seguranca.dart';
import 'package:meu_frete/dados/dados.dart';
import 'package:meu_frete/dados/modelos.dart';
import 'package:meu_frete/relatorio/gerador_pdf.dart';
import 'package:meu_frete/regras/periodo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apoio.dart';

Future<(Configuracao, Dados)> preparar({bool configurado = true, bool comAmostra = true}) async {
  SharedPreferences.setMockInitialValues(configurado ? preferenciasProntas() : <String, Object>{});
  final config = await Configuracao.carregar();
  final dados = Dados(ArmazenamentoMemoria(inicial: comAmostra ? amostra() : null), placa: config.placaAtual);
  await dados.carregar();
  return (config, dados);
}

void main() {
  setUpAll(carregarFontes);

  testWidgets('primeira abertura mostra a configuracao guiada e termina no app', (tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (config, dados) = await preparar(configurado: false, comAmostra: false);
    await tester.pumpWidget(MeuFreteApp(config: config, dados: dados));
    await tester.pumpAndSettle();
    expect(find.text('Começar'), findsOneWidget);
    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();
    // Nome e placa sao obrigatorios: sem eles nao passa.
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Escreva o nome do motorista.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Nome do motorista'), 'Evandro');
    await tester.enterText(find.widgetWithText(TextField, 'Placa do caminhão'), 'abc1d23');
    await tester.pumpAndSettle();
    expect(find.text('ABC1D23'), findsWidgets);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Abrir o app'));
    await tester.pumpAndSettle();
    expect(config.configuracaoInicialFeita, isTrue);
    expect(config.nomeMotorista, 'Evandro');
    expect(config.placaAtual, 'ABC1D23');
    expect(find.text('Você tem para receber'), findsOneWidget);
  });

  testWidgets('quem atualizou da 2.1 informa nome e placa e os registros ficam com o caminhao', (tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'configuracao_inicial_feita': true});
    final config = await Configuracao.carregar();
    final semPlaca = amostra().map((t, linhas) => MapEntry(t, [for (final l in linhas) {...l, 'placa': ''}]));
    final dados = Dados(ArmazenamentoMemoria(inicial: semPlaca));
    await dados.carregar();
    await tester.pumpWidget(MeuFreteApp(config: config, dados: dados));
    await tester.pumpAndSettle();
    expect(find.text('Salvar e continuar'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Nome do motorista'), 'Evandro');
    await tester.enterText(find.widgetWithText(TextField, 'Placa do caminhão'), 'RVG2C47');
    await tester.tap(find.text('Salvar e continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Você tem para receber'), findsOneWidget);
    expect(dados.fretes, hasLength(4));
    expect(dados.fretes.every((f) => f.placa == 'RVG2C47'), isTrue);
  });

  testWidgets('trocar de caminhao comeca do zero e o anterior fica guardado', (tester) async {
    final (config, dados) = await preparar();
    expect(dados.fretes, hasLength(4));
    config.placaAtual = 'ABC1D23';
    dados.usarPlaca('ABC1D23');
    expect(dados.fretes, isEmpty);
    expect(dados.pontoDePartida, isNull);
    await dados.salvarFrete(Frete(origem: 'Goiatuba (GO)', destino: 'Santos (SP)', dataCarga: dia(3), adiantamento: 900));
    expect(dados.fretes.single.placa, 'ABC1D23');
    expect(config.placasUsadas, containsAll(['RVG2C47', 'ABC1D23']));
    dados.usarPlaca('RVG2C47');
    expect(dados.fretes, hasLength(4));
    expect(dados.placasComRegistro, ['ABC1D23', 'RVG2C47']);
    await dados.corrigirPlaca('ABC1D23', 'ABC1D24');
    dados.usarPlaca('ABC1D24');
    expect(dados.fretes, hasLength(1));
    final viagem = dados.dadosDaViagem(dados.fretes.single, config.regras, motorista: 'Evandro');
    expect(viagem.placa, 'ABC1D24');
    expect(nomeDoArquivoPdf(viagem), startsWith('MeuFrete_ABC1D24_viagem_'));
  });

  testWidgets('as cinco abas abrem sem erro', (tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (config, dados) = await preparar();
    await tester.pumpWidget(MeuFreteApp(config: config, dados: dados));
    await tester.pumpAndSettle();
    for (final aba in ['Fretes', 'Diesel', 'Gastos', 'Vales', 'Resumo']) {
      await tester.tap(find.text(aba).last);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('anotar um frete novo aparece na lista', (tester) async {
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (config, dados) = await preparar(comAmostra: false);
    await tester.pumpWidget(MeuFreteApp(config: config, dados: dados));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fretes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo frete'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Origem (de onde saiu)'), 'Goiatuba (GO)');
    await tester.enterText(find.widgetWithText(TextField, 'Destino (para onde vai)'), 'Santos (SP)');
    await tester.enterText(find.widgetWithText(TextField, 'Adiantamento'), '500000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar frete'));
    await tester.pumpAndSettle();
    expect(dados.fretes, hasLength(1));
    expect(dados.fretes.first.adiantamento, 5000);
    expect(find.text('Goiatuba (GO)'), findsOneWidget);
  });

  testWidgets('copia de seguranca ida e volta', (tester) async {
    final (config, dados) = await preparar();
    final texto = CopiaSeguranca.gerarTexto(dados, config);
    final lida = CopiaSeguranca.ler(texto);
    expect(lida.quantos(tabelaFretes), dados.fretes.length);
    expect(lida.quantos(tabelaAbastecimentos), dados.abastecimentos.length);
    final outro = Dados(ArmazenamentoMemoria());
    await outro.carregar();
    await outro.substituirTudo(lida.tabelas);
    expect(outro.fretes.length, dados.fretes.length);
    expect(outro.gastos.map((g) => g.valor).toList(), dados.gastos.map((g) => g.valor).toList());
    expect(() => CopiaSeguranca.ler('{"x":1}'), throwsFormatException);
  });

  testWidgets('pdf do relatorio e do acerto', (tester) async {
    final (config, dados) = await preparar();
    final fontes = await tester.runAsync(FontesPdf.carregar);
    final periodo = calcularPeriodo(TipoPeriodo.mesAtual)!;
    final bytes = await tester.runAsync(() => gerarPdf(dados.dadosDoPeriodo(periodo, config.regras), fontes!));
    expect(String.fromCharCodes(bytes!.take(4)), '%PDF');
    final viagem = dados.dadosDaViagem(dados.fretes.first, config.regras);
    final bytes2 = await tester.runAsync(() => gerarPdf(viagem, fontes!));
    expect(bytes2!.length, greaterThan(1000));
    expect(nomeDoArquivoPdf(viagem), startsWith('MeuFrete_viagem_'));
  });
}
