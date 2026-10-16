import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../dados/modelos.dart';
import '../nucleo/formato.dart';
import '../nucleo/placa.dart';
import '../regras/dados_relatorio.dart';
import '../regras/media_diesel.dart';
import '../regras/resumo.dart';

/// Letras embutidas no PDF (acentos e simbolos saem certos em qualquer celular).
class FontesPdf {
  const FontesPdf(this.normal, this.negrito, this.numero, this.numeroNegrito);
  final pw.Font normal;
  final pw.Font negrito;
  final pw.Font numero;
  final pw.Font numeroNegrito;

  static Future<FontesPdf> carregar() async {
    Future<pw.Font> f(String nome) async => pw.Font.ttf(await rootBundle.load('assets/fonts/$nome'));
    return FontesPdf(
      await f('Barlow-Regular.ttf'),
      await f('Barlow-SemiBold.ttf'),
      await f('BarlowSemiCondensed-SemiBold.ttf'),
      await f('BarlowSemiCondensed-Bold.ttf'),
    );
  }
}

const _tintaEscura = PdfColor.fromInt(0xFF1E2427);
const _tintaCinza = PdfColor.fromInt(0xFF5B6560);
const _tintaVerde = PdfColor.fromInt(0xFF0A7343);
const _tintaLaranja = PdfColor.fromInt(0xFF9A6200);
const _tintaVermelha = PdfColor.fromInt(0xFFB22A2A);
const _fundoCaixa = PdfColor.fromInt(0xFFF0F2EE);
const _fundoVerde = PdfColor.fromInt(0xFFE6F4EC);
const _fundoAmarelo = PdfColor.fromInt(0xFFFFF6DC);
const _fundoVermelho = PdfColor.fromInt(0xFFFDEDED);
const _verdePlaca = PdfColor.fromInt(0xFF0B5D3B);

String nomeDoArquivoPdf(DadosRelatorio d) {
  final inicio = dataTexto(d.periodo.inicio).replaceAll('/', '-');
  final placa = d.placa.isEmpty ? '' : '${normalizarPlaca(d.placa)}_';
  if (d.ehViagem) {
    var v = d.viagem.replaceAll(' para ', '-');
    v = _semAcento(v).replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '');
    if (v.length > 40) v = v.substring(0, 40);
    return 'MeuFrete_${placa}viagem_${v}_$inicio.pdf';
  }
  final fim = dataTexto(d.periodo.fim).replaceAll('/', '-');
  return 'MeuFrete_$placa${d.conteudo.arquivo}_${inicio}_a_$fim.pdf';
}

String _semAcento(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  const para = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    final i = de.indexOf(c);
    b.write(i >= 0 ? para[i] : c);
  }
  return b.toString();
}

class _Pdf {
  _Pdf(this.f);
  final FontesPdf f;

  pw.TextStyle t(double tamanho, {PdfColor cor = _tintaEscura, bool negrito = false, bool numero = false}) =>
      pw.TextStyle(
        font: numero ? (negrito ? f.numeroNegrito : f.numero) : (negrito ? f.negrito : f.normal),
        fontSize: tamanho,
        color: cor,
        lineSpacing: 1.5,
      );

