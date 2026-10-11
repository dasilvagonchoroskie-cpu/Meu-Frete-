import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../componentes/basicos.dart';
import '../../componentes/campos.dart';
import '../../componentes/listas.dart';
import '../../dados/dados.dart';
import '../../dados/modelos.dart';
import '../../dados/rascunho.dart';
import '../../nucleo/entrada.dart';
import '../../nucleo/formato.dart';
import '../../tema.dart';

const categoriasComuns = [
  'Borracharia', 'Manutenção', 'Pedágio', 'Alimentação', 'Arla 32',
  'Lavagem', 'Chapa', 'Estacionamento', 'Peças', 'Óleo',
];

class TelaGastos extends StatelessWidget {
  const TelaGastos({super.key});

  void _novo(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormGasto()));

  @override
  Widget build(BuildContext context) {
    final dados = context.watch<Dados>();
    final cores = context.cores;
    final grupos = agruparPorMes<Gasto>(dados.gastos, (g) => g.data);

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'novo_gasto',
        onPressed: () => _novo(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo gasto'),
      ),
      body: dados.gastos.isEmpty
          ? ListView(children: [
              EstadoVazio(
                icone: Icons.receipt_long_outlined,
                titulo: 'Nenhum gasto anotado',
                texto: 'Borracharia, manutenção, pedágio do bolso, chapa, lavagem. O diesel fica na aba Diesel.',
                acao: FilledButton.icon(
                  onPressed: () => _novo(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Anotar gasto'),
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
                        MaterialPageRoute(builder: (_) => FormGasto(editando: g.itens[i])),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
                        child: Row(
                          children: [
                            ColunaData(g.itens[i].data),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                g.itens[i].categoria.trim().isEmpty ? 'Sem categoria' : g.itens[i].categoria,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(reais(g.itens[i].valor), style: estiloNumero(18, cor: cores.negativo)),
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

class FormGasto extends StatefulWidget {
  const FormGasto({super.key, this.editando});
  final Gasto? editando;

  @override
  State<FormGasto> createState() => _FormGastoState();
}

class _FormGastoState extends State<FormGasto> {
  final _valor = TextEditingController();
  final _categoria = TextEditingController();
  int _data = hoje();
  String? _erroValor;
  String? _erroCategoria;
  Rascunho? _rascunho;

  bool get _novo => widget.editando == null;

  @override
  void initState() {
    super.initState();
    final g = widget.editando;
    if (g != null) {
      _data = g.data;
      _valor.text = textoDinheiro(g.valor);
      _categoria.text = g.categoria;
    } else {
      Rascunho.abrir('gasto').then((r) {
        _rascunho = r;
        final m = r.ler();
        if (m.isEmpty || !mounted) return;
        setState(() {
          _valor.text = (m['valor'] as String?) ?? '';
          _categoria.text = (m['categoria'] as String?) ?? '';
          final d = m['data'];
          if (d is int) _data = d;
        });
      });
    }
  }

  @override
  void dispose() {
    _valor.dispose();
    _categoria.dispose();
    super.dispose();
  }

  void _mudou([String? _]) {
    setState(() {
      _erroValor = null;
      _erroCategoria = null;
    });
    if (_novo) _rascunho?.gravar({'valor': _valor.text, 'categoria': _categoria.text, 'data': _data});
  }

  Future<void> _salvar() async {
    final valor = lerNumero(_valor.text);
    setState(() {
      _erroValor = valor <= 0 ? 'Falta o valor do gasto.' : null;
      _erroCategoria = _categoria.text.trim().isEmpty ? 'Escolha ou escreva o que foi. Ex.: borracharia.' : null;
    });
    if (_erroValor != null || _erroCategoria != null) return;
    await context.read<Dados>().salvarGasto(
          Gasto(id: widget.editando?.id ?? 0, data: _data, valor: valor, categoria: _categoria.text.trim()),
        );
    _rascunho?.limpar();
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    mensageiro.showSnackBar(SnackBar(content: Text(_novo ? 'Gasto salvo.' : 'Alteração salva.')));
  }

  Future<void> _apagar() async {
    final g = widget.editando!;
    final ok = await confirmarExclusao(
      context,
      titulo: 'Apagar este gasto?',
      detalhe: '${dataTexto(g.data)}, ${g.categoria}, ${reais(g.valor)}. Não dá para desfazer.',
    );
    if (!ok || !mounted) return;
    final dados = context.read<Dados>();
    final mensageiro = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    await dados.apagarGasto(g);
    mensageiro.showSnackBar(const SnackBar(content: Text('Gasto apagado.')));
  }

  @override
  Widget build(BuildContext context) {
    final usadas = context.watch<Dados>().categoriasUsadas;
    final opcoes = <String>[...usadas];
    for (final c in categoriasComuns) {
      if (!opcoes.any((u) => u.toLowerCase() == c.toLowerCase())) opcoes.add(c);
    }
    final atual = _categoria.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(_novo ? 'Novo gasto' : 'Mudar gasto'),
        actions: [
          if (!_novo) IconButton(tooltip: 'Apagar', icon: const Icon(Icons.delete_outline), onPressed: _apagar),
        ],
      ),
      bottomNavigationBar: RodapeBotao(texto: _novo ? 'Salvar gasto' : 'Salvar alteração', aoTocar: _salvar),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          CampoData(
            rotulo: 'Data',
            valor: _data,
            aoMudar: (v) {
              _data = v;
              _mudou();
            },
          ),
          const SizedBox(height: 14),
          Campo(controle: _valor, rotulo: 'Valor', tipo: TipoCampo.dinheiro, erro: _erroValor, aoMudar: _mudou),
          const SizedBox(height: 14),
          Campo(
            controle: _categoria,
            rotulo: 'O que foi',
            erro: _erroCategoria,
            maiusculas: TextCapitalization.sentences,
            aoMudar: _mudou,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in opcoes)
                ChoiceChip(
                  label: Text(c),
                  selected: c.toLowerCase() == atual,
                  showCheckmark: false,
                  onSelected: (_) {
                    _categoria.text = c;
                    _mudou();
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Nota('Diesel vai na aba Diesel. Pedágio pago no cartão ou tag da empresa vai no próprio frete.'),
        ],
      ),
    );
  }
}
