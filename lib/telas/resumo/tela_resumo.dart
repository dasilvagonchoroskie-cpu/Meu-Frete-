import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../componentes/basicos.dart';
import '../../componentes/placa.dart';
import '../../componentes/placa_veiculo.dart';
import '../../componentes/seletor_periodo.dart';
import '../../dados/configuracao.dart';
import '../../dados/dados.dart';
import '../../nucleo/formato.dart';
import '../../regras/media_diesel.dart';
import '../../regras/periodo.dart';
import '../../tema.dart';
import '../caminhao/tela_caminhao.dart';
import '../configuracoes/tela_configuracoes.dart';
import '../relatorio/tela_relatorio.dart';

class TelaResumo extends StatefulWidget {
  const TelaResumo({super.key});

  @override
  State<TelaResumo> createState() => _TelaResumoState();
}

class _TelaResumoState extends State<TelaResumo> {
  var _escolha = const EscolhaPeriodo(TipoPeriodo.mesAtual);

  @override
  Widget build(BuildContext context) {
    final dados = context.watch<Dados>();
    final config = context.watch<Configuracao>();
    final regras = config.regras;
    final cores = context.cores;
    final periodo = _escolha.periodo ?? calcularPeriodo(TipoPeriodo.mesAtual)!;
    final d = dados.dadosDoPeriodo(periodo, regras, motorista: config.nomeMotorista);
    final r = d.resultado;
    final descricao = _escolha.descricao;

    String detalheComissao;
    if (!regras.freteRealEhValorCheio) {
      detalheComissao = 'Sua parte dos fretes, já anotada';
    } else if (r.quantidadeFretes == 0) {
      detalheComissao = 'Nenhum frete no período';
    } else if (r.percentuaisDiferentes) {
      detalheComissao = 'Na média ${percentualTexto(r.percentualMedio)}% sobre ${reais(r.totalBaseComissao)}';
    } else {
      detalheComissao = '${percentualTexto(r.percentualMedio)}% sobre ${reais(r.totalBaseComissao)}';
    }

    final mediaDiesel = mediaDoPeriodo(d.abastecimentos, dados.abastecimentos);
    final litros = d.abastecimentos.fold<double>(0, (s, a) => s + a.litros);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Frete'),
        actions: [
          IconButton(
            tooltip: 'Relatório em PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaRelatorio())),
          ),
          IconButton(
            tooltip: 'Configurações',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaConfiguracoes())),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCaminhao())),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
              child: Row(
                children: [
                  PlacaVeiculo(config.placaAtual, tamanho: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      config.nomeMotorista,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(Icons.swap_horiz, color: cores.textoFraco, semanticLabel: 'Trocar de caminhão'),
                ],
              ),
            ),
          ),
          SeletorPeriodo(escolha: _escolha, aoMudar: (e) => setState(() => _escolha = e)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Placa(
                  rotulo: r.liquido < 0 ? 'Você está devendo' : 'Você tem para receber',
                  valor: reais(r.liquido),
                  detalhe: descricao[0].toUpperCase() + descricao.substring(1),
                  tipo: r.liquido < 0 ? TipoPlaca.vermelha : TipoPlaca.verde,
                ),
                const SizedBox(height: 10),
                LinhaValor(
                  rotulo: regras.freteRealEhValorCheio ? 'Comissão' : 'Sua parte',
                  valor: '+ ${reais(r.comissao)}',
                  detalhe: detalheComissao,
                  corValor: cores.positivo,
                  corDetalhe: r.percentuaisDiferentes ? cores.atencao : null,
                ),
                LinhaValor(
                  rotulo: 'Diesel e gastos',
                  valor: regras.gastosDescontamDoLiquido ? '$menos ${reais(r.totalGastoGeral)}' : reais(r.totalGastoGeral),
                  detalhe: regras.gastosDescontamDoLiquido
                      ? 'Saem do seu bolso, então descontam'
                      : 'A empresa paga, não descontam do seu líquido',
                  corValor: regras.gastosDescontamDoLiquido ? cores.negativo : cores.textoFraco,
                ),
                LinhaValor(
                  rotulo: 'Vales',
                  valor: regras.valeDescontaDoLiquido ? '$menos ${reais(r.totalVale)}' : reais(r.totalVale),
                  detalhe: regras.valeDescontaDoLiquido
                      ? 'Você já recebeu adiantado, então desconta'
                      : 'Só histórico, não mexe no líquido',
                  corValor: regras.valeDescontaDoLiquido ? cores.negativo : cores.textoFraco,
                ),
                if (d.vazio) ...[
                  const SizedBox(height: 16),
                  Aviso(
                    icone: Icons.edit_note,
                    titulo: 'Nada lançado em $descricao',
                    texto: 'Anote os fretes, as abastecidas, os gastos e os vales nas abas de baixo. '
                        'As contas aparecem aqui sozinhas.',
                  ),
                ],
                if (regras.freteRealEhValorCheio && !d.vazio) ...[
                  const TituloSecao('Conta do caminhão'),
                  Nota('O que sobrou depois de pagar o diesel, os gastos e a comissão.'),
                  const SizedBox(height: 6),
                  if (r.fretesEmAberto > 0) ...[
                    Aviso(
                      icone: Icons.hourglass_bottom,
                      titulo: r.fretesEmAberto == 1
                          ? '1 frete aguardando saldo'
                          : '${r.fretesEmAberto} fretes aguardando saldo',
                      texto: 'Devem entrar ${reais(r.contratadoEmAberto)} quando o saldo cair. '
                          'Até lá a conta mostra a despesa sem essa receita.',
                    ),
                    const SizedBox(height: 6),
                  ],
                  LinhaValor(
                    rotulo: 'Frete que caiu na conta',
                    valor: reais(r.totalFretes),
                    detalhe: plural(r.quantidadeFretes, 'frete', 'fretes') +
                        (r.totalDescontoDoFrete > 0.009
                            ? ', descontaram ${reais(r.totalDescontoDoFrete)} do contratado'
                            : ''),
                  ),
                  LinhaValor(rotulo: 'Diesel', valor: '$menos ${reais(r.totalAbastecimento)}'),
                  LinhaValor(rotulo: 'Outros gastos', valor: '$menos ${reais(r.totalGastos)}'),
                  LinhaValor(rotulo: 'Comissão do motorista', valor: '$menos ${reais(r.comissaoDoCaminhao)}'),
                  const Divider(height: 18),
                  LinhaValor(
                    rotulo: r.sobraDoCaminhao >= 0 ? 'Sobrou para o caminhão' : 'Faltou',
                    valor: reais(r.sobraDoCaminhao),
                    destaque: true,
                    corValor: r.sobraDoCaminhao >= 0
                        ? cores.positivo
                        : (r.fretesEmAberto > 0 ? cores.atencao : cores.negativo),
                  ),
                  if (r.totalQuebraKg > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Nota(
                        'Quebra de ${semCasas(r.totalQuebraKg)} kg no período'
                        '${r.totalDescontoQuebra > 0 ? ', descontaram ${reais(r.totalDescontoQuebra)}' : ''}.',
                      ),
                    ),
                ],
                if (d.abastecimentos.isNotEmpty) ...[
                  const TituloSecao('Diesel'),
                  LinhaValor(
                    rotulo: 'Média do caminhão',
                    valor: mediaDiesel.media == null ? '—' : '${umaCasa(mediaDiesel.media!)} km/L',
                    detalhe: mediaDiesel.media == null
                        ? 'Precisa de dois tanques cheios para calcular'
                        : '${semCasas(mediaDiesel.km)} km rodados com ${umaCasa(mediaDiesel.litros)} L',
                  ),
                  LinhaValor(
                    rotulo: 'Litros abastecidos',
                    valor: '${umaCasa(litros)} L',
                    detalhe: litros > 0 ? 'Preço médio do litro ${reais(r.totalAbastecimento / litros)}' : null,
                  ),
                ],
                const SizedBox(height: 28),
                Nota(
                  'As contas seguem o seu jeito de trabalhar: comissão padrão de ${percentualTexto(config.percentualPadrao)}%, '
                  '${regras.gastosDescontamDoLiquido ? 'gastos por sua conta' : 'gastos pagos pela empresa'} e '
                  '${regras.valeDescontaDoLiquido ? 'vale descontando' : 'vale sem descontar'}.',
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TelaConfiguracoes()),
                    ),
                    child: const Text('Mudar como você trabalha'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
