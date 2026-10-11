# Meu Frete 2 (Flutter)

Caderno do motorista de caminhão: fretes, diesel, gastos e vales, com a conta do
que o motorista tem para receber e de quanto sobrou para o caminhão. Funciona sem
internet; tudo fica no celular. Versão para a Play Store, reescrita em Flutter a
partir do MeuFrete 1.2 (Kotlin), com as mesmas regras de cálculo.

- Pacote: `br.com.fortalezadigitalsecurity.meufrete`
- Fortaleza Digital Security — Goiatuba (GO)

## Onde está cada coisa

| Pasta | O que tem |
|---|---|
| `lib/regras` | As contas: comissão, resumo, média do diesel, períodos, janela da viagem |
| `lib/dados` | Registros (SQLite), configurações, rascunhos, cópia de segurança |
| `lib/telas` | Telas: Resumo, Fretes, Diesel, Gastos, Vales, Relatório, Configurações, Boas-vindas |
| `lib/componentes` | Peças de tela reaproveitadas (placa, campos, listas) |
| `lib/relatorio` | Geração do PDF (relatório do período e acerto da viagem) |
| `test` | Testes das contas e das telas; `capturas_test.dart` gera as imagens da loja |
| `loja` | Ícone 512, imagem de destaque e textos da Play Store |

## Esteira

Cada envio para `main` roda `.github/workflows/compilar.yml`: análise, testes,
imagens da loja (artefato `capturas`), APK e AAB assinados com a chave de envio
(segredos `MEUFRETE_UPLOAD_KEYSTORE_BASE64` e `MEUFRETE_UPLOAD_KEYSTORE_SENHA`).
O release `versao-mais-recente` traz `MeuFrete.apk` e `MeuFrete.aab`.
