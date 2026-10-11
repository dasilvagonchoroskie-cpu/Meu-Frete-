import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../componentes/basicos.dart';
import '../../componentes/campos.dart';
import '../../componentes/listas.dart';
import '../../dados/configuracao.dart';
import '../../dados/dados.dart';
import '../../dados/modelos.dart';
import '../../nucleo/entrada.dart';
import '../../nucleo/formato.dart';
import '../../tema.dart';

class TelaVales extends StatelessWidget {
  const TelaVales({super.key});

  void _novo(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormVale()));

  @override
  Widget build(BuildContext context) {
    final dados = context.watch<Dados>();
    final desconta = context.watch<Configuracao>().valeDescontaDoLiquido;
    final grupos = agruparPorMes<Vale>(dados.vales, (v) => v.data);

    return Scaffold(
      appBar: AppBar(title: const Text('Vales')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'novo_vale',
        onPressed: () => _novo(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo vale'),
      ),
      body: dados.vales.isEmpty
          ? ListView(children: [
              EstadoVazio(
                icone: Icons.payments_outlined,
                titulo: 'Nenhum vale anotado',
                texto: desconta
                    ? 'Anote o dinheiro que você pegou adiantado. Ele é descontado do que você tem para receber.'
                    : 'Anote o dinheiro que você pegou adiantado. Fica só como histórico, sem mexer no líquido.',
                acao: FilledButton.icon(
                  onPressed: () => _novo(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Anotar vale'),
                ),
              ),
            ])
          : ListView(
              children: [
                for (final g in grupos) ...[
                  CabecalhoMes(titulo: g.titulo, resumo: reais(g.itens.fold<double>(0, (s, e) => s + e.valor))),
                  for (var i = 0; i < g.itens.length; i++) ...[
                    if (i > 0) const Divider(indent: 20, endIndent: 20),
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FormVale(editando: g.itens[i])),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
                        child: Row(
                          children: [
                            ColunaData(g.itens[i].data),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text('Vale', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                            ),
                            Text(reais(g.itens[i].valor), style: estiloNumero(18)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
                espacoFinalLista,
              ],
            ),
    );
  }
}

class FormVale extends StatefulWidget {
  const FormVale({super.key, this.editando});
  final Vale? editando;

  @override
  State<FormVale> createState() => _FormValeState();
}

class _FormValeState extends State<FormVale> {
  final _valor = TextEditingController();
  int _data = hoje();
  String? _erro;

  bool get _novo => widget.editando == null;

  @override
  void initState() {
    super.initState();
    final v = widget.editando;
    if (v != null) {
      _data = v.data;
      _valor.text = textoDinheiro(v.valor);
    }
  }

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final valor = lerNumero(_valor.text);
    if (valor <= 0) {
      setState(() => _erro = 'Falta o valor do vale.');
      return;
    }
    await context.read<Dados>().salvarVale(Vale(id: widget.editando?.id ?? 0, data: _data, valor: valor));
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    mensageiro.showSnackBar(SnackBar(content: Text(_novo ? 'Vale salvo.' : 'Alteração salva.')));
  }

  Future<void> _apagar() async {
    final v = widget.editando!;
    final ok = await confirmarExclusao(
      context,
      titulo: 'Apagar este vale?',
      detalhe: '${dataTexto(v.data)}, ${reais(v.valor)}. Não dá para desfazer.',
    );
    if (!ok || !mounted) return;
    final dados = context.read<Dados>();
    final mensageiro = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    await dados.apagarVale(v);
    mensageiro.showSnackBar(const SnackBar(content: Text('Vale apagado.')));
  }

  @override
  Widget build(BuildContext context) {
    final desconta = context.watch<Configuracao>().valeDescontaDoLiquido;
    return Scaffold(
      appBar: AppBar(
        title: Text(_novo ? 'Novo vale' : 'Mudar vale'),
        actions: [
          if (!_novo) IconButton(tooltip: 'Apagar', icon: const Icon(Icons.delete_outline), onPressed: _apagar),
        ],
      ),
      bottomNavigationBar: RodapeBotao(texto: _novo ? 'Salvar vale' : 'Salvar alteração', aoTocar: _salvar),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          CampoData(rotulo: 'Data', valor: _data, aoMudar: (v) => setState(() => _data = v)),
          const SizedBox(height: 14),
          Campo(
            controle: _valor,
            rotulo: 'Valor',
            tipo: TipoCampo.dinheiro,
            erro: _erro,
            autofoco: _novo,
            aoMudar: (_) => setState(() => _erro = null),
          ),
          const SizedBox(height: 16),
          Nota(desconta
              ? 'O vale é descontado do que você tem para receber.'
              : 'O vale fica só como histórico e não mexe no seu líquido. Dá para mudar isso em Configurações.'),
        ],
      ),
    );
  }
}
