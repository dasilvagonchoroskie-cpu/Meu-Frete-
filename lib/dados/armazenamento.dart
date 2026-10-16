import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'modelos.dart';

/// Onde os registros ficam guardados. No celular e o SQLite; nos testes e
/// na geracao das imagens da loja, uma versao em memoria.
abstract class Armazenamento {
  Future<void> abrir();

  Future<List<Frete>> fretes();
  Future<List<Abastecimento>> abastecimentos();
  Future<List<AjusteKm>> ajustes();
  Future<List<Gasto>> gastos();
  Future<List<Vale>> vales();

  Future<int> inserir(String tabela, Map<String, Object?> dados);
  Future<void> atualizar(String tabela, int id, Map<String, Object?> dados);
  Future<void> apagar(String tabela, int id);

  /// Troca tudo de uma vez (restaurar copia de seguranca).
  Future<void> substituirTudo(Map<String, List<Map<String, Object?>>> tabelas);

  /// Troca a placa de todos os registros [de] para [para]. Com [de] vazio,
  /// marca os registros que ainda nao tinham caminhao (versao 2.0/2.1).
  Future<void> renomearPlaca(String de, String para);
}

const tabelaFretes = 'fretes';
const tabelaAbastecimentos = 'abastecimentos';
const tabelaAjustes = 'ajustes_km';
const tabelaGastos = 'gastos';
const tabelaVales = 'vales';

const todasAsTabelas = [tabelaFretes, tabelaAbastecimentos, tabelaAjustes, tabelaGastos, tabelaVales];

class ArmazenamentoSqlite implements Armazenamento {
  Database? _db;

  Database get _banco {
    final db = _db;
    if (db == null) throw StateError('Banco ainda nao foi aberto');
    return db;
  }

  @override
  Future<void> abrir() async {
    final pasta = await getDatabasesPath();
    _db = await openDatabase(
      p.join(pasta, 'meufrete.db'),
      version: 2,
      onUpgrade: (db, antiga, nova) async {
        // Versao 2 (Meu Frete 2.2): cada registro guarda a placa do caminhao.
        if (antiga < 2) {
          for (final t in todasAsTabelas) {
            await db.execute("ALTER TABLE $t ADD COLUMN placa TEXT NOT NULL DEFAULT ''");
          }
        }
      },
      onCreate: (db, versao) async {
        await db.execute('CREATE TABLE IF NOT EXISTS fretes ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, '
            'origem TEXT NOT NULL, destino TEXT NOT NULL, empresa TEXT NOT NULL, '
            'dataCarga INTEGER NOT NULL, pesoKg REAL NOT NULL, valorTonelada REAL NOT NULL, '
            'adiantamento REAL NOT NULL, saldo REAL NOT NULL, '
            'percentualComissao REAL NOT NULL DEFAULT 13.0, pedagio REAL NOT NULL DEFAULT 0.0, '
            'comissaoSobreBruto INTEGER NOT NULL DEFAULT 1, pesoDescargaKg REAL NOT NULL DEFAULT 0.0, '
            "descontoQuebra REAL NOT NULL DEFAULT 0.0, placa TEXT NOT NULL DEFAULT '')");
        await db.execute('CREATE TABLE IF NOT EXISTS abastecimentos ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, data INTEGER NOT NULL, '
            'cidade TEXT NOT NULL, posto TEXT NOT NULL, litros REAL NOT NULL, valor REAL NOT NULL, '
            "km REAL NOT NULL, tanqueCheio INTEGER NOT NULL, pontoDePartida INTEGER NOT NULL, placa TEXT NOT NULL DEFAULT '')");
        await db.execute('CREATE TABLE IF NOT EXISTS ajustes_km ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, quando INTEGER NOT NULL, '
            "kmAnterior REAL NOT NULL, kmNovo REAL NOT NULL, motivo TEXT NOT NULL, placa TEXT NOT NULL DEFAULT '')");
        await db.execute('CREATE TABLE IF NOT EXISTS gastos ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, data INTEGER NOT NULL, '
            "valor REAL NOT NULL, categoria TEXT NOT NULL, placa TEXT NOT NULL DEFAULT '')");
        await db.execute('CREATE TABLE IF NOT EXISTS vales ('
            "id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, data INTEGER NOT NULL, valor REAL NOT NULL, placa TEXT NOT NULL DEFAULT '')");
      },
    );
  }

  @override
  Future<List<Frete>> fretes() async =>
      (await _banco.query(tabelaFretes, orderBy: 'dataCarga DESC, id DESC')).map(Frete.deMapa).toList();

  @override
  Future<List<Abastecimento>> abastecimentos() async =>
      (await _banco.query(tabelaAbastecimentos, orderBy: 'km DESC, id DESC')).map(Abastecimento.deMapa).toList();

  @override
  Future<List<AjusteKm>> ajustes() async =>
      (await _banco.query(tabelaAjustes, orderBy: 'quando DESC, id DESC')).map(AjusteKm.deMapa).toList();

  @override
  Future<List<Gasto>> gastos() async =>
      (await _banco.query(tabelaGastos, orderBy: 'data DESC, id DESC')).map(Gasto.deMapa).toList();

  @override
  Future<List<Vale>> vales() async =>
      (await _banco.query(tabelaVales, orderBy: 'data DESC, id DESC')).map(Vale.deMapa).toList();

