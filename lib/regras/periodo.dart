import '../nucleo/formato.dart';

/// Intervalo de datas, com as duas pontas incluidas (em milissegundos).
class Periodo {
  const Periodo(this.inicio, this.fim);
  final int inicio;
  final int fim;

  bool contem(int ms) => ms >= inicio && ms <= fim;

  String get texto => '${dataTexto(inicio)} a ${dataTexto(fim)}';

  @override
  bool operator ==(Object other) => other is Periodo && other.inicio == inicio && other.fim == fim;

  @override
  int get hashCode => Object.hash(inicio, fim);
}

enum TipoPeriodo {
  mesAtual('Este mês'),
  mesPassado('Mês passado'),
  seteDias('7 dias'),
  quinzeDias('15 dias'),
  trintaDias('30 dias'),
  escolher('Escolher datas');

  const TipoPeriodo(this.rotulo);
  final String rotulo;
}

/// Mesma regra da versao 1.2 (PeriodoRelatorio.kt).
Periodo? calcularPeriodo(TipoPeriodo tipo, {DateTime? inicio, DateTime? fim, DateTime? agora}) {
  final hoje = agora ?? DateTime.now();
  switch (tipo) {
    case TipoPeriodo.escolher:
      if (inicio == null || fim == null) return null;
      final a = inicioDoDia(inicio);
      final b = fimDoDia(fim);
      if (b < a) return null;
      return Periodo(a, b);
    case TipoPeriodo.seteDias:
    case TipoPeriodo.quinzeDias:
    case TipoPeriodo.trintaDias:
      final voltar = tipo == TipoPeriodo.seteDias ? 6 : (tipo == TipoPeriodo.quinzeDias ? 14 : 29);
      final comeco = DateTime(hoje.year, hoje.month, hoje.day - voltar);
      return Periodo(inicioDoDia(comeco), fimDoDia(hoje));
    case TipoPeriodo.mesAtual:
      final primeiro = DateTime(hoje.year, hoje.month, 1);
      final ultimo = DateTime(hoje.year, hoje.month + 1, 0);
      return Periodo(inicioDoDia(primeiro), fimDoDia(ultimo));
    case TipoPeriodo.mesPassado:
      final primeiro = DateTime(hoje.year, hoje.month - 1, 1);
      final ultimo = DateTime(hoje.year, hoje.month, 0);
      return Periodo(inicioDoDia(primeiro), fimDoDia(ultimo));
  }
}

/// Janela de uma viagem: da carga ate o dia em que a carga seguinte foi
/// pega (esse dia incluido). Se ja havia carga antes, comeca no dia seguinte
/// ao desta carga, porque o proprio dia ficou na conta da viagem anterior.
Periodo janelaDaViagem(int dataCarga, List<int> datasDeTodasAsCargas, {DateTime? agora}) {
  int? anterior;
  int? proxima;
  for (final d in datasDeTodasAsCargas) {
    if (d < dataCarga && (anterior == null || d > anterior)) anterior = d;
    if (d > dataCarga && (proxima == null || d < proxima)) proxima = d;
  }
  final carga = DateTime.fromMillisecondsSinceEpoch(dataCarga);
  final comeco = anterior != null ? DateTime(carga.year, carga.month, carga.day + 1) : carga;
  final fim = proxima != null
      ? fimDoDia(DateTime.fromMillisecondsSinceEpoch(proxima))
      : fimDoDia(agora ?? DateTime.now());
  return Periodo(inicioDoDia(comeco), fim);
}
