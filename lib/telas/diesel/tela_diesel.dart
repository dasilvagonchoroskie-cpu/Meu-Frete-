import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../componentes/basicos.dart';
import '../../componentes/listas.dart';
import '../../dados/dados.dart';
import '../../dados/modelos.dart';
import '../../nucleo/formato.dart';
import '../../regras/media_diesel.dart';
import '../../tema.dart';
import 'form_abastecimento.dart';
import 'ponto_partida.dart';

class TelaDiesel extends StatelessWidget {
  const TelaDiesel({super.key});

  void _nova(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FormAbastecimento()));

  void _ponto(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaPontoPartida()));

  @override
  Widget build(BuildContext context) {
    final dados = context.watch<Dados>();
    final cores = context.cores;
    final todas = dados.abastecimentos;
    final abastecidas = List<Abastecimento>.from(dados.abastecidas)
      ..sort((a, b) {
        final c = b.data.compareTo(a.data);
        return c != 0 ? c : b.km.compareTo(a.km);
      });
    final ponto = dados.pontoDePartida;
    final grupos = agruparPorMes<Abastecimento>(abastecidas, (a) => a.data);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diesel'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            onSelected: (v) {
              if (v == 'ponto') _ponto(context);
              if (v == 'historico') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistoricoKm()));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ponto', child: Text('Km inicial (ponto de partida)')),
              PopupMenuItem(value: 'historico', child: Text('Mudanças do km inicial')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nova_abastecida',
        onPressed: () => _nova(context),
        icon: const Icon(Icons.add),
        label: const Text('Abastecida'),
      ),
      body: abastecidas.isEmpty
          ? ListView(children: [
              EstadoVazio(
                icone: Icons.local_gas_station_outlined,
                titulo: ponto == null ? 'Comece pelo km da última abastecida' : 'Nenhuma abastecida ainda',
                texto: ponto == null
                    ? 'Se você tem anotado o km da última vez que encheu o tanque, coloque ele como ponto de partida. '
                        'Assim a média já sai certa na primeira abastecida.'
                    : 'Ponto de partida no km ${semCasas(ponto.km)}. Na próxima vez que encher o tanque, '
                        'anote aqui e a média aparece.',
                acao: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (ponto == null)
                      OutlinedButton(onPressed: () => _ponto(context), child: const Text('Informar km inicial')),
                    FilledButton.icon(
                      onPressed: () => _nova(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Anotar abastecida'),
                    ),
                  ],
                ),
              ),
            ])
          : ListView(
              children: [
                for (final g in grupos) ...[
                  CabecalhoMes(titulo: g.titulo, resumo: _resumoMes(g.itens, todas)),
                  for (var i = 0; i < g.itens.length; i++) ...[
                    if (i > 0) const Divider(indent: 20, endIndent: 20),
                    LinhaAbastecida(item: g.itens[i], todas: todas),
                  ],
                ],
                if (ponto != null) ...[
                  CabecalhoMes(titulo: 'Ponto de partida', resumo: ''),
                  ListTile(
                    leading: Icon(Icons.flag_outlined, color: cores.textoFraco),
                    title: Text('km ${semCasas(ponto.km)}', style: estiloNumero(18)),
                    subtitle: Text(
                      '${dataTexto(ponto.data)}${ponto.cidade.trim().isNotEmpty ? ', ${ponto.cidade}' : ''}. '
                      'Vindo da planilha, tanque cheio.',
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _ponto(context),
                  ),
                ],
                espacoFinalLista,
              ],
            ),
    );
  }

  String _resumoMes(List<Abastecimento> doMes, List<Abastecimento> todas) {
    final total = doMes.fold<double>(0, (s, a) => s + a.valor);
    final media = mediaDoPeriodo(doMes, todas).media;
    return media == null ? reais(total) : '${umaCasa(media)} km/L   ${reais(total)}';
  }
}

class LinhaAbastecida extends StatelessWidget {
  const LinhaAbastecida({super.key, required this.item, required this.todas});
  final Abastecimento item;
  final List<Abastecimento> todas;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final a = item;
    final media = mediaDaLinha(todas, a).media;
    final lugar = [a.cidade.trim(), a.posto.trim()].where((s) => s.isNotEmpty).join(', ');
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FormAbastecimento(editando: a))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColunaData(a.data),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lugar.isEmpty ? 'Abastecida' : lugar,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('km ${semCasas(a.km)}   ${umaCasa(a.litros)} L', style: estiloNumero(16, peso: FontWeight.w500, cor: cores.textoFraco)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(reais(a.valor), style: estiloNumero(18)),
                const SizedBox(height: 6),
                if (!a.tanqueCheio)
                  const Etiqueta('Não encheu', atencao: false)
                else if (media != null)
                  Text('${umaCasa(media)} km/L', style: estiloNumero(16, cor: cores.positivo))
                else
                  Text('primeira cheia', style: TextStyle(fontSize: 13.5, color: cores.textoFraco)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
