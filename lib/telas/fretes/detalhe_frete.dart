import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../componentes/basicos.dart';
import '../../componentes/listas.dart';
import '../../componentes/placa.dart';
import '../../dados/configuracao.dart';
import '../../dados/dados.dart';
import '../../nucleo/formato.dart';
import '../../relatorio/gerador_pdf.dart';
import '../../tema.dart';
import 'form_frete.dart';

class DetalheFrete extends StatefulWidget {
  const DetalheFrete({super.key, required this.idFrete});
  final int idFrete;

  @override
  State<DetalheFrete> createState() => _DetalheFreteState();
}

class _DetalheFreteState extends State<DetalheFrete> {
  bool _gerando = false;

  @override
  Widget build(BuildContext context) {
    final dados = context.watch<Dados>();
    final config = context.watch<Configuracao>();
    final f = dados.freteComId(widget.idFrete);
    final cores = context.cores;

    if (f == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }

    final viagem = dados.dadosDaViagem(f, config.regras);
    final r = viagem.resultado;
    final cheio = config.freteRealEhValorCheio;
    final contratado = f.valorContratado;
    final dif = f.diferencaDoContratado;
    final quebra = f.quebraKg;

    Future<void> apagar() async {
      final ok = await confirmarExclusao(
        context,
        titulo: 'Apagar este frete?',
        detalhe: '${f.rota}, carga de ${dataTexto(f.dataCarga)}. Não dá para desfazer.',
      );
      if (!ok || !context.mounted) return;
      final mensageiro = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      await dados.apagarFrete(f);
      mensageiro.showSnackBar(const SnackBar(content: Text('Frete apagado.')));
    }

    Future<void> enviar() async {
      setState(() => _gerando = true);
      try {
        await gerarEEnviarPdf(viagem);
      } catch (e) {
        if (context.mounted) mostrarMensagem(context, 'Não consegui gerar o acerto: $e');
      } finally {
        if (mounted) setState(() => _gerando = false);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Frete'),
        actions: [
          IconButton(
            tooltip: 'Mudar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FormFrete(editando: f))),
          ),
          IconButton(tooltip: 'Apagar', icon: const Icon(Icons.delete_outline), onPressed: apagar),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: RodapeBotao(
        texto: _gerando ? 'Montando o PDF...' : 'Enviar acerto da viagem',
        icone: Icons.ios_share,
        aoTocar: _gerando ? null : enviar,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 7), child: MarcadorTrajeto(altura: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.origem, style: context.textos.titleLarge),
                    const SizedBox(height: 8),
                    Text(f.destino, style: context.textos.titleLarge),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Carga de ${dataTexto(f.dataCarga)}${f.empresa.trim().isNotEmpty ? ', ${f.empresa.trim()}' : ''}',
            style: TextStyle(fontSize: 15.5, color: cores.textoFraco),
          ),
          const SizedBox(height: 18),
          if (cheio)
            Placa(
              rotulo: 'Sua parte neste frete',
              valor: reais(f.minhaParte),
              detalhe: '${percentualTexto(f.percentualComissao)}% sobre ${reais(f.baseComissao)}'
                  '${f.comissaoSobreBruto ? ' (frete + pedágio)' : ''}',
              tamanhoValor: 40,
            )
          else
            Placa(rotulo: 'Sua parte neste frete', valor: reais(f.freteReal), tamanhoValor: 40),
          if (f.aguardandoSaldo) ...[
            const SizedBox(height: 12),
            Aviso(
              icone: Icons.hourglass_bottom,
              titulo: 'Aguardando o saldo',
              texto: 'Quando o saldo cair, toque no lápis lá em cima e anote o valor.',
            ),
          ],
          const TituloSecao('Pagamento'),
          if (contratado > 0)
            LinhaValor(
              rotulo: 'Valor contratado',
              valor: reais(contratado),
              detalhe: '${toneladas(f.pesoKg)} t × ${reais(f.valorTonelada)}',
            ),
          LinhaValor(rotulo: 'Adiantamento', valor: reais(f.adiantamento)),
          LinhaValor(
            rotulo: 'Saldo',
            valor: f.saldo > 0 ? reais(f.saldo) : 'em aberto',
            corValor: f.saldo > 0 ? null : cores.atencao,
          ),
          const Divider(height: 18),
          LinhaValor(rotulo: 'Frete real (caiu na conta)', valor: reais(f.freteReal), destaque: true),
          if (f.pedagio > 0)
            LinhaValor(rotulo: 'Pedágio no cartão ou tag', valor: reais(f.pedagio), detalhe: 'Fora do frete'),
          if (f.freteReal > 0 && contratado > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Nota(
                dif.abs() < 0.01
                    ? 'Bateu certinho com o combinado.'
                    : (dif > 0
                        ? 'Entrou ${reais(dif)} a mais que o combinado. Confira.'
                        : 'A transportadora descontou ${reais(dif.abs())} do contratado '
                            '(INSS, SEST/SENAT, seguro, pedágio, quebra).'),
                cor: dif.abs() < 0.01 ? cores.positivo : (dif > 0 ? cores.atencao : null),
              ),
            ),
          if (f.pesoDescargaKg > 0 || quebra != null) ...[
            const TituloSecao('Descarga'),
            LinhaValor(rotulo: 'Carregou', valor: '${toneladas(f.pesoKg)} t'),
            LinhaValor(rotulo: 'Descarregou', valor: '${toneladas(f.pesoDescargaKg)} t'),
            if (quebra != null) ...[
              LinhaValor(
                rotulo: 'Quebra',
                valor: '${semCasas(quebra)} kg',
                detalhe: 'Pelo valor da tonelada vale ${reais(f.valorQuebraIntegral)}',
                corValor: cores.atencao,
              ),
              LinhaValor(
                rotulo: 'Descontaram',
                valor: f.descontoQuebra > 0 ? reais(f.descontoQuebra) : 'nada',
              ),
              if (f.valorQuebraIntegral > 0 && f.descontoQuebra > f.valorQuebraIntegral + 0.01)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Aviso(
                    icone: Icons.warning_amber_rounded,
                    texto: 'Cobraram ${reais(f.descontoQuebra - f.valorQuebraIntegral)} a mais do que a quebra vale. '
                        'Confira o acerto.',
                  ),
                ),
            ],
          ],
          if (cheio) ...[
            const TituloSecao('Conta desta viagem'),
            Nota('Diesel, gastos e vales lançados de ${dataTexto(viagem.periodo.inicio)} a '
                '${dataTexto(viagem.periodo.fim)}, até a carga seguinte.'),
            const SizedBox(height: 6),
            LinhaValor(rotulo: 'Frete que caiu na conta', valor: reais(r.totalFretes)),
            LinhaValor(
              rotulo: 'Diesel',
              valor: '$menos ${reais(r.totalAbastecimento)}',
              detalhe: plural(viagem.abastecimentos.length, 'abastecida', 'abastecidas'),
            ),
            LinhaValor(
              rotulo: 'Outros gastos',
              valor: '$menos ${reais(r.totalGastos)}',
              detalhe: plural(viagem.gastos.length, 'gasto', 'gastos'),
            ),
            LinhaValor(rotulo: 'Comissão do motorista', valor: '$menos ${reais(r.comissaoDoCaminhao)}'),
            const Divider(height: 18),
            LinhaValor(
              rotulo: r.sobraDoCaminhao >= 0 ? 'Sobrou para o caminhão' : 'Faltou',
              valor: reais(r.sobraDoCaminhao),
              destaque: true,
              corValor: r.sobraDoCaminhao >= 0 ? cores.positivo : (f.aguardandoSaldo ? cores.atencao : cores.negativo),
            ),
          ],
        ],
      ),
    );
  }
}
