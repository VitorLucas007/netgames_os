# NetGames OS

Aplicativo de **gestão de ordens de serviço (OS)** para assistência técnica de eletrônicos (notebooks, consoles, celulares etc.). O técnico cadastra o cliente e o aparelho, acompanha o conserto, monta o orçamento (com desconto) e gera documentos em PDF. O **cliente acompanha o andamento por um link**, sem precisar de login nem de instalar nada.

- **Painel do técnico:** app Flutter (Android, iOS, Web, Windows).
- **Acompanhamento do cliente:** página web aberta pelo link `https://netgamesos.web.app/acompanhar/<CODIGO>`.

## Funcionalidades

| Área | O que faz |
|---|---|
| Cadastro | Cliente (nome, WhatsApp, CPF, e-mail) e equipamento (tipo, marca, modelo, nº de série, acessórios, condição física, senha) |
| Ordem de serviço | Abertura de OS com código legível (`OS-2026-00001`), defeito relatado e histórico por número de série |
| Fluxo de status | Recebido → Em análise → Aguardando aprovação → Em manutenção → Aguardando peça → Pronto para retirada → Entregue (ou Devolvido sem conserto). O app só permite as transições válidas |
| Laudo e orçamento | Laudo técnico, mão de obra e peças, com total calculado |
| Desconto | O dono escolhe um valor em **R$** ou uma **porcentagem**. O desconto nunca passa do subtotal |
| Decisão do cliente | Registro de aprovação ou recusa do orçamento, que move a OS para o status certo |
| Fotos | Fotos de entrada e de saída do aparelho (câmera) |
| Documentos | PDF do Termo de Recebimento e do Recibo/Garantia, compartilhados pelo WhatsApp |
| Link do cliente | Página pública com status, linha do tempo, orçamento, laudo e desconto |

### Link de acompanhamento e privacidade

Cada OS tem um **código secreto aleatório** (20 caracteres, gerado com `Random.secure`), que vai no link. O cliente nunca acessa a OS completa:

- A OS completa (CPF, senha do aparelho, WhatsApp) fica em `ordens/{id}`.
- Uma **cópia pública**, só com o que o cliente pode ver, fica em `acompanhamentos/{codigo}` (classe `VisaoCliente`).
- O link **expira 30 dias** depois que a OS é entregue ou devolvida.

## Tecnologias

- **[Flutter](https://flutter.dev) / Dart** (SDK `^3.12.2`), com Material 3 e tema claro/escuro.
- **Firebase**
  - **Cloud Firestore**: banco de dados (`cloud_firestore`, `firebase_core`).
  - **Firebase Hosting**: publicação da versão web e do link do cliente.
- **Pacotes**: `pdf` (geração dos documentos), `share_plus` (compartilhar), `image_picker` (fotos), `path_provider`, `url_launcher`.
- **Arquitetura**: MVVM com `ChangeNotifier`. As telas dependem só da interface `OrdemServicoRepository`, que tem duas implementações: Firestore (padrão) e memória (para testes).

## Estrutura do projeto

```
lib/
├── core/            # tema, rota do link de acompanhamento
├── models/          # OrdemServico, Cliente, Equipamento, Desconto, VisaoCliente, enums
├── Repositories/    # interface + implementação em memória + implementação Firestore
├── ViewModels/      # regras e estado de cada tela
├── Views/           # telas (lista, nova OS, detalhe, acompanhamento do cliente)
├── services/        # geração de PDF e compartilhamento
├── utils/           # formatadores, validadores, geração de códigos
├── widgets/         # componentes reutilizáveis
├── firebase_options.dart   # lê as chaves do .env
└── main.dart
test/                # testes unitários (código de acesso, link, desconto)
firestore.rules      # regras de segurança do Firestore
firebase.json        # configuração de Hosting e regras
```

## Como rodar

### 1. Pré-requisitos
- [Flutter](https://docs.flutter.dev/get-started/install) instalado (`flutter doctor` sem erros)
- [Node.js](https://nodejs.org) e a CLI do Firebase: `npm i -g firebase-tools`
- Acesso ao projeto Firebase `netgamesos`

### 2. Configurar as chaves (`.env`)
As chaves do Firebase **não ficam no código**. Elas ficam no arquivo `.env`, que está no `.gitignore`.

```bash
cp .env.example .env     # no Windows: copy .env.example .env
```

Preencha com os valores do Console do Firebase (Configurações do projeto → Seus aplicativos). O arquivo `.env.example` lista todas as variáveis.

### 3. Instalar dependências
```bash
flutter pub get
```

### 4. Executar
O `.env` entra na compilação pela flag `--dart-define-from-file`:

```bash
flutter run -d chrome --dart-define-from-file=.env
```

No VS Code, use o `F5`: o `.vscode/launch.json` já passa a flag.

> **Android:** além do `.env`, o app precisa do arquivo `android/app/google-services.json` (baixe no Console do Firebase). Ele também está no `.gitignore`.

### 5. Testes
```bash
flutter test
```

## Publicar (Firebase)

```bash
# Regras do Firestore
firebase deploy --only firestore:rules --project netgamesos

# Versão web (inclui o link do cliente)
flutter build web --release --dart-define-from-file=.env
firebase deploy --only hosting --project netgamesos
```

## Segurança: o que fica fora do git

O `.gitignore` bloqueia:

| Arquivo | Motivo |
|---|---|
| `.env`, `.env.*` (menos `.env.example`) | Chaves do Firebase |
| `android/app/google-services.json` | Configuração do Firebase no Android |
| `ios/Runner/GoogleService-Info.plist`, `macos/Runner/GoogleService-Info.plist` | Configuração do Firebase no iOS/macOS |
| `.firebaserc`, `.firebase/`, `firebase-debug.log` | Estado local da CLI do Firebase |
| `android/key.properties`, `*.jks`, `*.keystore` | Chaves de assinatura do app |

> **Importante:** as chaves de API do Firebase em apps web e mobile são identificadores do projeto e acabam visíveis no app compilado. O que protege os dados de verdade são as **regras do Firestore** (`firestore.rules`). Tirar as chaves do git evita expô-las no repositório, mas não substitui as regras.

## Estado atual e próximos passos

- [x] Cadastro, fluxo de status, laudo, orçamento e desconto
- [x] Persistência no Firestore e link público do cliente
- [x] PDFs de recebimento e recibo/garantia
- [ ] **Login do técnico (Firebase Auth).** Hoje as regras do Firestore estão em **modo de teste (abertas)**; use só dados fictícios até o login existir e as regras serem fechadas
- [ ] Perfis (dono × técnico), para controlar quem dá desconto
- [ ] Fotos no Firebase Storage (hoje são caminhos locais e o cliente não as vê)
- [ ] Criptografar a senha do aparelho antes de ir para produção
