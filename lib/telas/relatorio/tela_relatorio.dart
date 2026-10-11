import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../componentes/basicos.dart';
import '../../componentes/seletor_periodo.dart';
import '../../dados/configuracao.dart';
import '../../dados/dados.dart';
import '../../nucleo/formato.dart';
import '../../regras/dados_relatorio.dart';
import '../../regras/periodo.dart';
import '../../relatorio/gerador_pdf.dart';
import '../../tema.dart';

/// Monta o relatorio em PDF para mandar ao patrao.
class TelaRelatorio extends StatefulWidget {
  const TelaRelatorio({super.key});

  @override
  State<TelaRelatorio> createState() => _TelaRelatorioState();
}

class _TelaRelatorioState extends State<TelaRelatorio> {
  var _escolha = const EscolhaPeriodo(TipoPeriodo.mesAtual);
  var _conteudo = ConteudoRelatorio.tudo;
  bool _gerando = false;

  Future<void> _gerar(DadosRelatorio d) async {
    setState(() => _gerando = true);
    try {
      await gerarEEnviarPdf(d);
    } catch (e) {
      if (mounted) mostrarMensagem(context, 'Não consegui montar o PDF: $e');
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dados = context.watch<Dados>();
    final config = context.watch<Configuracao>();
    final periodo = _escolha.periodo;
    final d = periodo == null ? null : dados.dadosDoPeriodo(periodo, config.regras, conteudo: _conteudo);

    final List<String> partes;
    if (d == null) {
      partes = const [];
    } else {
      final fr = plural(d.fretes.length, 'frete', 'fretes');
      final ab = plural(d.abastecimentos.length, 'abastecida', 'abastecidas');
      final va = plural(d.vales.length, 'vale', 'vales');
      final ga = plural(d.gastos.length, 'gasto', 'gastos');
      switch (_conteudo) {
        case ConteudoRelatorio.tudo:
          partes = [fr, ab, va, ga];
        case ConteudoRelatorio.fretes:
          partes = [fr];
        case ConteudoRelatorio.diesel:
          partes = [ab];
        case ConteudoRelatorio.vales:
          partes = [va];
        case ConteudoRelatorio.gastos:
          partes = [ga];
      }
    }

    final bool semNada;
    if (d == null) {
      semNada = true;
    } else {
      switch (_conteudo) {
        case ConteudoRelatorio.tudo:
          semNada = d.vazio;
        case ConteudoRelatorio.fretes:
          semNada = d.fretes.isEmpty;
        case ConteudoRelatorio.diesel:
          semNada = d.abastecimentos.isEmpty;
        case ConteudoRelatorio.vales:
          semNada = d.vales.isEmpty;
        case ConteudoRelatorio.gastos:
          semNada = d.gastos.isEmpty;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Relatório em PDF')),
      bottomNavigationBar: RodapeBotao(
        texto: _gerando ? 'Montando o PDF...' : 'Gerar PDF e enviar',
        icone: Icons.ios_share,
        aoTocar: (_gerando || d == null) ? null : () => _gerar(d),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Text('De quando até quando', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
          SeletorPeriodo(escolha: _escolha, aoMudar: (e) => setState(() => _escolha = e)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  periodo == null ? 'Escolha as datas.' : periodo.texto,
                  style: estiloNumero(17, peso: FontWeight.w500, cor: context.cores.textoFraco),
                ),
                const TituloSecao('O que vai no papel', espacoAcima: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in ConteudoRelatorio.values)
                      ChoiceChip(
                        label: Text(c.rotulo),
                        selected: _conteudo == c,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _conteudo = c),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Nota(_conteudo == ConteudoRelatorio.tudo
                    ? 'Vai tudo junto: fretes, diesel, vales, gastos e as contas do período.'
                    : 'Só a parte escolhida, com o fechamento dela.'),
                const TituloSecao('Vai no relatório'),
                if (partes.isNotEmpty)
                  Text(partes.join(', '), style: const TextStyle(fontSize: 17)),
                if (semNada) ...[
                  const SizedBox(height: 12),
                  Aviso(
                    icone: Icons.info_outline,
                    titulo: 'Nada anotado neste período',
                    texto: 'O PDF vai sair sem registros. Confira se o período escolhido pega a data dos seus lançamentos.',
                  ),
                ],
                const SizedBox(height: 24),
                Nota('O PDF sai em folha branca com letra grande, para o patrão ler no celular ou imprimir. '
                    'Se o km inicial já foi mudado alguma vez, o registro sai no pé do papel.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
