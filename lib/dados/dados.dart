import 'package:flutter/foundation.dart';

import '../regras/dados_relatorio.dart';
import '../regras/periodo.dart';
import '../regras/resumo.dart';
import 'armazenamento.dart';
import 'modelos.dart';

/// Todos os registros do motorista, ja carregados na memoria.
///
/// Cada registro guarda a placa do caminhao em que foi feito. As telas e as
/// contas mostram so o caminhao em uso ([placaAtiva]): quando o motorista
/// troca de caminhao, comeca do zero no novo (inclusive a media do diesel,
/// que depende do km do painel) e o do caminhao anterior fica guardado.
class Dados extends ChangeNotifier {
  Dados(this._armazenamento, {String placa = ''}) : _placa = placa;

  final Armazenamento _armazenamento;
  String _placa;

  // Tudo, de todos os caminhoes.
  List<Frete> _fretes = const [];
  List<Abastecimento> _abastecimentos = const [];
  List<AjusteKm> _ajustes = const [];
  List<Gasto> _gastos = const [];
  List<Vale> _vales = const [];

  // So do caminhao em uso.
  List<Frete> fretes = const [];
  List<Abastecimento> abastecimentos = const [];
  List<AjusteKm> ajustes = const [];
  List<Gasto> gastos = const [];
  List<Vale> vales = const [];
  bool carregado = false;

  /// Placa do caminhao em uso (sem traco).
  String get placaAtiva => _placa;

  Future<void> carregar() async {
    await _armazenamento.abrir();
    await _recarregar();
    carregado = true;
    notifyListeners();
  }

  Future<void> _recarregar() async {
    _fretes = await _armazenamento.fretes();
    _abastecimentos = await _armazenamento.abastecimentos();
    _ajustes = await _armazenamento.ajustes();
    _gastos = await _armazenamento.gastos();
    _vales = await _armazenamento.vales();
    _filtrar();
  }

  void _filtrar() {
    final p = _placa;
    fretes = _fretes.where((e) => e.placa == p).toList();
    abastecimentos = _abastecimentos.where((e) => e.placa == p).toList();
    ajustes = _ajustes.where((e) => e.placa == p).toList();
    gastos = _gastos.where((e) => e.placa == p).toList();
    vales = _vales.where((e) => e.placa == p).toList();
  }

  /// Passa a mostrar o caminhao [placa].
  void usarPlaca(String placa) {
    if (placa == _placa) return;
    _placa = placa;
    _filtrar();
    notifyListeners();
  }

  /// Registros que ainda nao tinham caminhao (vindos da versao 2.0/2.1 ou de
  /// copia antiga) passam a ser do caminhao [placa].
  Future<void> marcarSemPlaca(String placa) async {
    if (placa.isEmpty) return;
    await _armazenamento.renomearPlaca('', placa);
    await _recarregar();
    notifyListeners();
  }

  /// Corrige a placa digitada errada: todos os registros de [de] vao para [para].
  Future<void> corrigirPlaca(String de, String para) async {
    if (de == para || para.isEmpty) return;
    await _armazenamento.renomearPlaca(de, para);
    if (_placa == de) _placa = para;
    await _recarregar();
    notifyListeners();
  }

  /// Placas que ja tem registro guardado.
  List<String> get placasComRegistro {
    final s = <String>{
      for (final e in _fretes) e.placa,
      for (final e in _abastecimentos) e.placa,
      for (final e in _gastos) e.placa,
      for (final e in _vales) e.placa,
    }..remove('');
    return s.toList()..sort();
  }

  /// Quantos registros o caminhao [placa] tem.
  int registrosDaPlaca(String placa) =>
      _fretes.where((e) => e.placa == placa).length +
      _abastecimentos.where((e) => e.placa == placa && !e.pontoDePartida).length +
      _gastos.where((e) => e.placa == placa).length +
      _vales.where((e) => e.placa == placa).length;

  Map<String, Object?> _comPlaca(Map<String, Object?> mapa) {
    final atual = mapa['placa'];
    if (atual is String && atual.isNotEmpty) return mapa;
    return {...mapa, 'placa': _placa};
  }

  Future<void> _salvar(String tabela, int id, Map<String, Object?> mapa) async {
    final comPlaca = _comPlaca(mapa);
    if (id == 0) {
      await _armazenamento.inserir(tabela, comPlaca);
    } else {
      await _armazenamento.atualizar(tabela, id, comPlaca);
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
    if (ajuste != null) await _armazenamento.inserir(tabelaAjustes, _comPlaca(ajuste.paraMapa()));
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

  /// Categorias ja usadas nos gastos (de todos os caminhoes), em ordem alfabetica.
  List<String> get categoriasUsadas {
    final s = <String>{};
    for (final g in _gastos) {
      final c = g.categoria.trim();
      if (c.isNotEmpty) s.add(c);
    }
    final l = s.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return l;
  }

  /// Cidades ja usadas (origem, destino, abastecida), para sugestao.
  List<String> get cidadesUsadas {
    final s = <String>{};
    for (final f in _fretes) {
      if (f.origem.trim().isNotEmpty) s.add(f.origem.trim());
      if (f.destino.trim().isNotEmpty) s.add(f.destino.trim());
    }
    for (final a in _abastecimentos) {
      if (a.cidade.trim().isNotEmpty) s.add(a.cidade.trim());
    }
    return s.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  List<String> get empresasUsadas {
    final s = <String>{};
    for (final f in _fretes) {
      if (f.empresa.trim().isNotEmpty) s.add(f.empresa.trim());
    }
    return s.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  DadosRelatorio dadosDoPeriodo(
    Periodo periodo,
    Regras regras, {
    ConteudoRelatorio conteudo = ConteudoRelatorio.tudo,
    String motorista = '',
  }) =>
      montarDados(
        fretes: fretes,
        abastecimentos: abastecimentos,
        vales: vales,
        gastos: gastos,
        ajustes: ajustes,
        periodo: periodo,
        regras: regras,
        conteudo: conteudo,
        motorista: motorista,
        placa: _placa,
      );

  DadosRelatorio dadosDaViagem(Frete frete, Regras regras, {String motorista = ''}) => montarDadosDaViagem(
        frete: frete,
        fretes: fretes,
        abastecimentos: abastecimentos,
        vales: vales,
        gastos: gastos,
        ajustes: ajustes,
        regras: regras,
        motorista: motorista,
        placa: frete.placa.isNotEmpty ? frete.placa : _placa,
      );

  /// Copia de tudo (todos os caminhoes), para exportar.
  Map<String, List<Map<String, Object?>>> exportar() => {
        tabelaFretes: _fretes.map((e) => {...e.paraMapa(), 'id': e.id}).toList(),
        tabelaAbastecimentos: _abastecimentos.map((e) => {...e.paraMapa(), 'id': e.id}).toList(),
        tabelaAjustes: _ajustes.map((e) => {...e.paraMapa(), 'id': e.id}).toList(),
        tabelaGastos: _gastos.map((e) => {...e.paraMapa(), 'id': e.id}).toList(),
        tabelaVales: _vales.map((e) => {...e.paraMapa(), 'id': e.id}).toList(),
      };

  Future<void> substituirTudo(Map<String, List<Map<String, Object?>>> tabelas) async {
    await _armazenamento.substituirTudo(tabelas);
    if (_placa.isNotEmpty) await _armazenamento.renomearPlaca('', _placa);
    await _recarregar();
    notifyListeners();
  }

  /// Registros guardados no celular (todos os caminhoes).
  int get totalDeRegistros => _fretes.length + _abastecimentos.length + _gastos.length + _vales.length;
}
