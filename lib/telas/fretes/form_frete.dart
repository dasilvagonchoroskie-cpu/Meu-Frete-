import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../componentes/basicos.dart';
import '../../componentes/campos.dart';
import '../../dados/configuracao.dart';
import '../../dados/dados.dart';
import '../../dados/modelos.dart';
import '../../dados/rascunho.dart';
import '../../nucleo/entrada.dart';
import '../../nucleo/formato.dart';
import '../../tema.dart';

/// Anotar um frete novo ou mudar um ja salvo.
class FormFrete extends StatefulWidget {
  const FormFrete({super.key, this.editando});

  final Frete? editando;

  @override
  State<FormFrete> createState() => _FormFreteState();
}

class _FormFreteState extends State<FormFrete> {
  final _origem = TextEditingController();
  final _destino = TextEditingController();
  final _empresa = TextEditingController();
  final _peso = TextEditingController();
  final _tonelada = TextEditingController();
  final _adiantamento = TextEditingController();
  final _saldo = TextEditingController();
  final _percentual = TextEditingController();
  final _pedagio = TextEditingController();
  final _pesoDescarga = TextEditingController();
  final _descontoQuebra = TextEditingController();

  int _dataCarga = hoje();
  bool _sobreBruto = false;
  Rascunho? _rascunho;
  String? _erroOrigem;
  String? _erroDestino;

  bool get _novo => widget.editando == null;

  List<TextEditingController> get _todos => [
        _origem, _destino, _empresa, _peso, _tonelada, _adiantamento,
        _saldo, _percentual, _pedagio, _pesoDescarga, _descontoQuebra,
      ];

  @override
  void initState() {
    super.initState();
    final config = context.read<Configuracao>();
    final f = widget.editando;
    if (f != null) {
      _origem.text = f.origem;
      _destino.text = f.destino;
      _empresa.text = f.empresa;
      _dataCarga = f.dataCarga;
      _peso.text = textoInteiro(f.pesoKg);
      _tonelada.text = textoDinheiro(f.valorTonelada);
      _adiantamento.text = textoDinheiro(f.adiantamento);
      _saldo.text = textoDinheiro(f.saldo);
      _percentual.text = textoDecimal(f.percentualComissao);
      _pedagio.text = textoDinheiro(f.pedagio);
      _pesoDescarga.text = textoInteiro(f.pesoDescargaKg);
      _descontoQuebra.text = textoDinheiro(f.descontoQuebra);
      _sobreBruto = f.comissaoSobreBruto;
    } else {
      _percentual.text = textoDecimal(config.percentualPadrao);
      _sobreBruto = config.comissaoSobreBrutoPadrao;
      _carregarRascunho();
    }
  }

  Future<void> _carregarRascunho() async {
    final r = await Rascunho.abrir('frete');
    _rascunho = r;
    final m = r.ler();
    if (m.isEmpty || !mounted) return;
    setState(() {
      String s(String k) => (m[k] as String?) ?? '';
      _origem.text = s('origem');
      _destino.text = s('destino');
      _empresa.text = s('empresa');
      _peso.text = s('peso');
      _tonelada.text = s('tonelada');
      _adiantamento.text = s('adiantamento');
      _saldo.text = s('saldo');
      if (s('percentual').isNotEmpty) _percentual.text = s('percentual');
      _pedagio.text = s('pedagio');
      _pesoDescarga.text = s('pesoDescarga');
      _descontoQuebra.text = s('descontoQuebra');
      final d = m['dataCarga'];
      if (d is int) _dataCarga = d;
      final b = m['sobreBruto'];
      if (b is bool) _sobreBruto = b;
    });
  }

  void _mudou([String? _]) {
    setState(() {
      if (_origem.text.trim().isNotEmpty) _erroOrigem = null;
      if (_destino.text.trim().isNotEmpty) _erroDestino = null;
    });
    if (_novo) {
      _rascunho?.gravar({
        'origem': _origem.text,
        'destino': _destino.text,
        'empresa': _empresa.text,
        'peso': _peso.text,
        'tonelada': _tonelada.text,
        'adiantamento': _adiantamento.text,
        'saldo': _saldo.text,
        'percentual': _percentual.text,
        'pedagio': _pedagio.text,
        'pesoDescarga': _pesoDescarga.text,
        'descontoQuebra': _descontoQuebra.text,
        'dataCarga': _dataCarga,
        'sobreBruto': _sobreBruto,
      });
    }
  }