  pw.Widget titulo(String texto) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 18, bottom: 8),
        padding: const pw.EdgeInsets.only(bottom: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _tintaCinza, width: 0.8)),
        ),
        child: pw.Text(texto, style: t(14, negrito: true)),
      );

  pw.Widget valor(String rotulo, String v, {PdfColor cor = _tintaEscura}) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 5, bottom: 1),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(child: pw.Text(rotulo, style: t(12))),
            pw.Text(v, style: t(14, negrito: true, numero: true, cor: cor)),
          ],
        ),
      );

  pw.Widget nota(String texto, {PdfColor cor = _tintaCinza, double recuo = 0, double tamanho = 9.5, double abaixo = 4}) =>
      pw.Padding(
        padding: pw.EdgeInsets.only(left: recuo, bottom: abaixo),
        child: pw.Text(texto, style: t(tamanho, cor: cor)),
      );

  pw.Widget item(String texto, String v) => pw.Padding(
        padding: const pw.EdgeInsets.only(left: 12, top: 1, bottom: 1),
        child: pw.Row(children: [
          pw.Expanded(child: pw.Text(texto, style: t(9.5, cor: _tintaCinza))),
          pw.Text(v, style: t(10, cor: _tintaCinza, numero: true)),
        ]),
      );

  pw.Widget bloco(String rotulo, String v, String detalhe,
          {PdfColor cor = _tintaVerde, PdfColor fundo = _fundoVerde}) =>
      pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(top: 8, bottom: 8),
        padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: pw.BoxDecoration(
          color: fundo,
          border: pw.Border.all(color: cor, width: 1.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(rotulo, style: t(10.5, cor: cor, negrito: true)),
            pw.SizedBox(height: 2),
            pw.Text(v, style: t(24, negrito: true, numero: true)),
            if (detalhe.isNotEmpty) pw.Text(detalhe, style: t(10, cor: _tintaCinza, numero: true)),
          ],
        ),
      );
}

/// Monta o PDF do relatorio (ou do acerto de uma viagem).
Future<Uint8List> gerarPdf(DadosRelatorio d, FontesPdf fontes, {DateTime? agora}) async {
  final p = _Pdf(fontes);
  final doc = pw.Document(title: 'Meu Frete', author: 'Meu Frete');
  final conteudo = <pw.Widget>[];

  conteudo.addAll(_cabecalho(p, d, agora ?? DateTime.now()));
  switch (d.conteudo) {
    case ConteudoRelatorio.tudo:
      conteudo.addAll(_resumo(p, d));
      conteudo.addAll(_fretes(p, d.fretes));
      conteudo.addAll(_abastecimentos(p, d.abastecimentos, d.abastecimentosCompletos));
      conteudo.addAll(_vales(p, d.vales, d.resultado.totalVale));
      conteudo.addAll(_gastos(p, d.gastos, d.resultado.totalGastos));
    case ConteudoRelatorio.diesel:
      conteudo.addAll(_abastecimentos(p, d.abastecimentos, d.abastecimentosCompletos));
      conteudo.addAll(_fechoDiesel(p, d));
    case ConteudoRelatorio.fretes:
      conteudo.addAll(_fretes(p, d.fretes));
      conteudo.addAll(_fechoFretes(p, d.resultado));
    case ConteudoRelatorio.vales:
      conteudo.addAll(_vales(p, d.vales, d.resultado.totalVale));
    case ConteudoRelatorio.gastos:
      conteudo.addAll(_gastos(p, d.gastos, d.resultado.totalGastos));
      conteudo.addAll(_fechoGastos(p, d));
  }
  conteudo.addAll(_ajustes(p, d.ajustes));

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
      theme: pw.ThemeData.withFont(base: fontes.normal, bold: fontes.negrito),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Text('Meu Frete  |  página ${ctx.pageNumber} de ${ctx.pagesCount}', style: p.t(8.5, cor: _tintaCinza)),
      ),
      build: (ctx) => conteudo,
    ),
  );
  return doc.save();
}

