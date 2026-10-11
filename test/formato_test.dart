import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_frete/nucleo/entrada.dart';
import 'package:meu_frete/nucleo/formato.dart';

String digitar(TextInputFormatter f, String texto) =>
    f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: texto)).text;

void main() {
  test('dinheiro no padrao brasileiro', () {
    expect(dinheiro(1234.5), '1.234,50');
    expect(dinheiro(0), '0,00');
    expect(dinheiro(1234567.891), '1.234.567,89');
    expect(reais(-12), '−R\$ 12,00');
    expect(reais(-0.001), 'R\$ 0,00');
    expect(semCasas(412300), '412.300');
    expect(toneladas(33040), '33,040');
    expect(percentualTexto(13), '13');
    expect(percentualTexto(12.5), '12,5');
  });

  test('datas', () {
    final ms = DateTime(2026, 10, 9, 14, 5).millisecondsSinceEpoch;
    expect(dataTexto(ms), '09/10/2026');
    expect(dataHoraTexto(ms), '09/10/2026 às 14:05');
    expect(mesAno(DateTime(2026, 3)), 'março de 2026');
    expect(plural(1, 'frete', 'fretes'), '1 frete');
    expect(plural(3, 'frete', 'fretes'), '3 fretes');
  });

  test('ler o que foi digitado', () {
    expect(lerNumero('1.234,56'), 1234.56);
    expect(lerNumero('33.040'), 33040);
    expect(lerNumero('350,5'), 350.5);
    expect(lerNumero('12.5'), 12.5);
    expect(lerNumero('R\$ 10,00'), 10);
    expect(lerNumero(''), 0);
    expect(lerNumero('abc'), 0);
  });

  test('mascaras', () {
    expect(digitar(const FormatadorDinheiro(), '1550'), '15,50');
    expect(digitar(const FormatadorDinheiro(), '123456'), '1.234,56');
    expect(digitar(const FormatadorDinheiro(), '0'), '');
    expect(digitar(const FormatadorInteiro(), '33040'), '33.040');
    expect(digitar(const FormatadorDecimal(), '350.567'), '350,56');
    expect(digitar(const FormatadorDecimal(casas: 3), '12,3456'), '12,345');
    expect(digitar(const FormatadorDecimal(), ',5'), '0,5');
    expect(textoDecimal(13), '13');
    expect(textoDecimal(350.5, casas: 3), '350,5');
    expect(textoDinheiro(0), '');
    expect(lerNumero(digitar(const FormatadorDinheiro(), '987654')), 9876.54);
  });
}
