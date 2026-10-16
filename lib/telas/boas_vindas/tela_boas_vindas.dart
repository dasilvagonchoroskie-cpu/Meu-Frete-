import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../componentes/basicos.dart';
import '../../componentes/perguntas_trabalho.dart';
import '../../componentes/placa.dart';
import '../../dados/configuracao.dart';
import '../../nucleo/placa.dart';
import '../../tema.dart';
import '../caminhao/tela_caminhao.dart';

/// Primeira abertura: boas-vindas, nome do motorista e placa do caminhao
/// (obrigatorios, saem no relatorio) e as quatro perguntas de como o
/// motorista trabalha. Tudo pode ser mudado depois em Configuracoes.
class TelaBoasVindas extends StatefulWidget {
  const TelaBoasVindas({super.key});

  @override
  State<TelaBoasVindas> createState() => _TelaBoasVindasState();
}

class _TelaBoasVindasState extends State<TelaBoasVindas> {
  final _paginas = PageController();
  int _pagina = 0;
  late final TextEditingController _nome;
  late final TextEditingController _placa;
  String? _erroNome;
  String? _erroPlaca;

  static const _total = 7;
  static const _paginaIdentificacao = 1;

  @override
  void initState() {
    super.initState();
    final config = context.read<Configuracao>();
    _nome = TextEditingController(text: config.nomeMotorista);
    _placa = TextEditingController(text: placaTexto(config.placaAtual));
  }

  @override
  void dispose() {
    _paginas.dispose();
    _nome.dispose();
    _placa.dispose();
    super.dispose();
  }

  Future<void> _avancar() async {
    FocusScope.of(context).unfocus();
    if (_pagina == _paginaIdentificacao) {
      setState(() {
        _erroNome = erroDoNome(_nome.text);
        _erroPlaca = erroDaPlaca(_placa.text);
      });
      if (_erroNome != null || _erroPlaca != null) return;
      await gravarIdentificacao(context, nome: _nome.text, placa: _placa.text);
      if (!mounted) return;
    }
    if (_pagina == _total - 1) {
      context.read<Configuracao>().configuracaoInicialFeita = true;
      return;
    }
    _paginas.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  void _voltar() {
    FocusScope.of(context).unfocus();
    _paginas.previousPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  Widget _passo(int numero, String titulo, String texto, Widget conteudo) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text('Passo $numero de 5', style: TextStyle(fontSize: 15, color: context.cores.textoFraco)),
          const SizedBox(height: 6),
          Text(titulo, style: context.textos.headlineSmall),
          const SizedBox(height: 8),
          Nota(texto),
          const SizedBox(height: 20),
          conteudo,
        ],
      );

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final paginas = <Widget>[
      ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        children: [
          Placa(rotulo: 'Bem-vindo ao', valor: 'Meu Frete', tamanhoValor: 52),
          const SizedBox(height: 28),
          Text('O caderno do motorista, no celular.', style: context.textos.headlineSmall),
          const SizedBox(height: 14),
          Text(
            'Anote os fretes, o diesel, os gastos e os vales. O app faz a conta do que você tem para receber, '
            'da média do caminhão e de quanto sobrou em cada viagem. Depois manda o acerto em PDF para o patrão.',
            style: TextStyle(fontSize: 17, height: 1.45, color: cores.textoFraco),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.lock_outline, color: cores.textoFraco, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Nota('Tudo fica guardado só neste celular. Não precisa de internet nem de cadastro.'),
              ),
            ],
          ),
        ],
      ),
      _passo(
        1,
        'Motorista e caminhão',
        'O nome e a placa saem no relatório e no acerto, para o proprietário saber de quem é cada registro. '
            'Se trocar de caminhão, é só trocar a placa em Configurações.',
        CamposIdentificacao(
          nome: _nome,
          placa: _placa,
          erroNome: _erroNome,
          erroPlaca: _erroPlaca,
          aoMudar: () {
            if (_erroNome != null || _erroPlaca != null) {
              setState(() {
                _erroNome = null;
                _erroPlaca = null;
              });
            }
          },
        ),
      ),
      _passo(
        2,
        'Sua comissão',
        'Agora quatro perguntas rápidas sobre o seu combinado. Elas mudam a conta do seu líquido.',
        const PerguntaComissao(),
      ),
      _passo(3, 'O dinheiro do frete', 'Para o app saber se precisa tirar a sua porcentagem.', const PerguntaFreteCheio()),
      _passo(4, 'Diesel e gastos', 'Para saber se o gasto sai do seu líquido ou não.', const PerguntaGastos()),
      _passo(5, 'Vale', 'Dinheiro que você pega adiantado durante a viagem.', const PerguntaVale()),
      ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        children: [
          Text('Pronto', style: context.textos.headlineMedium),
          const SizedBox(height: 10),
          Nota('Com as suas respostas, a conta de um mês fica assim:'),
          const SizedBox(height: 14),
          const ExemploDaConta(),
          const SizedBox(height: 18),
          Nota('Dá para mudar qualquer resposta depois, em Configurações, na tela Resumo.'),
        ],
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Row(
                children: [
                  for (var i = 0; i < _total; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _pagina ? cores.placa : cores.divisor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _paginas,
                // So os botoes passam de pagina (o nome e a placa sao obrigatorios).
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _pagina = p),
                children: paginas,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  if (_pagina > 0) ...[
                    OutlinedButton(onPressed: _voltar, child: const Text('Voltar')),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _avancar,
                      child: Text(_pagina == 0 ? 'Começar' : (_pagina == _total - 1 ? 'Abrir o app' : 'Continuar')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