List<pw.Widget> _cabecalho(_Pdf p, DadosRelatorio d, DateTime agora) {
  final String subtitulo;
  if (d.ehViagem) {
    subtitulo = 'Acerto da viagem: ${d.viagem}';
  } else {
    switch (d.conteudo) {
      case ConteudoRelatorio.tudo:
        subtitulo = 'Relatório de fretes, diesel, vales e gastos';
      case ConteudoRelatorio.diesel:
        subtitulo = 'Relatório de diesel';
      case ConteudoRelatorio.fretes:
        subtitulo = 'Relatório de fretes';
      case ConteudoRelatorio.vales:
        subtitulo = 'Relatório de vales';
      case ConteudoRelatorio.gastos:
        subtitulo = 'Relatório de gastos';
    }
  }
  return [
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(2),
          decoration: const pw.BoxDecoration(
            color: _verdePlaca,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(8, 3, 8, 3),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.white, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text('Meu Frete', style: p.t(17, cor: PdfColors.white, negrito: true, numero: true)),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(child: pw.Text(subtitulo, style: p.t(12.5, cor: _tintaCinza))),
      ],
    ),
    pw.SizedBox(height: 10),
    if (d.ehViagem)
      p.nota(
        'Entram nesta conta os gastos, abastecidas e vales lançados entre a data desta carga e o dia em que a '
        'carga seguinte foi pega, com esse último dia incluído, porque o que se gasta nele (pedágio e diesel '
        'rodando até o próximo carregamento) é custo de fechar esta viagem. Confira as datas abaixo: gasto lançado '
        'com data errada aparece na viagem errada.',
        tamanho: 8.5,
        abaixo: 8,
      ),
    pw.Container(
      width: double.infinity,
      color: _fundoCaixa,
      padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 5,
            child: _campoCaixa(p, 'Período', '${dataTexto(d.periodo.inicio)}  a  ${dataTexto(d.periodo.fim)}'),
          ),
          if (d.placa.isNotEmpty) pw.Expanded(flex: 3, child: _campoCaixa(p, 'Caminhão', placaTexto(d.placa))),
          if (d.motorista.isNotEmpty) pw.Expanded(flex: 5, child: _campoCaixa(p, 'Motorista', d.motorista)),
        ],
      ),
    ),
    pw.SizedBox(height: 4),
    p.nota('Gerado em ${dataHoraTexto(agora.millisecondsSinceEpoch)}', tamanho: 9),
  ];
}

pw.Widget _campoCaixa(_Pdf p, String rotulo, String valor) => pw.Padding(
      padding: const pw.EdgeInsets.only(right: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(rotulo, style: p.t(9.5, cor: _tintaCinza, negrito: true)),
          pw.Text(valor, style: p.t(14, negrito: true, numero: true)),
        ],
      ),
    );

List<pw.Widget> _resumo(_Pdf p, DadosRelatorio d) {
  final r = d.resultado;
  final regras = d.regras;
  final w = <pw.Widget>[p.titulo('Resumo do período')];
  w.add(p.valor('Total de fretes', reais(r.totalFretes)));
  w.add(p.nota(
    plural(r.quantidadeFretes, 'frete', 'fretes') +
        (r.totalPedagio > 0 ? '   |   pedágio ${reais(r.totalPedagio)} (cartão/tag, fora do frete)' : ''),
    recuo: 8,
  ));
  w.add(p.valor(regras.freteRealEhValorCheio ? 'Comissão (a parte do motorista)' : 'Parte do motorista', reais(r.comissao)));
  final String linhaComissao;
  if (!regras.freteRealEhValorCheio) {
    linhaComissao = 'Valor já lançado como a parte do motorista';
  } else if (r.percentuaisDiferentes) {
    linhaComissao = 'Percentuais diferentes entre os fretes. Na média deu ${percentualTexto(r.percentualMedio)}% '
        'sobre ${reais(r.totalBaseComissao)}';
  } else {
    linhaComissao = '${percentualTexto(r.percentualMedio)}% sobre ${reais(r.totalBaseComissao)}';
  }
  w.add(p.nota(linhaComissao, recuo: 8, cor: r.percentuaisDiferentes ? _tintaLaranja : _tintaCinza));
  w.add(p.valor('Total gasto', reais(r.totalGastoGeral)));
  w.add(p.nota('Diesel ${reais(r.totalAbastecimento)}   |   Outros gastos ${reais(r.totalGastos)}', recuo: 8, abaixo: 1));
  w.add(p.nota(
    regras.gastosDescontamDoLiquido
        ? 'Pago pelo motorista. Desconta do líquido.'
        : 'Pago pela empresa. Não desconta do líquido do motorista.',
    recuo: 8,
  ));
  w.add(p.valor('Total de vale', reais(r.totalVale)));
  w.add(p.nota(
    regras.valeDescontaDoLiquido ? 'Já adiantado ao motorista. Desconta do líquido.' : 'Só histórico. Não desconta do líquido.',
    recuo: 8,
  ));
  final conta = StringBuffer('Comissão ${reais(r.comissao)}');
  if (regras.gastosDescontamDoLiquido) conta.write('  menos gastos ${reais(r.totalGastoGeral)}');
  if (regras.valeDescontaDoLiquido) conta.write('  menos vale ${reais(r.totalVale)}');
  w.add(p.bloco('VALOR LÍQUIDO A RECEBER', reais(r.liquido), conta.toString(),
      cor: r.liquido < 0 ? _tintaVermelha : _tintaVerde, fundo: r.liquido < 0 ? _fundoVermelho : _fundoVerde));
  if (regras.freteRealEhValorCheio) w.addAll(_contaDoCaminhao(p, d));
  return w;
}