  @override
  Future<int> inserir(String tabela, Map<String, Object?> dados) {
    final semId = Map<String, Object?>.from(dados)..remove('id');
    return _banco.insert(tabela, semId);
  }

  @override
  Future<void> atualizar(String tabela, int id, Map<String, Object?> dados) async {
    final semId = Map<String, Object?>.from(dados)..remove('id');
    await _banco.update(tabela, semId, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> apagar(String tabela, int id) async {
    await _banco.delete(tabela, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> substituirTudo(Map<String, List<Map<String, Object?>>> tabelas) async {
    await _banco.transaction((txn) async {
      for (final t in todasAsTabelas) {
        await txn.delete(t);
      }
      for (final t in todasAsTabelas) {
        for (final linha in tabelas[t] ?? const <Map<String, Object?>>[]) {
          await txn.insert(t, linha);
        }
      }
    });
  }

  @override
  Future<void> renomearPlaca(String de, String para) async {
    await _banco.transaction((txn) async {
      for (final t in todasAsTabelas) {
        await txn.update(t, {'placa': para}, where: 'placa = ?', whereArgs: [de]);
      }
    });
  }
}

/// Versao em memoria (testes e imagens da loja).
class ArmazenamentoMemoria implements Armazenamento {
  ArmazenamentoMemoria({Map<String, List<Map<String, Object?>>>? inicial}) {
    for (final t in todasAsTabelas) {
      _tabelas[t] = [];
    }
    if (inicial != null) {
      inicial.forEach((t, linhas) {
        for (final l in linhas) {
          final copia = Map<String, Object?>.from(l);
          if (copia['id'] == null || copia['id'] == 0) copia['id'] = ++_ultimoId;
          final id = (copia['id'] as num).toInt();
          if (id > _ultimoId) _ultimoId = id;
          _tabelas[t]!.add(copia);
        }
      });
    }
  }

  final Map<String, List<Map<String, Object?>>> _tabelas = {};
  int _ultimoId = 0;

  @override
  Future<void> abrir() async {}

  List<Map<String, Object?>> _ordenado(String t, int Function(Map<String, Object?>, Map<String, Object?>) cmp) {
    final l = List<Map<String, Object?>>.from(_tabelas[t]!);
    l.sort(cmp);
    return l;
  }

  int _desc(Object? a, Object? b) => (b as num).compareTo(a as num);

  @override
  Future<List<Frete>> fretes() async => _ordenado(tabelaFretes, (a, b) {
        final c = _desc(a['dataCarga'], b['dataCarga']);
        return c != 0 ? c : _desc(a['id'], b['id']);
      }).map(Frete.deMapa).toList();

  @override
  Future<List<Abastecimento>> abastecimentos() async => _ordenado(tabelaAbastecimentos, (a, b) {
        final c = _desc(a['km'], b['km']);
        return c != 0 ? c : _desc(a['id'], b['id']);
      }).map(Abastecimento.deMapa).toList();

  @override
  Future<List<AjusteKm>> ajustes() async => _ordenado(tabelaAjustes, (a, b) {
        final c = _desc(a['quando'], b['quando']);
        return c != 0 ? c : _desc(a['id'], b['id']);
      }).map(AjusteKm.deMapa).toList();

  @override
  Future<List<Gasto>> gastos() async => _ordenado(tabelaGastos, (a, b) {
        final c = _desc(a['data'], b['data']);
        return c != 0 ? c : _desc(a['id'], b['id']);
      }).map(Gasto.deMapa).toList();

  @override
  Future<List<Vale>> vales() async => _ordenado(tabelaVales, (a, b) {
        final c = _desc(a['data'], b['data']);
        return c != 0 ? c : _desc(a['id'], b['id']);
      }).map(Vale.deMapa).toList();

  @override
  Future<int> inserir(String tabela, Map<String, Object?> dados) async {
    final id = ++_ultimoId;
    _tabelas[tabela]!.add({...dados, 'id': id});
    return id;
  }

  @override
  Future<void> atualizar(String tabela, int id, Map<String, Object?> dados) async {
    final l = _tabelas[tabela]!;
    final i = l.indexWhere((m) => m['id'] == id);
    if (i >= 0) l[i] = {...dados, 'id': id};
  }

  @override
  Future<void> apagar(String tabela, int id) async {
    _tabelas[tabela]!.removeWhere((m) => m['id'] == id);
  }

  @override
  Future<void> substituirTudo(Map<String, List<Map<String, Object?>>> tabelas) async {
    for (final t in todasAsTabelas) {
      _tabelas[t] = [];
      for (final l in tabelas[t] ?? const <Map<String, Object?>>[]) {
        final copia = Map<String, Object?>.from(l);
        final id = (copia['id'] as num?)?.toInt() ?? ++_ultimoId;
        if (id > _ultimoId) _ultimoId = id;
        copia['id'] = id;
        _tabelas[t]!.add(copia);
      }
    }
  }

  @override
  Future<void> renomearPlaca(String de, String para) async {
    for (final t in todasAsTabelas) {
      for (final m in _tabelas[t]!) {
        if ((m['placa'] ?? '') == de) m['placa'] = para;
      }
    }
  }
}
