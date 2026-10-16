import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../regras/resumo.dart';

/// Preferencias do motorista. As chaves sao as mesmas da versao 1.2.
class Configuracao extends ChangeNotifier {
  Configuracao(this._prefs);

  final SharedPreferences _prefs;

  static Future<Configuracao> carregar() async => Configuracao(await SharedPreferences.getInstance());

  static const _percentual = 'percentual_padrao';
  static const _freteCheio = 'frete_real_eh_valor_cheio';
  static const _gastosDescontam = 'gastos_descontam';
  static const _valeDesconta = 'vale_desconta';
  static const _comissaoBruto = 'comissao_sobre_bruto';
  static const _tema = 'tema';
  static const _configurado = 'configuracao_inicial_feita';
  static const _motorista = 'nome_motorista';
  static const _placa = 'placa_caminhao';
  static const _placas = 'placas_usadas';

  /// Nome do motorista (sai no relatorio).
  String get nomeMotorista => _prefs.getString(_motorista) ?? '';
  set nomeMotorista(String v) {
    _prefs.setString(_motorista, v.trim());
    notifyListeners();
  }

  /// Placa do caminhao em uso, sem traco (sai no relatorio).
  String get placaAtual => _prefs.getString(_placa) ?? '';
  set placaAtual(String v) {
    _prefs.setString(_placa, v);
    final lista = placasUsadas;
    if (v.isNotEmpty && !lista.contains(v)) _prefs.setStringList(_placas, [...lista, v]);
    notifyListeners();
  }

  /// Todos os caminhoes que o motorista ja usou no app.
  List<String> get placasUsadas => _prefs.getStringList(_placas) ?? const [];

  /// Troca a placa digitada errada (a antiga sai da lista).
  void corrigirPlaca(String antiga, String nova) {
    final lista = placasUsadas.where((p) => p != antiga && p != nova).toList()..add(nova);
    _prefs.setStringList(_placas, lista);
    if (placaAtual == antiga) _prefs.setString(_placa, nova);
    notifyListeners();
  }

  /// Nome e placa ja foram informados.
  bool get identificado => nomeMotorista.isNotEmpty && placaAtual.isNotEmpty;

  double get percentualPadrao => _prefs.getDouble(_percentual) ?? 13.0;
  set percentualPadrao(double v) {
    _prefs.setDouble(_percentual, v);
    notifyListeners();
  }

  bool get freteRealEhValorCheio => _prefs.getBool(_freteCheio) ?? true;
  set freteRealEhValorCheio(bool v) {
    _prefs.setBool(_freteCheio, v);
    notifyListeners();
  }

  bool get gastosDescontamDoLiquido => _prefs.getBool(_gastosDescontam) ?? false;
  set gastosDescontamDoLiquido(bool v) {
    _prefs.setBool(_gastosDescontam, v);
    notifyListeners();
  }

  bool get valeDescontaDoLiquido => _prefs.getBool(_valeDesconta) ?? true;
  set valeDescontaDoLiquido(bool v) {
    _prefs.setBool(_valeDesconta, v);
    notifyListeners();
  }

  bool get comissaoSobreBrutoPadrao => _prefs.getBool(_comissaoBruto) ?? false;
  set comissaoSobreBrutoPadrao(bool v) {
    _prefs.setBool(_comissaoBruto, v);
    notifyListeners();
  }

  ThemeMode get tema {
    switch (_prefs.getString(_tema)) {
      case 'claro':
        return ThemeMode.light;
      case 'escuro':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  set tema(ThemeMode m) {
    _prefs.setString(_tema, m == ThemeMode.light ? 'claro' : (m == ThemeMode.dark ? 'escuro' : 'sistema'));
    notifyListeners();
  }

  /// A configuracao guiada da primeira abertura ja foi feita.
  bool get configuracaoInicialFeita => _prefs.getBool(_configurado) ?? false;
  set configuracaoInicialFeita(bool v) {
    _prefs.setBool(_configurado, v);
    notifyListeners();
  }

  Regras get regras => Regras(
        freteRealEhValorCheio: freteRealEhValorCheio,
        gastosDescontamDoLiquido: gastosDescontamDoLiquido,
        valeDescontaDoLiquido: valeDescontaDoLiquido,
      );

  Map<String, Object?> paraMapa() => {
        _percentual: percentualPadrao,
        _freteCheio: freteRealEhValorCheio,
        _gastosDescontam: gastosDescontamDoLiquido,
        _valeDesconta: valeDescontaDoLiquido,
        _comissaoBruto: comissaoSobreBrutoPadrao,
        _motorista: nomeMotorista,
        _placa: placaAtual,
        _placas: placasUsadas,
      };

  void aplicarMapa(Map<String, Object?> m) {
    final p = m[_percentual];
    if (p is num) _prefs.setDouble(_percentual, p.toDouble());
    for (final chave in [_freteCheio, _gastosDescontam, _valeDesconta, _comissaoBruto]) {
      final v = m[chave];
      if (v is bool) _prefs.setBool(chave, v);
    }
    final nome = m[_motorista];
    if (nome is String && nome.isNotEmpty && nomeMotorista.isEmpty) _prefs.setString(_motorista, nome);
    final placas = m[_placas];
    if (placas is List) {
      final juntas = {...placasUsadas, ...placas.whereType<String>().where((p) => p.isNotEmpty)}.toList();
      _prefs.setStringList(_placas, juntas);
    }
    final placa = m[_placa];
    if (placa is String && placa.isNotEmpty && placaAtual.isEmpty) _prefs.setString(_placa, placa);
    _prefs.setBool(_configurado, true);
    notifyListeners();
  }
}
