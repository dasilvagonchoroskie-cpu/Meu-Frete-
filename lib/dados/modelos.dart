// Registros do aplicativo. As contas de cada frete ficam aqui, iguais as da
// versao 1.2 (Kotlin), para o motorista ver o mesmo numero de antes.

double _d(Object? v) => v == null ? 0.0 : (v as num).toDouble();
int _i(Object? v) => v == null ? 0 : (v as num).toInt();
String _s(Object? v) => v == null ? '' : v.toString();
bool _b(Object? v, {bool padrao = false}) {
  if (v == null) return padrao;
  if (v is bool) return v;
  return (v as num) != 0;
}

class Frete {
  const Frete({
    this.id = 0,
    required this.origem,
    required this.destino,
    this.empresa = '',
    required this.dataCarga,
    this.pesoKg = 0,
    this.valorTonelada = 0,
    this.adiantamento = 0,
    this.saldo = 0,
    this.percentualComissao = 13,
    this.pedagio = 0,
    this.comissaoSobreBruto = true,
    this.pesoDescargaKg = 0,
    this.descontoQuebra = 0,
  });

  final int id;
  final String origem;
  final String destino;
  final String empresa;
  final int dataCarga;
  final double pesoKg;
  final double valorTonelada;
  final double adiantamento;
  final double saldo;
  final double percentualComissao;
  final double pedagio;
  final bool comissaoSobreBruto;
  final double pesoDescargaKg;
  final double descontoQuebra;

  /// O que caiu na conta: adiantamento + saldo.
  double get freteReal => adiantamento + saldo;

  /// Peso x valor da tonelada (carta frete).
  double get valorContratado => (pesoKg / 1000.0) * valorTonelada;

  /// Sobre o que a comissao e calculada.
  double get baseComissao {
    if (comissaoSobreBruto) {
      final peso = pesoDescargaKg > 0 ? pesoDescargaKg : pesoKg;
      return (peso / 1000.0) * valorTonelada;
    }
    return freteReal;
  }

  /// A parte do motorista neste frete.
  double get minhaParte => baseComissao * (percentualComissao / 100.0);

  /// Quilos que faltaram na descarga (null se nao teve quebra).
  double? get quebraKg {
    if (pesoDescargaKg <= 0 || pesoKg <= 0) return null;
    final q = pesoKg - pesoDescargaKg;
    return q > 0 ? q : null;
  }

  /// Quanto a quebra vale pelo preco da tonelada.
  double get valorQuebraIntegral {
    final q = quebraKg;
    return q == null ? 0 : (q / 1000.0) * valorTonelada;
  }

  double get freteSemQuebra => adiantamento + saldo + descontoQuebra;

  /// Ainda falta cair o saldo.
  bool get aguardandoSaldo => saldo <= 0;

  /// Diferenca entre o que entrou e o contratado (negativo = desconto).
  double get diferencaDoContratado => freteReal - valorContratado;

  String get rota => '$origem para $destino';

  Frete copyWith({int? id}) => Frete(
        id: id ?? this.id,
        origem: origem,
        destino: destino,
        empresa: empresa,
        dataCarga: dataCarga,
        pesoKg: pesoKg,
        valorTonelada: valorTonelada,
        adiantamento: adiantamento,
        saldo: saldo,
        percentualComissao: percentualComissao,
        pedagio: pedagio,
        comissaoSobreBruto: comissaoSobreBruto,
        pesoDescargaKg: pesoDescargaKg,
        descontoQuebra: descontoQuebra,
      );

  Map<String, Object?> paraMapa() => {
        if (id != 0) 'id': id,
        'origem': origem,
        'destino': destino,
        'empresa': empresa,
        'dataCarga': dataCarga,
        'pesoKg': pesoKg,
        'valorTonelada': valorTonelada,
        'adiantamento': adiantamento,
        'saldo': saldo,
        'percentualComissao': percentualComissao,
        'pedagio': pedagio,
        'comissaoSobreBruto': comissaoSobreBruto ? 1 : 0,
        'pesoDescargaKg': pesoDescargaKg,
        'descontoQuebra': descontoQuebra,
      };

