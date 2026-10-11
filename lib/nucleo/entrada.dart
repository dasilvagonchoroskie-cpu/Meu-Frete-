import 'package:flutter/services.dart';

import 'formato.dart';

/// Le o que foi digitado num campo de numero.
/// Aceita "1.234,56", "33.040", "350,5", "13", "12.5" e "R$ 10,00".
double lerNumero(String texto) {
  var t = texto.trim().replaceAll('R\$', '').replaceAll(' ', '').replaceAll(' ', '');
  if (t.isEmpty) return 0;
  if (t.contains(',')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  } else if (t.contains('.')) {
    final partes = t.split('.');
    final ehMilhar = partes.length > 1 && partes.skip(1).every((p) => p.length == 3);
    if (ehMilhar) {
      t = partes.join();
    } else if (partes.length > 2) {
      // varios pontos sem grupos de 3: fica so o ultimo como decimal
      t = '${partes.sublist(0, partes.length - 1).join()}.${partes.last}';
    }
  }
  return double.tryParse(t) ?? 0;
}

String _soDigitos(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

TextEditingValue _comCursoNoFim(String texto) => TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );

/// Dinheiro digitado da direita para a esquerda, como em app de banco:
/// 1 -> 0,01 / 1550 -> 15,50 / 123456 -> 1.234,56
class FormatadorDinheiro extends TextInputFormatter {
  const FormatadorDinheiro();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    var digitos = _soDigitos(novo.text);
    if (digitos.length > 11) digitos = digitos.substring(0, 11);
    digitos = digitos.replaceFirst(RegExp(r'^0+'), '');
    if (digitos.isEmpty) return _comCursoNoFim('');
    final centavos = int.parse(digitos);
    return _comCursoNoFim(dinheiro(centavos / 100.0));
  }
}

/// Numero inteiro com ponto de milhar: 33040 -> 33.040
class FormatadorInteiro extends TextInputFormatter {
  const FormatadorInteiro({this.maxDigitos = 9});
  final int maxDigitos;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    var digitos = _soDigitos(novo.text);
    if (digitos.length > maxDigitos) digitos = digitos.substring(0, maxDigitos);
    digitos = digitos.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digitos.isEmpty) return _comCursoNoFim('');
    return _comCursoNoFim(semCasas(double.parse(digitos)));
  }
}

/// Numero com virgula decimal livre: 350,5 / 12,5. Ponto vira virgula.
class FormatadorDecimal extends TextInputFormatter {
  const FormatadorDecimal({this.casas = 2, this.maxInteiros = 6});
  final int casas;
  final int maxInteiros;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    var t = novo.text.replaceAll('.', ',').replaceAll(RegExp(r'[^0-9,]'), '');
    final i = t.indexOf(',');
    String inteiro;
    String? fracao;
    if (i >= 0) {
      inteiro = t.substring(0, i);
      fracao = t.substring(i + 1).replaceAll(',', '');
      if (fracao.length > casas) fracao = fracao.substring(0, casas);
      if (inteiro.isEmpty) inteiro = '0';
    } else {
      inteiro = t;
    }
    if (inteiro.length > maxInteiros) inteiro = inteiro.substring(0, maxInteiros);
    if (inteiro.length > 1) inteiro = inteiro.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final r = fracao == null ? inteiro : '$inteiro,$fracao';
    return _comCursoNoFim(r);
  }
}

/// Texto para colocar num campo de dinheiro ja preenchido.
String textoDinheiro(double v) => v > 0 ? dinheiro(v) : '';

/// Texto para campo inteiro (kg, km).
String textoInteiro(double v) => v > 0 ? semCasas(v) : '';

/// Texto para campo decimal livre: 350.5 -> "350,5", 13.0 -> "13".
String textoDecimal(double v, {int casas = 2}) {
  if (v <= 0) return '';
  var t = v.toStringAsFixed(casas);
  if (t.contains('.')) {
    t = t.replaceFirst(RegExp(r'0+$'), '');
    t = t.replaceFirst(RegExp(r'\.$'), '');
  }
  return t.replaceAll('.', ',');
}
