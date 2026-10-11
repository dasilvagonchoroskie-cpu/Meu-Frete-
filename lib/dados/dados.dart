import 'package:flutter/foundation.dart';

import '../regras/dados_relatorio.dart';
import '../regras/periodo.dart';
import '../regras/resumo.dart';
import 'armazenamento.dart';
import 'modelos.dart';

/// Todos os registros do motorista, ja carregados na memoria.
class Dados extends ChangeNotifier {
  Dados(this._armazenamento);

  final Armazenamento _armazenamento;

  List<Frete> fretes = const [];
  List<Abastecimento> abastecimentos = const [];
  List<AjusteKm> ajustes = const [];
  List<Gasto> gastos = const [];
  List<Vale> vales = const [];
  bool carregado = false;

  Future<void> carregar() async {
    await _armazenamento.abrir();
    await _recarregar();
    carregado = true;
    notifyListeners();
  }

  Future<void> _recarregar() async {
    fretes = await _armazenamento.fretes();
    abastecimentos = await _armazenamento.abastecimentos();
    ajustes = await _armazenamento.ajustes();
    gastos = await _armazenamento.gastos();
    vales = await _armazenamento.vales();
  }

  Future<void> _salvar(String tabela, int id, Map<String, Object?> mapa) async {
    if (id == 0) {
      await _armazenamento.inserir(tabela, mapa);
    } else {
      await _armazenamento.atualizar(tabela, id, mapa);
    }
    await _recarregar();
    notifyListeners();
  }

  Future<void> _apagar(String tabela, int id) async {
    await _armazenamento.apagar(tabela, id);
    await _recarregar();
    notifyListeners();
  }

  Future<void> salvarFrete(Frete f) => _salvar(tabelaFretes, f.id, f.paraMapa());
  Future<void> apagarFrete(Frete f) => _apagar(tabelaFretes, f.id);

  Future<void> salvarAbastecimento(Abastecimento a) => _salvar(tabelaAbastecimentos, a.id, a.paraMapa());
  Future<void> apagarAbastecimento(Abastecimento a) => _apagar(tabelaAbastecimentos, a.id);

  Future<void> salvarGasto(Gasto g) => _salvar(tabelaGastos, g.id, g.paraMapa());
  Future<void> apagarGasto(Gasto g) => _apagar(tabelaGastos, g.id);

  Future<void> salvarVale(Vale v) => _salvar(tabelaVales, v.id, v.paraMapa());
  Future<void> apagarVale(Vale v) => _apagar(tabelaVales, v.id);

  /// Salva o ponto de partida e, se o km mudou, o registro da mudanca.
  Future<void> salvarPontoDePartida(Abastecimento ponto, AjusteKm? ajuste) async {
    if (ajuste != null) await _armazenamento.inserir(tabelaAjustes, ajuste.paraMapa());
    await _salvar(tabelaAbastecimentos, ponto.id, ponto.paraMapa());
  }

  Frete? freteComId(int id) {
    for (final f in fretes) {
      if (f.id == id) return f;
    }
    return null;
  }

  Abastecimento? get pontoDePartida {
    for (final a in abastecimentos) {
      if (a.pontoDePartida) return a;
    }
    return null;
  }

  /// Abastecidas de verdade (sem o ponto de partida).
  List<Abastecimento> get abastecidas => abastecimentos.where((a) => !a.pontoDePartida).toList();

  /// Categorias ja usadas nos gastos, em ordem alfabetica.
  List<String> get categoriasUsadas {
    final s = <String>{};
    for (final g in gastos) {
      final c = g.categoria.trim();
      if (c.isNotEmpty) s.add(c);
    }
    final l = s.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return l;
  }

  /// Cidades ja usadas (origem, destino, abastecida), para sugestao.
  List<String> get cidadesUsadas {
    final s = <String>{};
    for (final f in fretes) {
      if (f.origem.trim().isNotEmpty) s.add(f.origem.trim());
      if (f.destino.trim().isNotEmpty) s.add(f.destino.trim());
    }
    for (final a in abastecimentos) {
      if (a.cidade.trim().isNotEmpty) s.add(a.cidade.trim());
    }
    return s.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  List<String> get empresasUsadas {
    final s = <String>{};
    for (final f in fretes) {
      if (f.empresa.trim().isNotEmpty) s.add(f.empresa.trim());
    }
    return s.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  DadosRelatorio dadosDoPeriodo(Periodo periodo, Regras regras, {ConteudoRelatorio conteudo = ConteudoRelatorio.tudo}) =>
      montarDados(
        fretes: fretes,
        abastecimentos: abastecimentos,
        vales: vales,
        gastos: gastos,
        ajustes: ajustes,
        periodo: periodo,
        regras: regras,
        conteudo: conteudo,
      );

  DadosRelatorio dadosDaViagem(Frete frete, Regras regras) => montarDadosDaViagem(
        frete: frete,
        fretes: fretes,
        abastecimentos: abastecimentos,
        vales: vales,
        gastos: gastos,
        ajustes: ajustes,
        regras: regras,
      );

  /// Copia de tudo, para exportar.
  Map<String, List<Map<String, Object?>>> exportar() => {
        tabelaFretes: fretes.map((e) => {...e.paraMapa(), 'id': e.id}).toList(),
        tabelaAbastecimentos: abastecimentos.map((e) => {...e.paraMapa(), 'id': e.id}).toList(),
        tabelaAjustes: ajustes.map((e) => {...e.paraMapa(), 'id': e.id}).toList(),
        tabelaGastos: gastos.map((e) => {...e.paraMapa(), 'id': e.id}).toList(),
        tabelaVales: vales.map((e) => {...e.paraMapa(), 'id': e.id}).toList(),
      };

  Future<void> substituirTudo(Map<String, List<Map<String, Object?>>> tabelas) async {
    await _armazenamento.substituirTudo(tabelas);
    await _recarregar();
    notifyListeners();
  }

  int get totalDeRegistros => fretes.length + abastecimentos.length + gastos.length + vales.length;
}
