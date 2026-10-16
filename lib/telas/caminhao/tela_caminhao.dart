import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../componentes/basicos.dart';
import '../../componentes/placa_veiculo.dart';
import '../../dados/configuracao.dart';
import '../../dados/dados.dart';
import '../../nucleo/formato.dart';
import '../../nucleo/placa.dart';
import '../../tema.dart';

/// Nome do motorista e placa do caminhao: os dois campos e a validacao.
class CamposIdentificacao extends StatelessWidget {
  const CamposIdentificacao({
    super.key,
    required this.nome,
    this.placa,
    this.erroNome,
    this.erroPlaca,
    this.aoMudar,
  });

  final TextEditingController nome;

  /// Sem controle de placa, mostra so o nome.
  final TextEditingController? placa;
  final String? erroNome;
  final String? erroPlaca;
  final VoidCallback? aoMudar;

  @override
  Widget build(BuildContext context) {
    final placa = this.placa;
    final mostrarPlaca = placa != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nome,
          textCapitalization: TextCapitalization.words,
          textInputAction: mostrarPlaca ? TextInputAction.next : TextInputAction.done,
          style: const TextStyle(fontSize: 17),
          decoration: InputDecoration(
            labelText: 'Nome do motorista',
            errorText: erroNome,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          onChanged: (_) => aoMudar?.call(),
        ),
        if (placa != null) ...[
          const SizedBox(height: 14),
          CampoPlaca(controle: placa, erro: erroPlaca, aoMudar: aoMudar),
        ],
      ],
    );
  }
}

class CampoPlaca extends StatelessWidget {
  const CampoPlaca({super.key, required this.controle, this.erro, this.aoMudar, this.rotulo = 'Placa do caminhão'});

  final TextEditingController controle;
  final String? erro;
  final VoidCallback? aoMudar;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controle,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.visiblePassword,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: const [FormatadorPlaca()],
      style: estiloNumero(22, peso: FontWeight.w700).copyWith(letterSpacing: 2),
      decoration: InputDecoration(
        labelText: rotulo,
        hintText: 'ABC1D23',
        helperText: erro == null ? 'A placa do cavalo, como está no documento' : null,
        errorText: erro,
        prefixIcon: const Icon(Icons.local_shipping_outlined),
      ),
      onChanged: (_) => aoMudar?.call(),
    );
  }
}

String? erroDoNome(String nome) => nome.trim().length < 2 ? 'Escreva o nome do motorista.' : null;

String? erroDaPlaca(String placa) =>
    placaValida(placa) ? null : 'Placa no formato ABC1D23 (Mercosul) ou ABC-1234.';

/// Grava nome e placa e passa a usar este caminhao. Registros antigos sem
/// placa (de antes desta versao) ficam com este caminhao.
Future<void> gravarIdentificacao(BuildContext context, {required String nome, required String placa}) async {
  final config = context.read<Configuracao>();
  final dados = context.read<Dados>();
  final p = normalizarPlaca(placa);
  config.nomeMotorista = nome.trim();
  config.placaAtual = p;
  dados.usarPlaca(p);
  await dados.marcarSemPlaca(p);
}

/// Depois de atualizar o app: antes de continuar, o motorista informa o
/// nome e a placa (eles agora saem no relatorio).
class TelaIdentificacao extends StatefulWidget {
  const TelaIdentificacao({super.key});

  @override
  State<TelaIdentificacao> createState() => _TelaIdentificacaoState();
}

class _TelaIdentificacaoState extends State<TelaIdentificacao> {
  late final TextEditingController _nome;
  late final TextEditingController _placa;
  String? _erroNome;
  String? _erroPlaca;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final config = context.read<Configuracao>();
    _nome = TextEditingController(text: config.nomeMotorista);
    _placa = TextEditingController(text: placaTexto(config.placaAtual));
  }

  @override
  void dispose() {
    _nome.dispose();
    _placa.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _erroNome = erroDoNome(_nome.text);
      _erroPlaca = erroDaPlaca(_placa.text);
    });
    if (_erroNome != null || _erroPlaca != null) return;
    setState(() => _salvando = true);
    await gravarIdentificacao(context, nome: _nome.text, placa: _placa.text);
  }

  @override
  Widget build(BuildContext context) {
    final temRegistros = context.watch<Dados>().totalDeRegistros > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Motorista e caminhão')),
      bottomNavigationBar: RodapeBotao(texto: 'Salvar e continuar', aoTocar: _salvando ? null : _salvar),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'O relatório e o acerto em PDF agora saem com o nome do motorista e a placa do caminhão, '
            'para o proprietário saber de quem é cada registro.',
            style: TextStyle(fontSize: 16.5, height: 1.4, color: context.cores.textoFraco),
          ),
          if (temRegistros) ...[
            const SizedBox(height: 10),
            Nota('O que você já anotou fica com este caminhão.'),
          ],
          const SizedBox(height: 22),
          CamposIdentificacao(
            nome: _nome,
            placa: _placa,
            erroNome: _erroNome,
            erroPlaca: _erroPlaca,
            aoMudar: () => setState(() {
              _erroNome = null;
              _erroPlaca = null;
            }),
          ),
        ],
      ),
    );
  }
}