  @override
  void dispose() {
    for (final c in _todos) {
      c.dispose();
    }
    super.dispose();
  }

  Frete _montar() => Frete(
        id: widget.editando?.id ?? 0,
        origem: _origem.text.trim(),
        destino: _destino.text.trim(),
        empresa: _empresa.text.trim(),
        dataCarga: _dataCarga,
        pesoKg: lerNumero(_peso.text),
        valorTonelada: lerNumero(_tonelada.text),
        adiantamento: lerNumero(_adiantamento.text),
        saldo: lerNumero(_saldo.text),
        percentualComissao: lerNumero(_percentual.text),
        pedagio: lerNumero(_pedagio.text),
        comissaoSobreBruto: _sobreBruto,
        pesoDescargaKg: lerNumero(_pesoDescarga.text),
        descontoQuebra: lerNumero(_descontoQuebra.text),
      );

  Future<void> _salvar() async {
    final f = _montar();
    setState(() {
      _erroOrigem = f.origem.isEmpty ? 'Falta de onde saiu a carga.' : null;
      _erroDestino = f.destino.isEmpty ? 'Falta para onde vai a carga.' : null;
    });
    if (_erroOrigem != null || _erroDestino != null) {
      mostrarMensagem(context, 'Preencha origem e destino para salvar.');
      return;
    }
    await context.read<Dados>().salvarFrete(f);
    _rascunho?.limpar();
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    Navigator.pop(context, true);
    mensageiro.showSnackBar(SnackBar(content: Text(_novo ? 'Frete salvo.' : 'Alteração salva.')));
  }

  Widget _dupla(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
      );

  @override
  Widget build(BuildContext context) {
    final dados = context.watch<Dados>();
    final f = _montar();
    const espaco = SizedBox(height: 14);

    return Scaffold(
      appBar: AppBar(title: Text(_novo ? 'Novo frete' : 'Mudar frete')),
      bottomNavigationBar: RodapeBotao(texto: _novo ? 'Salvar frete' : 'Salvar alteração', aoTocar: _salvar),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          if (_novo)
            Nota('Preencha o que já sabe agora. O saldo e a descarga você completa depois. '
                'O que digitar fica guardado mesmo se o app fechar.'),
          const TituloSecao('Carga', espacoAcima: 16),
          CampoData(
            rotulo: 'Data da carga',
            valor: _dataCarga,
            aoMudar: (v) {
              _dataCarga = v;
              _mudou();
            },
          ),
          espaco,
          Campo(
            controle: _origem,
            rotulo: 'Origem (de onde saiu)',
            erro: _erroOrigem,
            maiusculas: TextCapitalization.words,
            sugestoes: dados.cidadesUsadas,
            aoMudar: _mudou,
          ),
          espaco,
          Campo(
            controle: _destino,
            rotulo: 'Destino (para onde vai)',
            erro: _erroDestino,
            maiusculas: TextCapitalization.words,
            sugestoes: dados.cidadesUsadas,
            aoMudar: _mudou,
          ),
          espaco,
          Campo(
            controle: _empresa,
            rotulo: 'Transportadora ou cliente',
            ajuda: 'Opcional',
            maiusculas: TextCapitalization.words,
            sugestoes: dados.empresasUsadas,
            aoMudar: _mudou,
          ),
          const TituloSecao('Peso e preço'),
          _dupla(
            Campo(controle: _peso, rotulo: 'Peso na carga', tipo: TipoCampo.inteiro, sufixo: 'kg', dica: '33.040', aoMudar: _mudou),
            Campo(controle: _tonelada, rotulo: 'Valor da tonelada', tipo: TipoCampo.dinheiro, aoMudar: _mudou),
          ),
          const TituloSecao('Pagamento'),
          _dupla(
            Campo(controle: _adiantamento, rotulo: 'Adiantamento', tipo: TipoCampo.dinheiro, aoMudar: _mudou),
            Campo(controle: _saldo, rotulo: 'Saldo', tipo: TipoCampo.dinheiro, ajuda: 'Quando cair', aoMudar: _mudou),
          ),
          espaco,
          Campo(
            controle: _pedagio,
            rotulo: 'Pedágio no cartão ou tag',
            tipo: TipoCampo.dinheiro,
            ajuda: 'O que a empresa pagou de pedágio. Pedágio do seu bolso vai em Gastos.',
            aoMudar: _mudou,
          ),
          const TituloSecao('Comissão'),
          Campo(
            controle: _percentual,
            rotulo: 'Sua comissão',
            tipo: TipoCampo.decimal,
            sufixo: '%',
            aoMudar: _mudou,
          ),
          const SizedBox(height: 12),
          Text('A comissão é sobre', style: TextStyle(fontSize: 15, color: context.cores.textoFraco)),
          const SizedBox(height: 6),
          EscolhaDupla(
            valor: _sobreBruto,
            textoSim: 'Frete + pedágio',
            textoNao: 'Só o frete',
            aoMudar: (v) {
              _sobreBruto = v;
              _mudou();
            },
          ),
          const TituloSecao('Descarga'),
          Nota('Pode completar depois, quando descarregar.'),
          const SizedBox(height: 10),
          _dupla(
            Campo(controle: _pesoDescarga, rotulo: 'Peso na descarga', tipo: TipoCampo.inteiro, sufixo: 'kg', aoMudar: _mudou),
            Campo(controle: _descontoQuebra, rotulo: 'Desconto de quebra', tipo: TipoCampo.dinheiro, aoMudar: _mudou),
          ),
          const TituloSecao('Conferência'),
          Conferencia(frete: f),
        ],
      ),
    );
  }
}

