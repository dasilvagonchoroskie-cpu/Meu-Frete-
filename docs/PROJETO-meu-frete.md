# PROJETO — Meu Frete (versão 2, Flutter, Play Store)

Arquivo mestre. Colando este arquivo num chat novo dá para continuar o projeto sem explicar nada de novo.

## 1. Objetivo

Aplicativo para motorista de caminhão (carreteiro comissionado) anotar fretes, diesel, gastos e vales e saber:
- quanto tem para receber (valor líquido);
- a média real do caminhão;
- quanto sobrou para o caminhão em cada viagem e no período;
- o acerto da viagem em PDF para mandar ao patrão.

Produto da Fortaleza Digital Security (Evandro, Goiatuba-GO), para vender na Google Play com pagamento único. Funciona 100% offline, sem cadastro e sem servidor.

A versão 1.2 era em Kotlin (Jetpack Compose + Room, pacote `com.meufrete.app`). Em 11/10/2026 foi reescrita em Flutter mantendo exatamente as mesmas regras de cálculo, com telas novas e mais limpas. A versão "frota" (Firebase, painel do gestor) continua só como ideia.

## 2. Decisões tomadas

| Decisão | Motivo |
|---|---|
| Flutter/Dart | Regra do Evandro desde 24/09/2026: apps novos só em Flutter |
| Pacote novo `br.com.fortalezadigitalsecurity.meufrete` | Nome único na Play, ligado ao domínio da marca. Não atualiza por cima da 1.2 (a chave antiga não existe), então a 1.2 e a 2.0 são apps separados |
| Licença: Play Store sem a Central; APK de venda direta pela Central de Licenças 3 (11/10/2026) | Na Play Store o app é pago e a própria loja cobra (AAB sem trava e sem internet, como a ficha promete). O APK vendido por WhatsApp sai com o portão do pacote `fortaleza_licenca`: pedido de liberação sem chave, teste grátis opcional, chave curta. A esteira monta os dois a partir do mesmo código (`--dart-define=LICENCA_CENTRAL`). |
| SQLite local (sqflite) com as mesmas tabelas da 1.2 | Mesmo modelo de dados; backup automático do Android leva o banco |
| Cópia de segurança em arquivo .json | Trocar de celular sem perder nada; restaura pelo seletor de arquivos oficial (file_selector) |
| Rascunho automático nos formulários novos | "Nada do que você digitar se perde", como na 1.2 |
| Acentos corretos em tudo (1.2 escrevia sem acento) | Qualidade de produto de loja |
| PDF com a letra Barlow embutida | Acentos, "−" e "×" saem certos em qualquer celular |
| Conta do caminhão só aparece quando "o valor cheio do frete" | No modo "só a minha parte" a conta não faz sentido |
| Correção de erro da 1.2 | No acerto de uma viagem que não era a primeira, o próprio frete ficava fora da conta (a janela começava no dia seguinte à carga). Agora o frete sempre entra |
| Chave de envio da Play guardada fora do GitHub | A sessão não consegue gravar segredos no GitHub; a esteira compila com chave de teste e a assinatura final é feita fora (ver item 7) |

## 3. Regras de cálculo (iguais à 1.2)

Frete:
- Frete real = adiantamento + saldo (o que caiu na conta).
- Valor contratado = peso (kg) / 1000 × valor da tonelada.
- Base da comissão: se "frete + pedágio" (comissaoSobreBruto) = peso da descarga (ou da carga, se não tiver descarga) / 1000 × tonelada; se "só o frete" = frete real.
- Sua parte = base × percentual / 100.
- Quebra = peso da carga − peso da descarga (só se positivo). Valor da quebra = quebra / 1000 × tonelada. Aviso se o desconto de quebra cobrado passar do valor da quebra.
- Diferença do contratado: frete real − contratado (0 = "bateu certinho"; negativo = desconto da transportadora).

Resumo do período (calcularResumo):
- Comissão = soma das "sua parte" (modo valor cheio) ou soma do frete real (modo "só a minha parte").
- Líquido = comissão − (diesel + gastos, se saem do bolso do motorista) − (vales, se descontam).
- Fretes em aberto = frete real 0 e contratado > 0.
- Desconto da transportadora = contratado dos fretes pagos − frete real deles (mínimo 0).
- Sobra do caminhão = frete real − diesel − gastos − comissão. Pedágio no cartão/tag não entra.

