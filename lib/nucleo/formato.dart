// Formatacao no padrao brasileiro: 1.234,56 / dd/mm/aaaa.
// Feito a mao (sem depender de dados de localidade carregados).

const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho',
  'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];
const _mesesCurtos = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];
const _diasSemana = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

/// Sinal de menos tipografico (mais legivel que o hifen nas contas).
const menos = '−';

String _agrupar(String inteiro) {
  final b = StringBuffer();
  final n = inteiro.length;
  for (var i = 0; i < n; i++) {
    b.write(inteiro[i]);
    final faltam = n - i - 1;
    if (faltam > 0 && faltam % 3 == 0) b.write('.');
  }
  return b.toString();
}

/// Numero com [casas] decimais: 1234.5 -> "1.234,50".
String numeroBr(double valor, int casas) {
  var v = valor;
  if (v.isNaN || v.isInfinite) v = 0;
  final negativo = v < 0;
  final texto = v.abs().toStringAsFixed(casas);
  final partes = texto.split('.');
  var r = _agrupar(partes[0]);
  if (casas > 0) r = '$r,${partes[1]}';
  final ehZero = r.replaceAll(RegExp(r'[0.,]'), '').isEmpty;
  if (negativo && !ehZero) r = '-$r';
  return r;
}

String dinheiro(double v) => numeroBr(v, 2);

/// "R$ 1.234,56" ou "−R$ 1.234,56".
String reais(double v) {
  final texto = numeroBr(v.abs(), 2);
  final ehZero = texto == '0,00';
  return (v < 0 && !ehZero) ? '${menos}R\$ $texto' : 'R\$ $texto';
}

String umaCasa(double v) => numeroBr(v, 1);
String semCasas(double v) => numeroBr(v, 0);

/// Quilos para toneladas com 3 casas: 33040 -> "33,040".
String toneladas(double kg) => numeroBr(kg / 1000.0, 3);

/// 13 -> "13", 12.5 -> "12,5".
String percentualTexto(double p) {
  if (p == p.roundToDouble()) return p.round().toString();
  return umaCasa(p);
}

String _dois(int n) => n.toString().padLeft(2, '0');

DateTime _data(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

/// 12/10/2026
String dataTexto(int ms) {
  final d = _data(ms);
  return '${_dois(d.day)}/${_dois(d.month)}/${d.year}';
}

/// 12/10/2026 às 14:05
String dataHoraTexto(int ms) {
  final d = _data(ms);
  return '${dataTexto(ms)} às ${_dois(d.hour)}:${_dois(d.minute)}';
}

/// "12 out"
String diaMes(int ms) {
  final d = _data(ms);
  return '${d.day} ${_mesesCurtos[d.month - 1]}';
}

/// "qui"
String diaSemana(int ms) => _diasSemana[_data(ms).weekday - 1];

/// "outubro de 2026"
String mesAno(DateTime d) => '${_meses[d.month - 1]} de ${d.year}';

/// "Outubro de 2026"
String mesAnoTitulo(DateTime d) {
  final t = mesAno(d);
  return t[0].toUpperCase() + t.substring(1);
}

/// "1 frete" / "3 fretes"
String plural(int n, String um, String varios) => n == 1 ? '1 $um' : '$n $varios';

/// Inicio do dia (meia-noite) em milissegundos.
int inicioDoDia(DateTime d) => DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;

/// Ultimo milissegundo do dia.
int fimDoDia(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999).millisecondsSinceEpoch;

/// Hoje a meia-noite.
int hoje() => inicioDoDia(DateTime.now());