/// Conta ao vivo do frete: o que entrou, o combinado, a quebra e a sua parte.
class Conferencia extends StatelessWidget {
  const Conferencia({super.key, required this.frete});
  final Frete frete;

  @override
  Widget build(BuildContext context) {
    final f = frete;
    final cores = context.cores;
    final contratado = f.valorContratado;
    final dif = f.diferencaDoContratado;
    final quebra = f.quebraKg;

    String? mensagem;
    Color? corMensagem;
    if (f.freteReal > 0 && contratado > 0) {
      if (dif.abs() < 0.01) {
        mensagem = 'Bateu certinho com o combinado.';
        corMensagem = cores.positivo;
      } else if (dif > 0) {
        mensagem = 'Entrou ${reais(dif)} a mais que o combinado. Confira.';
        corMensagem = cores.atencao;
      } else {
        mensagem = 'Desconto da transportadora: ${reais(dif.abs())} (INSS, SEST/SENAT, seguro, pedágio, quebra).';
        corMensagem = cores.textoFraco;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinhaValor(rotulo: 'Frete real (o que entrou)', valor: reais(f.freteReal)),
        if (f.descontoQuebra > 0) LinhaValor(rotulo: 'Sem a quebra teria dado', valor: reais(f.freteSemQuebra)),
        LinhaValor(
          rotulo: 'Valor contratado',
          valor: contratado > 0 ? reais(contratado) : '—',
          detalhe: contratado > 0 ? '${toneladas(f.pesoKg)} t × ${reais(f.valorTonelada)}' : 'Peso vezes o valor da tonelada',
        ),
        LinhaValor(
          rotulo: f.comissaoSobreBruto ? 'Base da comissão (bruto)' : 'Base da comissão (o que entrou)',
          valor: f.baseComissao > 0 ? reais(f.baseComissao) : '—',
        ),
        LinhaValor(
          rotulo: 'Sua parte (${percentualTexto(f.percentualComissao)}%)',
          valor: reais(f.minhaParte),
          destaque: true,
          corValor: cores.positivo,
        ),
        if (mensagem != null)
          Padding(padding: const EdgeInsets.only(top: 6), child: Nota(mensagem, cor: corMensagem)),
        if (quebra != null) ...[
          const SizedBox(height: 12),
          Aviso(
            icone: Icons.scale_outlined,
            titulo: 'Quebra de ${semCasas(quebra)} kg',
            texto: 'Carregou ${toneladas(f.pesoKg)} t e descarregou ${toneladas(f.pesoDescargaKg)} t. '
                'Pelo valor da tonelada, a quebra vale ${reais(f.valorQuebraIntegral)}. '
                '${f.descontoQuebra > 0 ? 'Cobraram ${reais(f.descontoQuebra)}.' : 'Não descontaram.'}'
                '${f.descontoQuebra > f.valorQuebraIntegral + 0.01 && f.valorQuebraIntegral > 0 ? ' Atenção: cobraram ${reais(f.descontoQuebra - f.valorQuebraIntegral)} a mais do que a quebra vale.' : ''}',
          ),
        ],
      ],
    );
  }
}
