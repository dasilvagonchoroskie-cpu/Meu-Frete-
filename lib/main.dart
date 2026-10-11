import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'dados/armazenamento.dart';
import 'dados/configuracao.dart';
import 'dados/dados.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final config = await Configuracao.carregar();
  final dados = Dados(ArmazenamentoSqlite());
  await dados.carregar();
  runApp(MeuFreteApp(config: config, dados: dados));
}
