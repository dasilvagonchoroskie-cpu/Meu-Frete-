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
      };

  void aplicarMapa(Map<String, Object?> m) {
    final p = m[_percentual];
    if (p is num) _prefs.setDouble(_percentual, p.toDouble());
    for (final chave in [_freteCheio, _gastosDescontam, _valeDesconta, _comissaoBruto]) {
      final v = m[chave];
      if (v is bool) _prefs.setBool(chave, v);
    }
    _prefs.setBool(_configurado, true);
    notifyListeners();
  }
}
