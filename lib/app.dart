import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fortaleza_licenca/fortaleza_licenca.dart';
import 'package:provider/provider.dart';

import 'dados/configuracao.dart';
import 'dados/dados.dart';
import 'tema.dart';
import 'telas/boas_vindas/tela_boas_vindas.dart';
import 'telas/caminhao/tela_caminhao.dart';
import 'telas/casca.dart';

const versaoApp = '2.2.0';
const enderecoPrivacidade = 'https://fortalezadigitalsecurity.com.br/meufrete/privacidade.html';
const enderecoSite = 'https://fortalezadigitalsecurity.com.br';

class MeuFreteApp extends StatelessWidget {
  const MeuFreteApp({super.key, required this.config, required this.dados, this.inicio, this.licenca});

  final Configuracao config;
  final Dados dados;

  /// Licenca pela Central (so no APK de venda direta). Null = sem portao,
  /// como na versao da Play Store.
  final ControleLicenca? licenca;

  /// Tela inicial forcada (usado nas imagens da loja).
  final Widget? inicio;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Configuracao>.value(value: config),
        ChangeNotifierProvider<Dados>.value(value: dados),
      ],
      child: Consumer<Configuracao>(
        builder: (context, cfg, _) => MaterialApp(
          title: 'Meu Frete',
          debugShowCheckedModeBanner: false,
          theme: temaClaro,
          darkTheme: temaEscuro,
          themeMode: cfg.tema,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: inicio ?? _comLicenca(const Raiz()),
        ),
      ),
    );
  }

  /// No APK de venda direta, o app so abre no aparelho liberado pela
  /// Central de Licencas (pedido de liberacao sem chave, teste gratis, chave).
  Widget _comLicenca(Widget raiz) {
    final controle = licenca;
    if (controle == null) return raiz;
    return PortaoLicenca(controle: controle, icone: Icons.local_shipping, child: raiz);
  }
}

/// Primeira tela: a configuracao guiada (so na primeira vez) ou as abas.
class Raiz extends StatelessWidget {
  const Raiz({super.key});

  @override
  Widget build(BuildContext context) {
    final (feita, identificado) =
        context.select<Configuracao, (bool, bool)>((c) => (c.configuracaoInicialFeita, c.identificado));
    if (!feita) return const TelaBoasVindas();
    // Quem ja usava antes da versao 2.2 informa nome e placa uma vez.
    if (!identificado) return const TelaIdentificacao();
    return const Casca();
  }
}