/// Configuracoes > Motorista e caminhao: muda o nome, troca de caminhao
/// (os registros do anterior ficam guardados) ou corrige a placa.
class TelaCaminhao extends StatefulWidget {
  const TelaCaminhao({super.key});

  @override
  State<TelaCaminhao> createState() => _TelaCaminhaoState();
}

class _TelaCaminhaoState extends State<TelaCaminhao> {
  late final TextEditingController _nome;
  String? _erroNome;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: context.read<Configuracao>().nomeMotorista);
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _salvarNome() {
    final erro = erroDoNome(_nome.text);
    setState(() => _erroNome = erro);
    if (erro != null) return;
    context.read<Configuracao>().nomeMotorista = _nome.text;
    FocusScope.of(context).unfocus();
    mostrarMensagem(context, 'Nome salvo.');
  }

  /// Pede uma placa num quadro. Devolve a placa sem traco, ou null.
  Future<String?> _pedirPlaca({required String titulo, required String texto, required String botao}) {
    final controle = TextEditingController();
    String? erro;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialogo) => AlertDialog(
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(texto, style: const TextStyle(fontSize: 15.5, height: 1.35)),
              const SizedBox(height: 16),
              CampoPlaca(
                controle: controle,
                erro: erro,
                rotulo: 'Placa',
                aoMudar: () => setStateDialogo(() => erro = null),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                final e = erroDaPlaca(controle.text);
                if (e != null) {
                  setStateDialogo(() => erro = e);
                  return;
                }
                Navigator.pop(ctx, normalizarPlaca(controle.text));
              },
              child: Text(botao),
            ),
          ],
        ),
      ),
    );
  }

  void _usar(String placa) {
    context.read<Configuracao>().placaAtual = placa;
    context.read<Dados>().usarPlaca(placa);
    mostrarMensagem(context, 'Agora o app está no caminhão ${placaTexto(placa)}.');
  }

  Future<void> _trocar() async {
    final nova = await _pedirPlaca(
      titulo: 'Trocar de caminhão',
      texto: 'Digite a placa do caminhão novo. O que foi anotado no caminhão atual fica guardado; '
          'para ver de novo, é só escolher a placa dele aqui.',
      botao: 'Trocar',
    );
    if (nova == null || !mounted) return;
    _usar(nova);
  }

  Future<void> _corrigir(String atual) async {
    final nova = await _pedirPlaca(
      titulo: 'Corrigir a placa',
      texto: 'Use só se a placa ${placaTexto(atual)} foi digitada errada. Todos os registros dela passam '
          'para a placa certa.',
      botao: 'Corrigir',
    );
    if (nova == null || nova == atual || !mounted) return;
    final config = context.read<Configuracao>();
    final dados = context.read<Dados>();
    config.corrigirPlaca(atual, nova);
    await dados.corrigirPlaca(atual, nova);
    if (mounted) mostrarMensagem(context, 'Placa corrigida para ${placaTexto(nova)}.');
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<Configuracao>();
    final dados = context.watch<Dados>();
    final cores = context.cores;
    final atual = config.placaAtual;
    final outras = {...config.placasUsadas, ...dados.placasComRegistro}.where((p) => p != atual && p.isNotEmpty).toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Motorista e caminhão')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const TituloSecao('Motorista', espacoAcima: 8),
          CamposIdentificacao(
            nome: _nome,
            erroNome: _erroNome,
            aoMudar: () => setState(() => _erroNome = null),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(onPressed: _salvarNome, child: const Text('Salvar nome')),
          ),
          const TituloSecao('Caminhão em uso'),
          Row(
            children: [
              PlacaVeiculo(atual, tamanho: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  plural(dados.registrosDaPlaca(atual), 'registro', 'registros'),
                  style: TextStyle(fontSize: 15.5, color: cores.textoFraco),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _trocar,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Trocar de caminhão'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: atual.isEmpty ? null : () => _corrigir(atual),
            child: const Text('A placa está errada? Corrigir'),
          ),
          if (outras.isNotEmpty) ...[
            const TituloSecao('Outros caminhões'),
            Nota('Registros guardados de caminhões que você já usou. Toque para ver e anotar nele.'),
            const SizedBox(height: 8),
            for (final p in outras)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: PlacaVeiculo(p, tamanho: 15),
                title: Text(plural(dados.registrosDaPlaca(p), 'registro', 'registros')),
                trailing: const Text('Usar', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _usar(p),
              ),
          ],
          const SizedBox(height: 20),
          Nota('Cada caminhão tem a sua média de diesel, o seu km inicial e as suas contas. '
              'O relatório sai sempre com a placa do caminhão em uso.'),
        ],
      ),
    );
  }
}
