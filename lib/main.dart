import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortaleza_licenca/fortaleza_licenca.dart';

import 'app.dart';
import 'dados/armazenamento.dart';
import 'dados/configuracao.dart';
import 'dados/dados.dart';

/// APK de venda direta (WhatsApp): passa pela Central de Licencas.
/// A versao da Play Store compila com --dart-define=LICENCA_CENTRAL=false.
const licencaCentral = bool.fromEnvironment('LICENCA_CENTRAL', defaultValue: true);

final _licenca = ControleLicenca(const ConfiguracaoLicenca(
  appId: 'meufrete',
  nomeApp: 'Meu Frete',
  versaoApp: versaoApp,
));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final config = await Configuracao.carregar();
  final dados = Dados(ArmazenamentoSqlite(), placa: config.placaAtual);
  await dados.carregar();
  runApp(MeuFreteApp(config: config, dados: dados, licenca: licencaCentral ? _licenca : null));
}