Média do diesel:
- Só sai com tanque cheio. Referência = última abastecida de tanque cheio com km menor. km rodados = km atual − km da referência; litros = litros das abastecidas entre as duas + litros desta. Média = km / litros.
- Ponto de partida (km inicial da planilha) é uma abastecida especial de tanque cheio sem litros e sem valor; toda mudança do km dele grava data, hora, km anterior, km novo e motivo, e sai no pé do relatório.
- Média do período = soma dos km dos trechos ÷ soma dos litros dos trechos.

Períodos: este mês, mês passado, 7/15/30 dias (contando hoje), datas escolhidas.
Janela da viagem (acerto): do dia da carga (ou do dia seguinte, se houve carga antes) até o dia da carga seguinte, esse dia incluído; se não houver carga seguinte, até hoje.

Configuração (as quatro perguntas, chaves do SharedPreferences):
- `percentual_padrao` (13), `comissao_sobre_bruto` (false = só o frete), `frete_real_eh_valor_cheio` (true), `gastos_descontam` (false = empresa paga), `vale_desconta` (true), `tema` (sistema/claro/escuro), `configuracao_inicial_feita`.

## 4. Arquitetura

Flutter 3.47.5 (estável), Dart 3.13. Provider para estado.

```
lib/
  main.dart, app.dart (MaterialApp pt-BR, tema, Raiz: boas-vindas ou abas)
  tema.dart (cores da estrada, Barlow / Barlow Semi Condensed, claro e escuro)
  nucleo/formato.dart (1.234,56, datas, meses) e entrada.dart (máscaras: dinheiro de banco, inteiro com milhar, decimal)
  dados/ modelos.dart, armazenamento.dart (SQLite e memória), dados.dart (ChangeNotifier com tudo),
         configuracao.dart, rascunho.dart, copia_seguranca.dart
  regras/ resumo.dart, media_diesel.dart, periodo.dart, dados_relatorio.dart
  relatorio/gerador_pdf.dart (pacote pdf, MultiPage A4, compartilhar)
  componentes/ placa.dart (a "placa de estrada" do número principal), basicos.dart, campos.dart,
               listas.dart, seletor_periodo.dart, perguntas_trabalho.dart
  telas/ casca.dart (5 abas), resumo, fretes (lista, formulário, detalhe), diesel (lista, formulário,
         km inicial, histórico), gastos, vales, relatorio, configuracoes, boas_vindas
test/ regras_test, formato_test, app_test (telas, cópia, PDF), capturas_test (imagens da loja), apoio (dados de exemplo)
loja/ icone-512.png, destaque-1024x500.png, textos-play-store.md
android/ AGP 9.1, Kotlin 2.4, Gradle 9.3.1, compileSdk/targetSdk 36, ícone adaptativo com versão monocromática,
         abertura verde, sem nenhuma permissão, regras de backup (banco + preferências)
```

Dependências: provider, sqflite, path, shared_preferences, path_provider, share_plus 10, file_selector, url_launcher, pdf, intl, flutter_localizations.

## 5. Telas

1. Boas-vindas (primeira abertura): placa "Meu Frete" + 4 passos (comissão, dinheiro do frete, gastos, vale) + exemplo da conta.
2. Resumo: períodos em fichas, placa "Você tem para receber", comissão/gastos/vales, conta do caminhão, aviso de fretes aguardando saldo, diesel (média, litros, preço médio). Botões: PDF e Configurações.
3. Fretes: lista por mês (total do mês), linha com data, trajeto origem → destino, valor e "Aguardando saldo". Botão "Novo frete". Detalhe com placa "Sua parte", pagamento, descarga/quebra, conta da viagem e botão "Enviar acerto da viagem".
4. Diesel: lista por mês com média do mês, média de cada abastecida, ponto de partida no fim; menu com km inicial e histórico de mudanças.
5. Gastos: lista por mês; formulário com fichas de categoria (usadas + comuns).
6. Vales: lista por mês.
7. Relatório em PDF: período, o que vai (tudo, fretes, diesel, gastos, vales), contagem, gerar e enviar.
8. Configurações: as 4 perguntas + exemplo, tema, cópia de segurança (gerar/restaurar), versão, política de privacidade, site.

Visual: cores da estrada — verde placa #0B5D3B, amarelo faixa #F2B300, asfalto #1E2427, concreto #F1F2EE. Letra Barlow (inspirada em placas). O número mais importante de cada tela vai numa "placa" verde com filete branco.

