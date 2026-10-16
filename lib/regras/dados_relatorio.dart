import '../dados/modelos.dart';
import 'periodo.dart';
import 'resumo.dart';

enum ConteudoRelatorio {
  tudo('Tudo', 'completo'),
  fretes('Fretes', 'fretes'),
  diesel('Diesel', 'diesel'),
  gastos('Gastos', 'gastos'),
  vales('Vales', 'vales');

  const ConteudoRelatorio(this.rotulo, this.arquivo);
  final String rotulo;
  final String arquivo;
}

/// Tudo que entra num relatorio (ou no resumo de um periodo).
class DadosRelatorio {
  const DadosRelatorio({
    required this.periodo,
    required this.conteudo,
    required this.fretes,
    required this.abastecimentos,
    required this.abastecimentosCompletos,
    required this.vales,
    required this.gastos,
    required this.ajustes,
    required this.resultado,
    required this.regras,
    this.viagem = '',
    this.motorista = '',
    this.placa = '',
  });

  final Periodo periodo;
  final ConteudoRelatorio conteudo;
  final List<Frete> fretes;

  /// Abastecidas do periodo (sem o ponto de partida).
  final List<Abastecimento> abastecimentos;

  /// Todas as abastecidas (para a media de cada linha).
  final List<Abastecimento> abastecimentosCompletos;
  final List<Vale> vales;
  final List<Gasto> gastos;
  final List<AjusteKm> ajustes;
  final ResultadoResumo resultado;
  final Regras regras;

  /// "Uberlândia para Santos" quando e o acerto de uma viagem.
  final String viagem;

  /// Nome do motorista e placa do caminhao (saem no cabecalho do PDF).
  final String motorista;
  final String placa;

  bool get ehViagem => viagem.isNotEmpty;

  bool get vazio => fretes.isEmpty && abastecimentos.isEmpty && vales.isEmpty && gastos.isEmpty;
}

DadosRelatorio montarDados({
  required List<Frete> fretes,
  required List<Abastecimento> abastecimentos,
  required List<Vale> vales,
  required List<Gasto> gastos,
  required List<AjusteKm> ajustes,
  required Periodo periodo,
  required Regras regras,
  ConteudoRelatorio conteudo = ConteudoRelatorio.tudo,
  Frete? soEsteFrete,
  String motorista = '',
  String placa = '',
}) {
  final fretesP = soEsteFrete != null ? [soEsteFrete] : fretes.where((f) => periodo.contem(f.dataCarga)).toList();
  final abastP = abastecimentos.where((a) => !a.pontoDePartida && periodo.contem(a.data)).toList();
  final valesP = vales.where((v) => periodo.contem(v.data)).toList();
  final gastosP = gastos.where((g) => periodo.contem(g.data)).toList();
  final ajustesP = ajustes.where((a) => periodo.contem(a.quando)).toList();

  final resultado = calcularResumo(
    fretes: fretesP,
    abastecimentos: abastP.map((a) => a.valor).toList(),
    gastos: gastosP.map((g) => g.valor).toList(),
    vales: valesP.map((v) => v.valor).toList(),
    regras: regras,
  );

  return DadosRelatorio(
    periodo: periodo,
    conteudo: conteudo,
    fretes: fretesP,
    abastecimentos: abastP,
    abastecimentosCompletos: abastecimentos,
    vales: valesP,
    gastos: gastosP,
    ajustes: ajustesP,
    resultado: resultado,
    regras: regras,
    viagem: soEsteFrete?.rota ?? '',
    motorista: motorista,
    placa: placa,
  );
}

/// Acerto de uma viagem: o frete e o que foi lancado na janela dela.
DadosRelatorio montarDadosDaViagem({
  required Frete frete,
  required List<Frete> fretes,
  required List<Abastecimento> abastecimentos,
  required List<Vale> vales,
  required List<Gasto> gastos,
  required List<AjusteKm> ajustes,
  required Regras regras,
  DateTime? agora,
  String motorista = '',
  String placa = '',
}) {
  final janela = janelaDaViagem(frete.dataCarga, fretes.map((f) => f.dataCarga).toList(), agora: agora);
  return montarDados(
    fretes: fretes,
    abastecimentos: abastecimentos,
    vales: vales,
    gastos: gastos,
    ajustes: ajustes,
    periodo: janela,
    regras: regras,
    soEsteFrete: frete,
    motorista: motorista,
    placa: placa,
  );
}