List<pw.Widget> _contaDoCaminhao(_Pdf p, DadosRelatorio d) {
  final r = d.resultado;
  final w = <pw.Widget>[
    p.titulo('Conta do caminhão'),
    p.nota('Aqui a pergunta é outra: este período deu lucro para o caminhão? Parte do que entrou na conta e '
        'desconta tudo que saiu.', abaixo: 6),
  ];
  if (r.totalContratado > 0) {
    w.add(p.valor('Frete contratado', reais(r.totalContratado)));
    w.add(p.nota('Peso vezes o valor da tonelada, conforme a carta-frete', recuo: 8));
    w.add(p.valor('( - ) Desconto da transportadora', reais(r.totalDescontoDoFrete)));
    w.add(p.nota(
      'INSS, SEST/SENAT, seguro, quebra, vale-pedágio e o que mais a transportadora tiver retido. O app calcula '
      'pela diferença entre o contratado e o que caiu na conta, então o valor bate sempre com a carta-frete.',
      recuo: 8,
    ));
  }
  w.add(p.valor('Frete líquido', reais(r.totalFretes)));
  w.add(p.nota('O que realmente caiu na conta: adiantamento mais saldo de ${plural(r.quantidadeFretes, 'frete', 'fretes')}',
      recuo: 8));
  w.add(p.valor('( - ) Diesel', reais(r.totalAbastecimento)));
  for (final a in d.abastecimentos) {
    final posto = a.posto.trim().isEmpty ? 'posto' : a.posto.trim();
    final cidade = a.cidade.trim().isEmpty ? '' : ' (${a.cidade.trim()})';
    w.add(p.item('${dataTexto(a.data)}   $posto$cidade   ${umaCasa(a.litros)} L', reais(a.valor)));
  }
  w.add(p.valor('( - ) Outros gastos', reais(r.totalGastos)));
  for (final g in d.gastos) {
    w.add(p.item('${dataTexto(g.data)}   ${g.categoria.trim().isEmpty ? 'sem categoria' : g.categoria}', reais(g.valor)));
  }
  w.add(p.valor('( - ) Comissão do motorista', reais(r.comissaoDoCaminhao)));
  w.add(p.nota('Quem paga a comissão é o frete. Por isso ela entra como despesa do caminhão, no mesmo peso do diesel.',
      recuo: 8));
  if (r.totalPedagio > 0) {
    w.add(p.nota(
      'O pedágio de ${reais(r.totalPedagio)} NÃO entra nesta subtração: foi pago no cartão ou tag da empresa, esse '
      'dinheiro nunca saiu da conta. Pedágio pago do próprio bolso deve ser lançado em Gastos.',
      recuo: 8,
      tamanho: 8.5,
    ));
  }
  final emAberto = r.fretesEmAberto > 0;
  final positivo = r.sobraDoCaminhao >= 0;
  if (emAberto) {
    w.add(p.bloco(
      r.fretesEmAberto == 1 ? '1 FRETE AINDA NÃO FOI PAGO' : '${r.fretesEmAberto} FRETES AINDA NÃO FORAM PAGOS',
      reais(r.contratadoEmAberto),
      'Devem entrar quando o saldo cair. Enquanto isso, a conta abaixo mostra despesa sem a receita correspondente.',
      cor: _tintaLaranja,
      fundo: _fundoAmarelo,
    ));
  }
  final contaTexto = '${reais(r.totalFretes)} - ${dinheiro(r.totalAbastecimento)} - ${dinheiro(r.totalGastos)} - '
      '${dinheiro(r.comissaoDoCaminhao)}';
  w.add(p.bloco(
    positivo
        ? 'SOBROU PARA O CAMINHÃO'
        : (emAberto ? 'NO VERMELHO POR ENQUANTO (falta o frete cair)' : 'FALTOU (o período deu prejuízo)'),
    reais(r.sobraDoCaminhao),
    contaTexto,
    cor: positivo ? _tintaVerde : (emAberto ? _tintaLaranja : _tintaVermelha),
    fundo: positivo ? _fundoVerde : (emAberto ? _fundoAmarelo : _fundoVermelho),
  ));
  if (r.totalQuebraKg > 0 || r.totalDescontoQuebra > 0) {
    w.add(pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
      child: pw.Text('Quebra na descarga', style: p.t(11, negrito: true)),
    ));
    if (r.totalQuebraKg > 0) {
      w.add(p.nota('Faltaram ${semCasas(r.totalQuebraKg)} kg entre a carga e a descarga. Pelo valor da tonelada isso '
          'daria ${reais(r.totalQuebraCalculada)}.', recuo: 8));
    }
    if (r.totalDescontoQuebra > 0) {
      w.add(p.nota('A transportadora cobrou ${reais(r.totalDescontoQuebra)}.', recuo: 8));
      final aMais = r.totalDescontoQuebra - r.totalQuebraCalculada;
      if (r.totalQuebraCalculada > 0 && aMais > 0.01) {
        w.add(p.nota('ATENÇÃO: cobraram ${reais(aMais)} a mais do que a quebra valia pelo preço da tonelada. '
            'Vale conferir o contrato.', recuo: 8, cor: _tintaLaranja));
      }
    }
    w.add(p.nota('A quebra não é subtraída de novo aqui: o saldo recebido já veio com ela descontada.',
        recuo: 8, tamanho: 8.5));
  }
  return w;
}

