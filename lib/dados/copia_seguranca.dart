import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../nucleo/formato.dart';
import 'armazenamento.dart';
import 'configuracao.dart';
import 'dados.dart';
import 'modelos.dart';

/// Copia de seguranca num arquivo .json que o motorista guarda onde quiser
/// (WhatsApp, Drive, e-mail) e restaura em outro celular.
class CopiaSeguranca {
  static const _marca = 'meufrete';
  static const _versao = 1;

  static String gerarTexto(Dados dados, Configuracao config) => const JsonEncoder.withIndent(' ').convert({
        'app': _marca,
        'versao': _versao,
        'criadoEm': DateTime.now().millisecondsSinceEpoch,
        'configuracao': config.paraMapa(),
        'tabelas': dados.exportar(),
      });

  static Future<void> exportar(Dados dados, Configuracao config) async {
    final pasta = await getTemporaryDirectory();
    final agora = DateTime.now();
    final nome = 'MeuFrete_copia_${dataTexto(agora.millisecondsSinceEpoch).replaceAll('/', '-')}.json';
    final arquivo = File('${pasta.path}/$nome');
    await arquivo.writeAsString(gerarTexto(dados, config));
    await Share.shareXFiles(
      [XFile(arquivo.path, mimeType: 'application/json', name: nome)],
      subject: 'Cópia de segurança do Meu Frete',
      text: 'Cópia de segurança do Meu Frete. Guarde este arquivo para restaurar seus registros.',
    );
  }

  /// Abre o seletor de arquivos e devolve a copia lida (ou null se cancelou).
  static Future<CopiaLida?> escolherArquivo() async {
    // Sem filtro de tipo: arquivo baixado do WhatsApp as vezes chega sem o tipo .json.
    final arquivo = await openFile();
    if (arquivo == null) return null;
    final bytes = await arquivo.readAsBytes();
    return ler(utf8.decode(bytes, allowMalformed: true));
  }

  /// Le e confere o conteudo de uma copia.
  static CopiaLida ler(String texto) {
    Object? json;
    try {
      json = jsonDecode(texto);
    } catch (_) {
      throw const FormatException('Este arquivo não é uma cópia do Meu Frete.');
    }
    if (json is! Map || json['app'] != _marca || json['tabelas'] is! Map) {
      throw const FormatException('Este arquivo não é uma cópia do Meu Frete.');
    }
    final tabelas = json['tabelas'] as Map;
    List<Map<String, Object?>> linhas(String t) {
      final l = tabelas[t];
      if (l is! List) return [];
      return l.whereType<Map>().map((m) => Map<String, Object?>.from(m)).toList();
    }

    // Passa cada linha pelo modelo: descarta campo estranho e completa o que faltar.
    final limpas = <String, List<Map<String, Object?>>>{
      tabelaFretes: linhas(tabelaFretes).map((m) {
        final f = Frete.deMapa(m);
        return {...f.paraMapa(), 'id': f.id};
      }).toList(),
      tabelaAbastecimentos: linhas(tabelaAbastecimentos).map((m) {
        final a = Abastecimento.deMapa(m);
        return {...a.paraMapa(), 'id': a.id};
      }).toList(),
      tabelaAjustes: linhas(tabelaAjustes).map((m) {
        final a = AjusteKm.deMapa(m);
        return {...a.paraMapa(), 'id': a.id};
      }).toList(),
      tabelaGastos: linhas(tabelaGastos).map((m) {
        final g = Gasto.deMapa(m);
        return {...g.paraMapa(), 'id': g.id};
      }).toList(),
      tabelaVales: linhas(tabelaVales).map((m) {
        final v = Vale.deMapa(m);
        return {...v.paraMapa(), 'id': v.id};
      }).toList(),
    };
    for (final l in limpas.values) {
      for (final m in l) {
        if (m['id'] == 0) m.remove('id');
      }
    }
    final config = json['configuracao'];
    final criadoEm = json['criadoEm'];
    return CopiaLida(
      tabelas: limpas,
      configuracao: config is Map ? Map<String, Object?>.from(config) : const {},
      criadoEm: criadoEm is num ? criadoEm.toInt() : 0,
    );
  }
}

class CopiaLida {
  const CopiaLida({required this.tabelas, required this.configuracao, required this.criadoEm});

  final Map<String, List<Map<String, Object?>>> tabelas;
  final Map<String, Object?> configuracao;
  final int criadoEm;

  int quantos(String tabela) => tabelas[tabela]?.length ?? 0;

  String get descricao {
    final partes = <String>[
      plural(quantos(tabelaFretes), 'frete', 'fretes'),
      plural(quantos(tabelaAbastecimentos), 'abastecida', 'abastecidas'),
      plural(quantos(tabelaGastos), 'gasto', 'gastos'),
      plural(quantos(tabelaVales), 'vale', 'vales'),
    ];
    return partes.join(', ');
  }
}
