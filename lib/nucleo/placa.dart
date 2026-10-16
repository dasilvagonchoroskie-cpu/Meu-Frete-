import 'package:flutter/services.dart';

/// Placa guardada sem traco e em maiusculas: "ABC1D23" ou "ABC1234".
String normalizarPlaca(String texto) => texto.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// Placa brasileira: modelo antigo (ABC1234) ou Mercosul (ABC1D23).
bool placaValida(String texto) => RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$').hasMatch(normalizarPlaca(texto));

/// Para mostrar: "ABC-1234" no modelo antigo, "ABC1D23" no Mercosul.
String placaTexto(String placa) {
  final p = normalizarPlaca(placa);
  if (p.length == 7 && RegExp(r'^[A-Z]{3}[0-9]{4}$').hasMatch(p)) {
    return '${p.substring(0, 3)}-${p.substring(3)}';
  }
  return p;
}

/// Mascara do campo de placa: so letras e numeros, em maiusculas, ate 7.
class FormatadorPlaca extends TextInputFormatter {
  const FormatadorPlaca();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    var p = normalizarPlaca(novo.text);
    if (p.length > 7) p = p.substring(0, 7);
    final t = placaTexto(p);
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}