List<pw.Widget> _fechoDiesel(_Pdf p, DadosRelatorio d) {
  final lista = d.abastecimentos;
  if (lista.isEmpty) return [];
  final total = lista.fold<double>(0, (s, a) => s + a.valor);
  final litros = lista.fold<double>(0, (s, a) => s + a.litros);
  final mp = mediaDoPeriodo(lista, d.abastecimentosCompletos);
  final w = <pw.Widget>[
    p.titulo('Fecho do diesel'),
    p.valor('Total gasto com diesel', reais(total)),
    p.valor('Litros abastecidos', '${umaCasa(litros)} L'),
  ];
  if (litros > 0) w.add(p.nota('Preço médio do litro: ${reais(total / litros)}', recuo: 8));
  final media = mp.media;
  if (media != null) {
    w.add(p.bloco('MÉDIA REAL DO CAMINHÃO', '${umaCasa(media)} km/L',
        '${semCasas(mp.km)} km rodados com ${umaCasa(mp.litros)} L'));
    w.add(p.nota('Km rodados divididos pelos litros que entraram, de tanque cheio a tanque cheio. Não é a média de '
        'cada abastecida somada e dividida, que daria outro número, porque cada tanque tem um tamanho.', tamanho: 8.5));
  } else {
    w.add(p.nota('Ainda não dá para calcular a média do período: é preciso pelo menos dois tanques cheios.',
        cor: _tintaLaranja));
  }
  return w;
}

List<pw.Widget> _fechoFretes(_Pdf p, ResultadoResumo r) {
  if (r.quantidadeFretes == 0) return [];
  return [
    p.titulo('Fecho dos fretes'),
    if (r.totalContratado > 0) ...[
      p.valor('Frete contratado', reais(r.totalContratado)),
      p.valor('( - ) Desconto da transportadora', reais(r.totalDescontoDoFrete)),
    ],
    p.bloco('FRETE LÍQUIDO QUE CAIU NA CONTA', reais(r.totalFretes),
        '${plural(r.quantidadeFretes, 'frete', 'fretes')}   |   comissão do motorista ${reais(r.comissaoDoCaminhao)}'),
  ];
}

