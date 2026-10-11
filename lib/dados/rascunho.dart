import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Guarda o que esta sendo digitado num formulario. Se o celular fechar o
/// aplicativo no meio, nada se perde: na proxima vez o formulario volta
/// preenchido.
class Rascunho {
  Rascunho._(this._prefs, this._chave);

  final SharedPreferences _prefs;
  final String _chave;

  static Future<Rascunho> abrir(String nome) async =>
      Rascunho._(await SharedPreferences.getInstance(), 'rascunho_$nome');

  Map<String, Object?> ler() {
    final texto = _prefs.getString(_chave);
    if (texto == null || texto.isEmpty) return {};
    try {
      final m = jsonDecode(texto);
      return m is Map<String, dynamic> ? Map<String, Object?>.from(m) : {};
    } catch (_) {
      return {};
    }
  }

  void gravar(Map<String, Object?> campos) => _prefs.setString(_chave, jsonEncode(campos));

  void limpar() => _prefs.remove(_chave);
}
