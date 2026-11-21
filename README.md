# Diário de Leituras

Um diário pessoal de leituras, **100% offline**, para registrar obras, escrever
fichamentos e análises e acompanhar estatísticas de leitura. A interface é em
português do Brasil e o projeto tem como alvo principal o **Android**.

## Objetivo

Organizar a prática da leitura em um único lugar: cadastrar livros, artigos e
outros textos; fichar o que foi lido com resumo, tese, conceitos, crítica e
citações; escrever análises em formato de artigo, opcionalmente vinculadas a
várias obras; e acompanhar o progresso por meio de estatísticas e de uma
sequência diária de leitura. Todos os dados ficam no dispositivo — sem contas,
nuvem, sincronização ou consultas a APIs externas.

## Funcionalidades

- **Obras:** cadastro com tipo, título, autor, gênero, ano e páginas; filtros
  por status (da leitura mais recente), tipo e gênero; busca por título ou
  autor; detalhe com leituras, fichamentos e análises vinculadas.
- **Leituras e releituras:** cada obra pode ter vários ciclos numerados, cada
  um com status, nota, datas de início/fim, progresso e sessões próprias.
- **Sessões de leitura:** registro de páginas lidas por data dentro de uma
  leitura, com validação que impede a soma da leitura de ultrapassar o total
  de páginas da obra.
- **Fichamentos:** vários por obra, com rótulo, resumo, tese, conceitos,
  crítica e uma lista de citações com página e comentário.
- **Análises:** texto livre com título, vínculo opcional com várias obras e
  salvamento automático ao sair da tela.
- **Estatísticas:** sequência atual (com estado "em risco") e maior sequência,
  calendário mensal de dias lidos, contagens de leituras por status e de obras
  por tipo/gênero, páginas lidas e leituras concluídas por mês/ano, e nota
  média por gênero e autor considerando todas as leituras.
- **Backup:** exportação e importação de todos os dados em JSON, com validação
  de versão e estrutura, resumo antes de importar e substituição atômica.
- **Navegação:** menu lateral (`NavigationDrawer`) com as quatro seções e
  Configurações, sem barra inferior.
- **Aparência:** tema "biblioteca clássica" com a fonte Literata embutida,
  tema claro e escuro conforme o sistema e um único acento carmesim.

## Stack

- Flutter estável, Dart null-safe, Material 3
- **Drift** + `drift_flutter` (SQLite) e `build_runner`/`drift_dev`
- **Riverpod** para estado (sem geração de código nos providers)
- **go_router** com `StatefulShellRoute`
- **fl_chart** para gráficos
- **intl** com locale `pt_BR`
- `file_picker`, `share_plus` e `path_provider` para backup

## Estrutura

```
lib/
  main.dart               # inicialização
  app.dart                # MaterialApp.router, locale e tema
  core/                   # tema, tokens, strings, rotas, formatadores, logo
  data/                   # tabelas Drift, DAOs e serviço de backup
  features/
    works/                # Obras, formulário, detalhe e sessões
    notes/                # Fichamentos e citações
    analyses/             # Análises e vínculos
    stats/                # Estatísticas e sequência diária
assets/
  fonts/                  # Literata (OFL)
  logo/                   # Logo clara/escura em várias resoluções
android/app/src/main/res/ # Ícone launcher e adaptive icon
```

As telas nunca acessam o banco diretamente: todos os dados passam por
providers Riverpod.

## Como executar

Pré-requisitos: Flutter SDK estável e, para Android, Android SDK + dispositivo
ou emulador.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Para gerar o APK de release:

```bash
flutter build apk --release
```

## Backup

Em **Configurações → Exportar dados**, um arquivo `.json` com todas as tabelas
é compartilhado pelo Android. Em **Importar dados**, escolha um `.json` válido:
o app mostra a quantidade de obras, fichamentos e análises e pede confirmação.
A importação substitui os dados atuais dentro de uma única transação; em caso
de erro, nada é alterado. Backups da versão 1 (sem releituras) também são
aceitos: cada obra é convertida na sua leitura 1 e as sessões antigas são
vinculadas a ela.

## Testes e qualidade

```bash
flutter analyze
flutter test
```

A suíte cobre cálculo da sequência diária (inclusive viradas de mês/ano e
sessões editadas ou apagadas), criação de releituras e migração do schema 1,
estatísticas com várias leituras por obra, ida e volta do backup (incluindo
backups legados) e navegação/menu lateral.

## Identidade visual

A direção visual é a de uma biblioteca clássica: serifas, papel e tinta,
neutros levemente quentes e um único acento carmesim escuro. Todo estilo vive
em `lib/core/theme.dart` e `lib/core/tokens.dart`. As fontes Literata são
distribuídas sob a licença OFL (ver `assets/fonts/OFL.txt`).

## Licença

Distribuído sob a licença MIT. Veja o arquivo [LICENSE](LICENSE).