List<pw.Widget> _fechoGastos(_Pdf p, DadosRelatorio d) {
  final r = d.resultado;
  final total = r.totalGastoGeral + r.comissaoDoCaminhao;
  if (total <= 0) return [];
  return [
    p.titulo('Tudo que o caminhão gastou'),
    p.nota('A lista acima traz só os gastos avulsos. O custo de verdade inclui o diesel e a comissão do motorista.'),
    p.valor('Diesel', reais(r.totalAbastecimento)),
    p.valor('Gastos avulsos', reais(r.totalGastos)),
    p.valor('Comissão do motorista', reais(r.comissaoDoCaminhao)),
    p.bloco('CUSTO TOTAL DO CAMINHÃO NO PERÍODO', reais(total),
        '${dinheiro(r.totalAbastecimento)} + ${dinheiro(r.totalGastos)} + ${dinheiro(r.comissaoDoCaminhao)}'),
    if (r.totalFretes > 0)
      pw.Text('Entrou de frete ${reais(r.totalFretes)} no mesmo período. Sobrou para o caminhão ${reais(r.sobraDoCaminhao)}.',
          style: p.t(10.5, negrito: true)),
  ];
}

List<pw.Widget> _fretes(_Pdf p, List<Frete> lista) {
  final w = <pw.Widget>[p.titulo('Fretes (${lista.length})')];
  if (lista.isEmpty) return w..add(p.nota('Nenhum frete neste período.', tamanho: 11));
  final ordenados = List<Frete>.from(lista)..sort((a, b) => a.dataCarga.compareTo(b.dataCarga));
  for (final f in ordenados) {
    final linhas = <pw.Widget>[
      pw.Text('${dataTexto(f.dataCarga)}   ${f.origem} para ${f.destino}', style: p.t(12, negrito: true)),
      if (f.empresa.trim().isNotEmpty) p.nota(f.empresa, recuo: 8, tamanho: 10, abaixo: 1),
      if (f.pesoKg > 0)
        p.nota('Carregou ${toneladas(f.pesoKg)} t${f.pesoDescargaKg > 0 ? '   Descarregou ${toneladas(f.pesoDescargaKg)} t' : ''}',
            recuo: 8, tamanho: 10, abaixo: 1),
    ];
    final q = f.quebraKg;
    if (q != null) {
      final desc = f.descontoQuebra > 0
          ? '   Descontado no acerto: ${reais(f.descontoQuebra)} (integral daria ${reais(f.valorQuebraIntegral)})'
          : '   Não foi descontado';
      linhas.add(p.nota('Quebra de ${semCasas(q)} kg$desc', recuo: 8, tamanho: 10, abaixo: 1, cor: _tintaLaranja));
    }
    linhas.add(p.nota(
      'Adiantamento ${reais(f.adiantamento)}   Saldo ${f.saldo > 0 ? reais(f.saldo) : 'em aberto'}'
      '${f.pedagio > 0 ? '   Pedágio ${reais(f.pedagio)}' : ''}',
      recuo: 8,
      tamanho: 10,
      abaixo: 1,
    ));
    linhas.add(p.nota(
      'Frete real ${reais(f.freteReal)}   Comissão ${percentualTexto(f.percentualComissao)}% sobre '
      '${reais(f.baseComissao)} = ${reais(f.minhaParte)}${f.pedagio > 0 && f.comissaoSobreBruto ? ' (com pedágio)' : ''}',
      recuo: 8,
      tamanho: 10,
      cor: _tintaVerde,
      abaixo: 10,
    ));
    w.add(pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: linhas));
  }
  return w;
}

