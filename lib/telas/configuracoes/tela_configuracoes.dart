import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app.dart';
import '../../componentes/basicos.dart';
import '../../componentes/perguntas_trabalho.dart';
import '../../dados/configuracao.dart';
import '../../dados/copia_seguranca.dart';
import '../../dados/dados.dart';
import '../../nucleo/formato.dart';
import '../../tema.dart';

class TelaConfiguracoes extends StatelessWidget {
  const TelaConfiguracoes({super.key});

  Future<void> _exportar(BuildContext context) async {
    try {
      await CopiaSeguranca.exportar(context.read<Dados>(), context.read<Configuracao>());
    } catch (e) {
      if (context.mounted) mostrarMensagem(context, 'Não consegui gerar a cópia: $e');
    }
  }

  Future<void> _restaurar(BuildContext context) async {
    final dados = context.read<Dados>();
    final config = context.read<Configuracao>();
    CopiaLida? copia;
    try {
      copia = await CopiaSeguranca.escolherArquivo();
    } on FormatException catch (e) {
      if (context.mounted) mostrarMensagem(context, e.message);
      return;
    } catch (e) {
      if (context.mounted) mostrarMensagem(context, 'Não consegui abrir o arquivo: $e');
      return;
    }
    if (copia == null || !context.mounted) return;
    final lida = copia;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar esta cópia?'),
        content: Text(
          'A cópia${lida.criadoEm > 0 ? ' de ${dataHoraTexto(lida.criadoEm)}' : ''} tem ${lida.descricao}.\n\n'
          'Tudo que está anotado agora neste celular (${plural(dados.totalDeRegistros, 'registro', 'registros')}) '
          'será trocado pelo que está na cópia.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
        ],
      ),
    );
    if (ok != true) return;
    await dados.substituirTudo(lida.tabelas);
    if (lida.configuracao.isNotEmpty) config.aplicarMapa(lida.configuracao);
    if (context.mounted) mostrarMensagem(context, 'Cópia restaurada: ${lida.descricao}.');
  }

  Future<void> _abrir(BuildContext context, String endereco) async {
    final ok = await launchUrl(Uri.parse(endereco), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) mostrarMensagem(context, 'Não consegui abrir o navegador.');
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<Configuracao>();
    final cores = context.cores;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          Nota('Estas respostas mudam a conta do seu valor líquido. Responda com o seu combinado, '
              'não com o do colega.'),
          const TituloSecao('Sua comissão', espacoAcima: 20),
          const PerguntaComissao(),
          const TituloSecao('O dinheiro que você anota no frete'),
          const PerguntaFreteCheio(),
          const TituloSecao('Diesel e gastos'),
          const PerguntaGastos(),
          const TituloSecao('Vale'),
          const PerguntaVale(),
          const SizedBox(height: 16),
          const ExemploDaConta(),
          const TituloSecao('Aparência'),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Automático')),
                ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
              ],
              selected: {config.tema},
              onSelectionChanged: (s) => config.tema = s.first,
            ),
          ),
          const SizedBox(height: 6),
          Nota('Automático segue o celular: claro de dia, escuro à noite se o celular estiver assim.'),
          const TituloSecao('Cópia de segurança'),
          Nota('Tudo fica guardado só neste celular. Gere uma cópia de vez em quando e guarde no WhatsApp, '
              'no Drive ou no e-mail. Se trocar de celular, é só restaurar.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _exportar(context),
            icon: const Icon(Icons.upload_file),
            label: const Text('Gerar cópia de segurança'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _restaurar(context),
            icon: const Icon(Icons.settings_backup_restore),
            label: const Text('Restaurar uma cópia'),
          ),
          const TituloSecao('Sobre'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Meu Frete'),
            subtitle: Text('Versão $versaoApp'),
            leading: Icon(Icons.local_shipping_outlined, color: cores.textoFraco),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Política de privacidade'),
            subtitle: const Text('O app não coleta nem envia seus dados'),
            leading: Icon(Icons.shield_outlined, color: cores.textoFraco),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => _abrir(context, enderecoPrivacidade),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fortaleza Digital Security'),
            subtitle: const Text('Quem fez o app'),
            leading: Icon(Icons.language, color: cores.textoFraco),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => _abrir(context, enderecoSite),
          ),
        ],
      ),
    );
  }
}
