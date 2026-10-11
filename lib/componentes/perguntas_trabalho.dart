import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dados/configuracao.dart';
import '../nucleo/entrada.dart';
import '../nucleo/formato.dart';
import '../tema.dart';
import 'basicos.dart';
import 'campos.dart';

/// As quatro perguntas que mudam a conta do valor liquido.

class PerguntaComissao extends StatefulWidget {
  const PerguntaComissao({super.key});

  @override
  State<PerguntaComissao> createState() => _PerguntaComissaoState();
}

class _PerguntaComissaoState extends State<PerguntaComissao> {
  late final TextEditingController _percentual;

  @override
  void initState() {
    super.initState();
    _percentual = TextEditingController(text: textoDecimal(context.read<Configuracao>().percentualPadrao));
  }

  @override
  void dispose() {
    _percentual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<Configuracao>();
    final p = config.percentualPadrao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Campo(
          controle: _percentual,
          rotulo: 'Porcentagem padrão',
          tipo: TipoCampo.decimal,
          sufixo: '%',
          ajuda: 'Vale para os fretes novos. Em cada frete dá para mudar, porque tem empresa que paga diferente.',
          aoMudar: (t) {
            final v = lerNumero(t);
            if (v > 0 && v <= 100) config.percentualPadrao = v;
          },
        ),
        const SizedBox(height: 18),
        const Text('A comissão entra sobre o quê?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Nota('O pedágio quase sempre vai no cartão ou tag e não passa pela sua mão. Mesmo assim tem patrão '
            'que paga a comissão em cima do total.'),
        const SizedBox(height: 10),
        OpcaoEscolha<bool>(
          valor: true,
          escolhido: config.comissaoSobreBrutoPadrao,
          titulo: 'Frete + pedágio',
          descricao: 'Frete de R\$ 10.000 mais R\$ 2.000 de pedágio, a ${percentualTexto(p)}%: ${reais(12000 * p / 100)}',
          aoEscolher: (v) => config.comissaoSobreBrutoPadrao = v,
        ),
        OpcaoEscolha<bool>(
          valor: false,
          escolhido: config.comissaoSobreBrutoPadrao,
          titulo: 'Só o frete',
          descricao: '${percentualTexto(p)}% só sobre os R\$ 10.000: ${reais(10000 * p / 100)}',
          aoEscolher: (v) => config.comissaoSobreBrutoPadrao = v,
        ),
      ],
    );
  }
}

class PerguntaFreteCheio extends StatelessWidget {
  const PerguntaFreteCheio({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<Configuracao>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Somando adiantamento e saldo, o que você anota é:',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        OpcaoEscolha<bool>(
          valor: true,
          escolhido: config.freteRealEhValorCheio,
          titulo: 'O valor cheio do frete',
          descricao: 'O dinheiro do frete inteiro passa pela sua mão. O app tira a sua comissão em cima dele.',
          aoEscolher: (v) => config.freteRealEhValorCheio = v,
        ),
        OpcaoEscolha<bool>(
          valor: false,
          escolhido: config.freteRealEhValorCheio,
          titulo: 'Só a minha parte',
          descricao: 'Você já anota só o que é seu. O app não tira porcentagem nenhuma.',
          aoEscolher: (v) => config.freteRealEhValorCheio = v,
        ),
      ],
    );
  }
}

class PerguntaGastos extends StatelessWidget {
  const PerguntaGastos({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<Configuracao>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Quem paga o diesel e os gastos?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Nota('Borracharia, manutenção, chapa, abastecimento.'),
        const SizedBox(height: 10),
        OpcaoEscolha<bool>(
          valor: false,
          escolhido: config.gastosDescontamDoLiquido,
          titulo: 'A empresa paga',
          descricao: 'Os gastos não descontam do seu líquido. Aparecem no relatório só para prestar conta.',
          aoEscolher: (v) => config.gastosDescontamDoLiquido = v,
        ),
        OpcaoEscolha<bool>(
          valor: true,
          escolhido: config.gastosDescontamDoLiquido,
          titulo: 'Sai do meu bolso',
          descricao: 'Os gastos descontam do seu líquido, porque o dinheiro saiu de você.',
          aoEscolher: (v) => config.gastosDescontamDoLiquido = v,
        ),
      ],
    );
  }
}

class PerguntaVale extends StatelessWidget {
  const PerguntaVale({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<Configuracao>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('O vale que você pega adiantado:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        OpcaoEscolha<bool>(
          valor: true,
          escolhido: config.valeDescontaDoLiquido,
          titulo: 'Desconta',
          descricao: 'Você já recebeu esse dinheiro antes, então ele abate do que ainda tem para receber.',
          aoEscolher: (v) => config.valeDescontaDoLiquido = v,
        ),
        OpcaoEscolha<bool>(
          valor: false,
          escolhido: config.valeDescontaDoLiquido,
          titulo: 'Não desconta',
          descricao: 'O vale fica só como histórico e não mexe no líquido.',
          aoEscolher: (v) => config.valeDescontaDoLiquido = v,
        ),
      ],
    );
  }
}

/// Exemplo de um mes com R$ 30.000 em fretes, seguindo as respostas.
class ExemploDaConta extends StatelessWidget {
  const ExemploDaConta({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<Configuracao>();
    final cores = context.cores;
    const fretes = 30000.0;
    const gastos = 9000.0;
    const vale = 1000.0;
    final p = config.percentualPadrao;
    final comissao = config.freteRealEhValorCheio ? fretes * p / 100 : fretes;
    var liquido = comissao;
    if (config.gastosDescontamDoLiquido) liquido -= gastos;
    if (config.valeDescontaDoLiquido) liquido -= vale;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        color: cores.campoFundo,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Exemplo: um mês com R\$ 30.000 em fretes', style: TextStyle(fontSize: 15, color: cores.textoFraco)),
          const SizedBox(height: 4),
          LinhaValor(
            rotulo: config.freteRealEhValorCheio ? 'Comissão de ${percentualTexto(p)}%' : 'Sua parte (já anotada)',
            valor: '+ ${reais(comissao)}',
            corValor: cores.positivo,
          ),
          LinhaValor(
            rotulo: 'Diesel e gastos de R\$ 9.000',
            valor: config.gastosDescontamDoLiquido ? '$menos ${reais(gastos)}' : 'não entra',
            corValor: config.gastosDescontamDoLiquido ? cores.negativo : cores.textoFraco,
          ),
          LinhaValor(
            rotulo: 'Vale de R\$ 1.000',
            valor: config.valeDescontaDoLiquido ? '$menos ${reais(vale)}' : 'não entra',
            corValor: config.valeDescontaDoLiquido ? cores.negativo : cores.textoFraco,
          ),
          const Divider(height: 16),
          LinhaValor(
            rotulo: 'Seu líquido',
            valor: reais(liquido),
            destaque: true,
            corValor: liquido < 0 ? cores.negativo : null,
          ),
          if (liquido < 0)
            Nota('Neste exemplo o líquido ficou negativo. Confira se as respostas batem com o seu combinado.',
                cor: cores.negativo),
        ],
      ),
    );
  }
}