List<pw.Widget> _abastecimentos(_Pdf p, List<Abastecimento> lista, List<Abastecimento> todas) {
  final doPeriodo = lista.where((a) => !a.pontoDePartida).toList()..sort((a, b) => a.km.compareTo(b.km));
  final w = <pw.Widget>[p.titulo('Diesel (${doPeriodo.length})')];
  if (doPeriodo.isEmpty) return w..add(p.nota('Nenhuma abastecida neste período.', tamanho: 11));
  var total = 0.0;
  var litros = 0.0;
  for (final a in doPeriodo) {
    total += a.valor;
    litros += a.litros;
    final m = mediaDaLinha(todas, a);
    final media = m.media;
    w.add(pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('${dataTexto(a.data)}   km ${semCasas(a.km)}   ${a.cidade}', style: p.t(12, negrito: true)),
        if (a.posto.trim().isNotEmpty) p.nota(a.posto, recuo: 8, tamanho: 10, abaixo: 1),
        p.nota(
          '${umaCasa(a.litros)} litros   ${reais(a.valor)}   ${a.tanqueCheio ? 'tanque cheio' : 'tanque não completado'}'
          '${media != null ? '   média ${umaCasa(media)} km/L' : ''}',
          recuo: 8,
          tamanho: 10,
          cor: media != null ? _tintaVerde : _tintaCinza,
          abaixo: 9,
        ),
      ],
    ));
  }
  w.add(p.valor('Total abastecido', reais(total)));
  w.add(p.nota('${umaCasa(litros)} litros no período', recuo: 8));
  return w;
}

List<pw.Widget> _vales(_Pdf p, List<Vale> lista, double total) {
  final w = <pw.Widget>[p.titulo('Vales (${lista.length})')];
  if (lista.isEmpty) return w..add(p.nota('Nenhum vale neste período.', tamanho: 11));
  final ordenados = List<Vale>.from(lista)..sort((a, b) => a.data.compareTo(b.data));
  for (final v in ordenados) {
    w.add(p.item(dataTexto(v.data), reais(v.valor)));
  }
  w.add(p.valor('Total de vale', reais(total)));
  return w;
}

List<pw.Widget> _gastos(_Pdf p, List<Gasto> lista, double total) {
  final w = <pw.Widget>[p.titulo('Gastos (${lista.length})')];
  if (lista.isEmpty) return w..add(p.nota('Nenhum gasto neste período.', tamanho: 11));
  final ordenados = List<Gasto>.from(lista)..sort((a, b) => a.data.compareTo(b.data));
  for (final g in ordenados) {
    w.add(p.item('${dataTexto(g.data)}   ${g.categoria}', reais(g.valor)));
  }
  w.add(p.valor('Total de gastos', reais(total)));
  return w;
}

List<pw.Widget> _ajustes(_Pdf p, List<AjusteKm> lista) {
  if (lista.isEmpty) return [];
  final ordenados = List<AjusteKm>.from(lista)..sort((a, b) => b.quando.compareTo(a.quando));
  return [
    p.titulo('Ajustes do km inicial'),
    p.nota('Toda vez que o km inicial foi alterado fica registrado aqui, com data, hora e motivo.', abaixo: 8),
    for (final a in ordenados)
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          p.nota(dataHoraTexto(a.quando), abaixo: 1),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 8),
            child: pw.Text('km ${semCasas(a.kmAnterior)} alterado para ${semCasas(a.kmNovo)}',
                style: p.t(11, negrito: true, numero: true)),
          ),
          p.nota('Motivo: ${a.motivo}', recuo: 8, tamanho: 10, abaixo: 8),
        ],
      ),
  ];
}

/// Gera o PDF, salva e abre o "compartilhar" do Android (WhatsApp, e-mail...).
Future<void> gerarEEnviarPdf(DadosRelatorio d) async {
  final fontes = await FontesPdf.carregar();
  final bytes = await gerarPdf(d, fontes);
  final pasta = Directory('${(await getTemporaryDirectory()).path}/relatorios');
  await pasta.create(recursive: true);
  final nome = nomeDoArquivoPdf(d);
  final arquivo = File('${pasta.path}/$nome');
  await arquivo.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles(
    [XFile(arquivo.path, mimeType: 'application/pdf', name: nome)],
    subject: (d.ehViagem ? 'Acerto da viagem: ${d.viagem}' : 'Relatório Meu Frete') +
        (d.placa.isEmpty ? '' : ' (${placaTexto(d.placa)})'),
  );
}
