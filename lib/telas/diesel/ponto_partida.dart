import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../componentes/basicos.dart';
import '../../componentes/campos.dart';
import '../../dados/dados.dart';
import '../../dados/modelos.dart';
import '../../nucleo/entrada.dart';
import '../../nucleo/formato.dart';
import '../../tema.dart';

/// Km da ultima abastecida anotada antes do app (tanque cheio), para a
/// media ja sair certa. Toda mudanca depois de salvo fica registrada.
class TelaPontoPartida extends StatefulWidget {
  const TelaPontoPartida({super.key});

  @override
  State<TelaPontoPartida> createState() => _TelaPontoPartidaState();
}

class _TelaPontoPartidaState extends State<TelaPontoPartida> {
  final _km = TextEditingController();
  final _cidade = TextEditingController();
  final _motivo = TextEditingController();
  int _data = hoje();
  Abastecimento? _atual;
  String? _erroKm;
  String? _erroMotivo;

  @override
  void initState() {
    super.initState();
    _atual = context.read<Dados>().pontoDePartida;
    final p = _atual;
    if (p != null) {
      _km.text = textoInteiro(p.km);
      _cidade.text = p.cidade;
      _data = p.data;
    }
  }

  @override
  void dispose() {
    _km.dispose();
    _cidade.dispose();
    _motivo.dispose();
    super.dispose();
  }

  bool get _mudouKm {
    final p = _atual;
    return p != null && lerNumero(_km.text) != p.km;
  }

  Future<void> _salvar() async {
    final km = lerNumero(_km.text);
    setState(() {
      _erroKm = km <= 0 ? 'Falta o km.' : null;
      _erroMotivo = _mudouKm && _motivo.text.trim().isEmpty
          ? 'Escreva o motivo da mudança. É o que protege você no relatório.'
          : null;
    });
    if (_erroKm != null || _erroMotivo != null) return;
    final p = _atual;
    final ponto = Abastecimento(
      id: p?.id ?? 0,
      data: _data,
      cidade: _cidade.text.trim(),
      km: km,
      tanqueCheio: true,
      pontoDePartida: true,
    );
    final ajuste = (p != null && km != p.km)
        ? AjusteKm(
            quando: DateTime.now().millisecondsSinceEpoch,
            kmAnterior: p.km,
            kmNovo: km,
            motivo: _motivo.text.trim(),
          )
        : null;
    await context.read<Dados>().salvarPontoDePartida(ponto, ajuste);
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    mensageiro.showSnackBar(const SnackBar(content: Text('Km inicial salvo.')));
  }

  @override
  Widget build(BuildContext context) {
    const espaco = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(title: const Text('Km inicial')),
      bottomNavigationBar: RodapeBotao(texto: _mudouKm ? 'Salvar mudança' : 'Salvar', aoTocar: _salvar),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Nota(_atual == null
              ? 'Coloque o km da última abastecida que você tem anotado, de tanque cheio. '
                  'A partir dele o app começa a contar a média.'
              : 'Você está mudando um km inicial que já estava salvo. A mudança fica registrada '
                  'e sai no pé do relatório.'),
          const SizedBox(height: 18),
          Campo(
            controle: _km,
            rotulo: 'Km da última abastecida',
            tipo: TipoCampo.inteiro,
            sufixo: 'km',
            erro: _erroKm,
            aoMudar: (_) => setState(() => _erroKm = null),
          ),
          espaco,
          Campo(controle: _cidade, rotulo: 'Cidade', ajuda: 'Se lembrar', maiusculas: TextCapitalization.words),
          espaco,
          CampoData(rotulo: 'Data', valor: _data, aoMudar: (v) => setState(() => _data = v)),
          if (_mudouKm) ...[
            espaco,
            Campo(
              controle: _motivo,
              rotulo: 'Motivo da mudança',
              dica: 'aferição do painel, troca de painel...',
              erro: _erroMotivo,
              aoMudar: (_) => setState(() => _erroMotivo = null),
            ),
            const SizedBox(height: 8),
            Nota('De ${semCasas(_atual!.km)} para ${_km.text.isEmpty ? '—' : _km.text} km'),
          ],
        ],
      ),
    );
  }
}

/// Lista de todas as mudancas do km inicial.
class TelaHistoricoKm extends StatelessWidget {
  const TelaHistoricoKm({super.key});

  @override
  Widget build(BuildContext context) {
    final ajustes = context.watch<Dados>().ajustes;
    final cores = context.cores;
    return Scaffold(
      appBar: AppBar(title: const Text('Mudanças do km inicial')),
      body: ajustes.isEmpty
          ? ListView(children: const [
              EstadoVazio(
                icone: Icons.history,
                titulo: 'Nenhuma mudança',
                texto: 'Toda vez que o km inicial for alterado, fica registrado aqui com data, hora e motivo. '
                    'Esse registro sai no relatório.',
              ),
            ])
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: ajustes.length,
              separatorBuilder: (context, indice) => const Divider(indent: 20, endIndent: 20),
              itemBuilder: (_, i) {
                final a = ajustes[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dataHoraTexto(a.quando), style: TextStyle(fontSize: 14, color: cores.textoFraco)),
                      const SizedBox(height: 4),
                      Text('km ${semCasas(a.kmAnterior)}  para  ${semCasas(a.kmNovo)}', style: estiloNumero(19)),
                      const SizedBox(height: 4),
                      Text('Motivo: ${a.motivo}', style: const TextStyle(fontSize: 15.5)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
