import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortaleza_licenca/fortaleza_licenca.dart';
import 'package:meu_frete/app.dart';
import 'package:meu_frete/dados/armazenamento.dart';
import 'package:meu_frete/dados/configuracao.dart';
import 'package:meu_frete/dados/dados.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apoio.dart';

/// APK de venda direta: o Meu Frete so abre no aparelho liberado pela
/// Central de Licencas. A versao da Play Store (sem licenca) e testada em
/// app_test.dart.
void main() {
  setUpAll(carregarFontes);

  testWidgets('venda direta: aparelho nao liberado ve a tela de pedir liberacao', (tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'configuracao_inicial_feita': true});
    final config = await Configuracao.carregar();
    final dados = Dados(ArmazenamentoMemoria());
    await dados.carregar();
    final licenca = ControleLicenca(
      const ConfiguracaoLicenca(appId: 'meufrete', nomeApp: 'Meu Frete', versaoApp: versaoApp),
      servidor: ServidorLicenca(
        transporte: (rota, corpo) async => const RespostaBruta(200, {
          'ok': true,
          'servico': 'fortaleza-licencas',
          'liberado': false,
          'situacao': 'sem_licenca',
          'motivo': 'Este aparelho ainda não está liberado.',
          'contato': {'whatsapp': '5564996472794'},
          'app': {'nome': 'Meu Frete', 'preco': '', 'teste_dias': 7},
          'teste_disponivel': true,
        }),
      ),
      lerIdDoAparelho: () async => 'aparelho-de-teste',
      lerModelo: () async => 'celular de teste',
    );

    await tester.pumpWidget(MeuFreteApp(config: config, dados: dados, licenca: licenca));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Pedir liberação'), findsWidgets);
    expect(find.text('Começar teste grátis de 7 dias'), findsOneWidget);
    expect(find.text('Você tem para receber'), findsNothing);
  });
}