  factory Frete.deMapa(Map<String, Object?> m) => Frete(
        id: _i(m['id']),
        origem: _s(m['origem']),
        destino: _s(m['destino']),
        empresa: _s(m['empresa']),
        dataCarga: _i(m['dataCarga']),
        pesoKg: _d(m['pesoKg']),
        valorTonelada: _d(m['valorTonelada']),
        adiantamento: _d(m['adiantamento']),
        saldo: _d(m['saldo']),
        percentualComissao: m['percentualComissao'] == null ? 13 : _d(m['percentualComissao']),
        pedagio: _d(m['pedagio']),
        comissaoSobreBruto: _b(m['comissaoSobreBruto'], padrao: true),
        pesoDescargaKg: _d(m['pesoDescargaKg']),
        descontoQuebra: _d(m['descontoQuebra']),
      );
}

class Abastecimento {
  const Abastecimento({
    this.id = 0,
    required this.data,
    this.cidade = '',
    this.posto = '',
    this.litros = 0,
    this.valor = 0,
    required this.km,
    this.tanqueCheio = true,
    this.pontoDePartida = false,
  });

  final int id;
  final int data;
  final String cidade;
  final String posto;
  final double litros;
  final double valor;
  final double km;
  final bool tanqueCheio;

  /// Km anotado da planilha antiga, so para a media comecar certa.
  final bool pontoDePartida;

  double get precoLitro => litros > 0 ? valor / litros : 0;

  Abastecimento copyWith({int? id}) => Abastecimento(
        id: id ?? this.id,
        data: data,
        cidade: cidade,
        posto: posto,
        litros: litros,
        valor: valor,
        km: km,
        tanqueCheio: tanqueCheio,
        pontoDePartida: pontoDePartida,
      );

  Map<String, Object?> paraMapa() => {
        if (id != 0) 'id': id,
        'data': data,
        'cidade': cidade,
        'posto': posto,
        'litros': litros,
        'valor': valor,
        'km': km,
        'tanqueCheio': tanqueCheio ? 1 : 0,
        'pontoDePartida': pontoDePartida ? 1 : 0,
      };

  factory Abastecimento.deMapa(Map<String, Object?> m) => Abastecimento(
        id: _i(m['id']),
        data: _i(m['data']),
        cidade: _s(m['cidade']),
        posto: _s(m['posto']),
        litros: _d(m['litros']),
        valor: _d(m['valor']),
        km: _d(m['km']),
        tanqueCheio: _b(m['tanqueCheio'], padrao: true),
        pontoDePartida: _b(m['pontoDePartida']),
      );
}

/// Registro de cada mudanca do km inicial (sai no pe do relatorio).
class AjusteKm {
  const AjusteKm({
    this.id = 0,
    required this.quando,
    required this.kmAnterior,
    required this.kmNovo,
    required this.motivo,
  });

  final int id;
  final int quando;
  final double kmAnterior;
  final double kmNovo;
  final String motivo;

  Map<String, Object?> paraMapa() => {
        if (id != 0) 'id': id,
        'quando': quando,
        'kmAnterior': kmAnterior,
        'kmNovo': kmNovo,
        'motivo': motivo,
      };

  factory AjusteKm.deMapa(Map<String, Object?> m) => AjusteKm(
        id: _i(m['id']),
        quando: _i(m['quando']),
        kmAnterior: _d(m['kmAnterior']),
        kmNovo: _d(m['kmNovo']),
        motivo: _s(m['motivo']),
      );
}

class Gasto {
  const Gasto({this.id = 0, required this.data, required this.valor, required this.categoria});

  final int id;
  final int data;
  final double valor;
  final String categoria;

  Gasto copyWith({int? id}) => Gasto(id: id ?? this.id, data: data, valor: valor, categoria: categoria);

  Map<String, Object?> paraMapa() => {
        if (id != 0) 'id': id,
        'data': data,
        'valor': valor,
        'categoria': categoria,
      };

  factory Gasto.deMapa(Map<String, Object?> m) => Gasto(
        id: _i(m['id']),
        data: _i(m['data']),
        valor: _d(m['valor']),
        categoria: _s(m['categoria']),
      );
}

/// Dinheiro que o motorista pegou adiantado.
class Vale {
  const Vale({this.id = 0, required this.data, required this.valor});

  final int id;
  final int data;
  final double valor;

  Vale copyWith({int? id}) => Vale(id: id ?? this.id, data: data, valor: valor);

  Map<String, Object?> paraMapa() => {
        if (id != 0) 'id': id,
        'data': data,
        'valor': valor,
      };

  factory Vale.deMapa(Map<String, Object?> m) => Vale(
        id: _i(m['id']),
        data: _i(m['data']),
        valor: _d(m['valor']),
      );
}