## 6. Repositório e esteira

- GitHub: `dasilvagonchoroskie-cpu/Meu-Frete-` (público enquanto ajusta; passar para privado quando pronto).
- `.github/workflows/compilar.yml`: pub get → flutter analyze → flutter test → imagens da loja (golden 1080x1920 + PDFs de exemplo) → APK e AAB release → Release `versao-mais-recente` com MeuFrete.apk, MeuFrete.aab e capturas.zip.
- Código de versão = 2000 + número da execução. Versão visível 2.0.0.

## 7. Assinatura (chave de envio da Play Store)

- Arquivo `meufrete-upload.jks` (PKCS12, RSA 4096, válida até 2054), alias `meufrete`, mesma senha para a chave e o arquivo. Guardado com o Evandro (não vai para o GitHub).
- SHA-256 do certificado: 32:73:DD:CC:BA:56:AA:3F:60:20:3C:A9:12:4C:E5:3B:76:42:DA:F5:AB:1E:CA:9F:D0:6A:3D:0A:5A:AF:30:CD
- A esteira compila com chave de teste. A assinatura final é feita fora: AAB com `jarsigner` (antes tira a assinatura de teste e a pasta `BUNDLE-METADATA/com.android.tools.build.debugsymbols`, que leva o arquivo de 56 MB para 28 MB) e APK com `uber-apk-signer --allowResign`. Conferido com `bundletool validate`.
- A sessão do Claude não consegue gravar segredos, criar release nem mudar o repositório para privado pelo GitHub; isso o Evandro faz pelo site.
- Se um dia os segredos `MEUFRETE_UPLOAD_KEYSTORE_BASE64` e `MEUFRETE_UPLOAD_KEYSTORE_SENHA` forem cadastrados no GitHub (Settings > Secrets and variables > Actions), a esteira já assina sozinha.
- Na Play Console, aceitar a Assinatura de apps do Google Play: o Google guarda a chave final; se a chave de envio se perder, dá para pedir troca ao suporte.

## 8. Play Store

- Política de privacidade: https://fortalezadigitalsecurity.com.br/meufrete/privacidade.html (repo `fortaleza-digital-site`, pasta `meufrete/`, com página do app e termos de uso).
- Textos, categoria, segurança dos dados e passo a passo: `loja/textos-play-store.md`.
- Conta pessoal nova pode exigir teste fechado (12 testadores, 14 dias) antes da produção.
- Preço: pagamento único, valor a definir pelo Evandro.

## 9. Status (11/10/2026)

- [x] Regras portadas e testadas (unitários iguais à 1.2)
- [x] Telas novas em Flutter, tema claro e escuro
- [x] Ícone, abertura, ícone 512, imagem de destaque, 10 capturas
- [x] Política de privacidade e termos publicados
- [x] Esteira verde: analyze + testes + APK + AAB
- [x] APK e AAB assinados com a chave de envio
- [ ] Evandro: criar o app na Play Console, definir preço, enviar o AAB, preencher a ficha
- [ ] Testar no Moto G35 (instalar o APK)
- [ ] Repositório volta para privado (Evandro, pelo site do GitHub)

## 9.1 Licença do APK de venda direta (11/10/2026)

- Pacote `fortaleza_licenca` (repositório `fortaleza-central-licencas`, pasta `pacote/`), preso no commit `8d208fbadafd65a681bd81473a4b49619b041b4c` (licenca-v1).
- Apelido no servidor: `meufrete` (já cadastrado). Na Central, aba Apps: WhatsApp de venda, preço e dias de teste grátis.
- `MainActivity.kt` entrega o ANDROID_ID e o modelo pelo canal `fortaleza/licenca`.
- **Antes de vender o APK por WhatsApp:** a chave de assinatura tem que estar nos segredos do GitHub (`MEUFRETE_UPLOAD_KEYSTORE_BASE64` e `MEUFRETE_UPLOAD_KEYSTORE_SENHA`). Sem ela a esteira gera `MeuFrete-venda-direta-TESTE.apk` com uma chave diferente a cada montagem — o código do aparelho mudaria a cada atualização.

## 10. Próximos passos possíveis

- Período de teste grátis + compra dentro do app (em vez de app pago).
- Versão frota (Firebase, painel do gestor) — R$ 600 implantação, R$ 100/mês, R$ 30 de desconto por indicação (decidido em 15/09/2026).
