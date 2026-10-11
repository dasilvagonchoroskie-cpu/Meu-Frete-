import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../componentes/basicos.dart';
import '../../componentes/listas.dart';
import '../../dados/configuracao.dart';
import '../../dados/dados.dart';
import '../../dados/modelos.dart';
import '../../nucleo/formato.dart';
import '../../tema.dart';
import 'detalhe_frete.dart';
import 'form_frete.dart';

class TelaFretes extends StatelessWidget {
  const TelaFretes({super.key});

  void _novo(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FormFrete()));

  @override
  Widget build(BuildContext context) {
    final dados = context.watch<Dados>();
    final grupos = agruparPorMes<Frete>(dados.fretes, (f) => f.dataCarga);

    return Scaffold(
      appBar: AppBar(title: const Text('Fretes')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'novo_frete',
        onPressed: () => _novo(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo frete'),
      ),
      body: dados.fretes.isEmpty
          ? ListView(children: [
              EstadoVazio(
                icone: Icons.local_shipping_outlined,
                titulo: 'Nenhum frete anotado',
                texto: 'Anote a carga quando carregar: origem, destino, peso e o adiantamento. '
                    'O saldo e o peso da descarga você completa depois.',
                acao: FilledButton.icon(
                  onPressed: () => _novo(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Anotar o primeiro frete'),
                ),
              ),
            ])
          : ListView(
              children: [
                for (final g in grupos) ...[
                  CabecalhoMes(
                    titulo: g.titulo,
                    resumo: reais(g.itens.fold<double>(0, (s, f) => s + f.freteReal)),
                  ),
                  for (var i = 0; i < g.itens.length; i++) ...[
                    if (i > 0) const Divider(indent: 20, endIndent: 20),
                    LinhaFrete(frete: g.itens[i]),
                  ],
                ],
                espacoFinalLista,
              ],
            ),
    );
  }
}

class LinhaFrete extends StatelessWidget {
  const LinhaFrete({super.key, required this.frete});
  final Frete frete;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final cheio = context.watch<Configuracao>().freteRealEhValorCheio;
    final f = frete;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalheFrete(idFrete: f.id))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColunaData(f.dataCarga),
            const SizedBox(width: 12),
            const Padding(padding: EdgeInsets.only(top: 6), child: MarcadorTrajeto(altura: 14)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.origem, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(f.destino, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  if (f.empresa.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(f.empresa, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: cores.textoFraco)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(reais(f.freteReal), style: estiloNumero(18)),
                const SizedBox(height: 6),
                if (f.aguardandoSaldo && f.adiantamento > 0)
                  const Etiqueta('Aguardando saldo')
                else if (f.freteReal <= 0)
                  const Etiqueta('Sem pagamento')
                else if (cheio)
                  Text('sua parte ${reais(f.minhaParte)}', style: TextStyle(fontSize: 13.5, color: cores.textoFraco)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
